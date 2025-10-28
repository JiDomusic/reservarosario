import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class ReservationService {
  static final _client = supabase;

  // Cache para mesas
  static List<Map<String, dynamic>>? _mesasCache;

  // Obtener todas las mesas (con fallback offline)
  static Future<List<Map<String, dynamic>>> getMesas() async {
    try {
      debugPrint('🔍 Loading tables from database...');
      final response = await _client
          .from('sodita_mesas')
          .select('*')
          .eq('activa', true)
          .order('numero');

      final mesas = List<Map<String, dynamic>>.from(response);
      _mesasCache = mesas; // Guardar en caché
      debugPrint('✅ Tables loaded: ${mesas.length} tables found');
      return mesas;
    } catch (e) {
      debugPrint('❌ Error fetching tables: $e');
      
      // Usar caché si está disponible
      if (_mesasCache != null) {
        debugPrint('📦 Using cached tables: ${_mesasCache!.length} tables');
        return _mesasCache!;
      }
      
      // Fallback: crear mesas de ejemplo para testing offline
      debugPrint('🏠 Creating demo tables for offline mode');
      return _createDemoTables();
    }
  }

  // Crear mesas de ejemplo para modo offline
  // Total capacidad: ~50 personas en la parte superior
  static List<Map<String, dynamic>> _createDemoTables() {
    final mesas = <Map<String, dynamic>>[];
    
    // 1 Living (12 personas)
    mesas.add({
      'id': 'demo-living-1',
      'numero': 1,
      'capacidad': 12,
      'ubicacion': 'Living',
      'activa': true,
    });
    
    // 4 Mesas Barra (4 personas c/u = 16 total)
    for (int i = 2; i <= 5; i++) {
      mesas.add({
        'id': 'demo-barra-$i',
        'numero': i,
        'capacidad': 4,
        'ubicacion': 'Mesas Barra',
        'activa': true,
      });
    }
    
    // 5 Mesas Bajas (4-6 personas c/u = ~22 total)
    for (int i = 6; i <= 10; i++) {
      mesas.add({
        'id': 'demo-baja-$i',
        'numero': i,
        'capacidad': i == 6 ? 6 : 4, // Mesa 6 para 6, las demás para 4
        'ubicacion': 'Mesas Bajas',
        'activa': true,
      });
    }
    
    // Total: 12 + 16 + 22 = 50 personas máximo
    return mesas;
  }

  // Crear una nueva reserva
  static Future<Map<String, dynamic>?> createReservation({
    required String mesaId,
    required DateTime date,
    required String time,
    required int partySize,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? comments,
  }) async {
    try {
      debugPrint('🍽️ Creating reservation: Mesa $mesaId, Date ${date.toIso8601String().split('T')[0]}, Time $time, Party $partySize');

      final reservationData = <String, dynamic>{
        'mesa_id': mesaId,
        'fecha': date.toIso8601String().split('T')[0],
        'hora': time,
        'personas': partySize,
        'nombre': customerName,
        'telefono': customerPhone,
        'estado': 'confirmada',
      };

      if (customerEmail != null && customerEmail.isNotEmpty) {
        reservationData['email'] = customerEmail;
      }

      if (comments != null && comments.isNotEmpty) {
        reservationData['comentarios'] = comments;
      }

      final response = await _client
          .from('sodita_reservas')
          .insert(reservationData)
          .select()
          .single();

      debugPrint('✅ Reservation created successfully: ${response['codigo_confirmacion']}');
      return response;
    } catch (e) {
      debugPrint('❌ Error creating reservation: $e');
      return null;
    }
  }

  // Verificar disponibilidad de mesa (un solo turno por noche)
  static Future<bool> isTableAvailable({
    required String mesaId,
    required DateTime date,
    required String time, // Mantenido para compatibilidad pero no se usa en verificación
  }) async {
    try {
      // Verificar si la mesa ya tiene una reserva para esa fecha (cualquier hora)
      final response = await _client
          .from('sodita_reservas')
          .select('id')
          .eq('mesa_id', mesaId)
          .eq('fecha', date.toIso8601String().split('T')[0])
          .or('estado.eq.confirmada,estado.eq.en_mesa,estado.eq.completada');

      bool isAvailable = response.isEmpty;
      debugPrint('🔍 Table $mesaId available for ${date.toIso8601String().split('T')[0]}: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking table availability: $e');
      return false;
    }
  }

  // Obtener mesas ocupadas para una fecha (un solo turno por noche)
  static Future<List<String>> getOccupiedTables({
    required DateTime date,
    required String time, // Mantenido para compatibilidad pero no se usa
  }) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .or('estado.eq.confirmada,estado.eq.en_mesa,estado.eq.completada'); // Cualquier reserva de la noche

      debugPrint('🚫 Occupied tables for ${date.toIso8601String().split('T')[0]}: ${response.length} tables');
      return response.map<String>((item) => item['mesa_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching occupied tables: $e');
      return [];
    }
  }
  
  // Obtener mesas ocupadas actualmente (clientes en mesa)
  static Future<List<String>> getCurrentlyOccupiedTables({
    required DateTime date,
  }) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('estado', 'en_mesa');

      return response.map<String>((item) => item['mesa_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching currently occupied tables: $e');
      return [];
    }
  }
  
  // Verificar el estado de una mesa específica
  static Future<String> getTableStatus({
    required String mesaId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('estado')
          .eq('mesa_id', mesaId)
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('hora', time)
          .order('creado_en', ascending: false)
          .limit(1);

      if (response.isEmpty) return 'available';
      
      final estado = response.first['estado'];
      switch (estado) {
        case 'confirmada':
          return 'reserved';
        case 'en_mesa':
          return 'occupied';
        case 'completada':
        case 'no_show':
        case 'cancelada':
          return 'available';
        default:
          return 'available';
      }
    } catch (e) {
      debugPrint('Error getting table status: $e');
      return 'available';
    }
  }

  // Obtener reservas por fecha (solo pendientes de check-in)
  static Future<List<Map<String, dynamic>>> getReservationsByDate(DateTime date) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('estado', 'confirmada') // Solo mostrar las que esperan check-in
          .order('hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reservations: $e');
      return [];
    }
  }
  
  // Obtener reservas activas (en mesa) para estadísticas
  static Future<List<Map<String, dynamic>>> getActiveReservationsByDate(DateTime date) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('estado', 'en_mesa')
          .order('hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching active reservations: $e');
      return [];
    }
  }
  
  // Cache para reservas del día
  static Map<String, List<Map<String, dynamic>>> _reservationsCache = {};
  static DateTime? _lastCacheUpdate;

  // Obtener todas las reservas del día (con caché para velocidad)
  static Future<List<Map<String, dynamic>>> getAllReservationsByDate(DateTime date) async {
    final dateKey = date.toIso8601String().split('T')[0];
    final now = DateTime.now();
    
    // Usar caché si es reciente (último minuto)
    if (_lastCacheUpdate != null && 
        now.difference(_lastCacheUpdate!).inSeconds < 60 &&
        _reservationsCache.containsKey(dateKey)) {
      return _reservationsCache[dateKey]!;
    }

    try {
      final response = await _client
          .from('sodita_reservas')
          .select('*, sodita_mesas!inner(numero, capacidad, ubicacion)')
          .eq('fecha', dateKey)
          .order('hora');

      final reservations = List<Map<String, dynamic>>.from(response);
      
      // Actualizar caché
      _reservationsCache[dateKey] = reservations;
      _lastCacheUpdate = now;
      
      // Si no hay datos reales, crear datos de prueba para testing
      if (reservations.isEmpty && date.isAtSameMomentAs(DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0))) {
        final testData = _createTestReservations();
        _reservationsCache[dateKey] = testData;
        return testData;
      }

      return reservations;
    } catch (e) {
      debugPrint('Error fetching all reservations: $e');
      // En caso de error, devolver datos de prueba para testing
      return _createTestReservations();
    }
  }

  // Crear reservas de prueba para testing del dashboard (con hora Argentina)
  static List<Map<String, dynamic>> _createTestReservations() {
    // Usar hora Argentina (UTC-3)
    final nowUTC = DateTime.now().toUtc();
    final now = nowUTC.subtract(const Duration(hours: 3));
    final testReservations = [
      {
        'id': 'test-1',
        'codigo_confirmacion': 'SOD001',
        'nombre': 'Juan Pérez',
        'telefono': '+54 9 341 123-4567',
        'hora': '${(now.hour + 1).toString().padLeft(2, '0')}:00',
        'personas': 4,
        'estado': 'confirmada',
        'fecha': now.toIso8601String().split('T')[0],
        'sodita_mesas': {
          'numero': 5,
          'capacidad': 6,
          'ubicacion': 'Mesa grande central'
        }
      },
      {
        'id': 'test-2',
        'codigo_confirmacion': 'SOD002',
        'nombre': 'María García',
        'telefono': '+54 9 341 987-6543',
        'hora': '${(now.hour).toString().padLeft(2, '0')}:30',
        'personas': 2,
        'estado': 'confirmada',
        'fecha': now.toIso8601String().split('T')[0],
        'sodita_mesas': {
          'numero': 2,
          'capacidad': 2,
          'ubicacion': 'Ventana lateral'
        }
      },
      {
        'id': 'test-3',
        'codigo_confirmacion': 'SOD003',
        'nombre': 'Carlos Rodríguez',
        'telefono': '+54 9 341 555-1234',
        'hora': '${(now.hour - 1).toString().padLeft(2, '0')}:45',
        'personas': 6,
        'estado': 'en_mesa',
        'fecha': now.toIso8601String().split('T')[0],
        'sodita_mesas': {
          'numero': 6,
          'capacidad': 8,
          'ubicacion': 'Mesa familiar grande'
        }
      }
    ];
    
    debugPrint('📊 Created ${testReservations.length} test reservations for dashboard demo');
    return testReservations;
  }

  // Obtener todas las reservas (para admin)
  static Future<List<Map<String, dynamic>>> getAllReservations() async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all reservations: $e');
      return [];
    }
  }

  // Actualizar estado de reserva
  static Future<bool> updateReservationStatus(String reservationId, String status) async {
    try {
      await _client
          .from('sodita_reservas')
          .update({'estado': status})
          .eq('id', reservationId);

      return true;
    } catch (e) {
      debugPrint('Error updating reservation status: $e');
      return false;
    }
  }

  // Cancelar reserva
  static Future<bool> cancelReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'cancelada');
  }

  // Check-in: Marcar que el cliente llegó a la mesa
  static Future<bool> checkInReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'en_mesa');
  }

  // Marcar como no_show
  static Future<bool> markAsNoShow(String reservationId) async {
    return await updateReservationStatus(reservationId, 'no_show');
  }

  // Completar reserva (cliente terminó de comer)
  static Future<bool> completeReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'completada');
  }

  // Obtener reservas que necesitan check-in (confirmadas y dentro del rango de tiempo)
  static Future<List<Map<String, dynamic>>> getReservationsNeedingCheckIn() async {
    try {
      // Usar hora Argentina (UTC-3)
      final nowUTC = DateTime.now().toUtc();
      final nowArgentina = nowUTC.subtract(const Duration(hours: 3));
      final today = nowArgentina.toIso8601String().split('T')[0];
      
      // Buscar reservas confirmadas de hoy que deberían haber llegado
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .eq('fecha', today)
          .eq('estado', 'confirmada')
          .order('hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reservations needing check-in: $e');
      return [];
    }
  }

  // Marcar automáticamente como no_show las reservas que pasaron 15 minutos (usando hora Argentina)
  static Future<void> autoMarkNoShow() async {
    try {
      // Obtener hora actual en Argentina (UTC-3)
      final nowUTC = DateTime.now().toUtc();
      final nowArgentina = nowUTC.subtract(const Duration(hours: 3));
      final today = nowArgentina.toIso8601String().split('T')[0];
      
      // Buscar reservas confirmadas de hoy
      final response = await _client
          .from('sodita_reservas')
          .select('id, hora, nombre')
          .eq('fecha', today)
          .eq('estado', 'confirmada');

      // Verificar cada reserva individualmente
      for (final reservation in response) {
        if (hasExpired(reservation['hora'])) {
          await updateReservationStatus(reservation['id'], 'no_show');
          debugPrint('⏰ AUTO-RELEASED: ${reservation['nombre']} - Mesa liberada automáticamente (15min)');
        }
      }
    } catch (e) {
      debugPrint('Error auto-marking no_show: $e');
    }
  }

  // Liberar mesa manualmente (acción del admin)
  static Future<bool> releaseTableManually(String reservationId, String customerName) async {
    try {
      final success = await updateReservationStatus(reservationId, 'no_show');
      if (success) {
        debugPrint('🔓 MANUAL RELEASE: $customerName - Mesa liberada manualmente por admin');
      }
      return success;
    } catch (e) {
      debugPrint('Error releasing table manually: $e');
      return false;
    }
  }
  
  // Calcular tiempo restante - SISTEMA WOKI MEJORADO
  static Duration? getTimeUntilNoShow(String hora) {
    try {
      final now = DateTime.now();
      
      // Parsear hora de reserva
      final parts = hora.split(':');
      final reservationHour = int.parse(parts[0]);
      final reservationMinute = int.parse(parts[1]);
      
      // Hora exacta de la reserva HOY
      final reservationTime = DateTime(
        now.year, now.month, now.day,
        reservationHour, reservationMinute, 0
      );
      
      // El cliente tiene 15 minutos desde su hora de reserva
      final deadline = reservationTime.add(const Duration(minutes: 15));
      
      // Si aún no es la hora de su reserva
      if (now.isBefore(reservationTime)) {
        return const Duration(minutes: 15); // Mostrar 15:00
      }
      
      // Si ya pasó el deadline
      if (now.isAfter(deadline)) {
        return null; // EXPIRADO
      }
      
      // Tiempo restante real
      return deadline.difference(now);
      
    } catch (e) {
      return null;
    }
  }
  
  // Verificar si una reserva está en período crítico (últimos 5 minutos)
  static bool isInCriticalPeriod(String hora) {
    final timeLeft = getTimeUntilNoShow(hora);
    if (timeLeft == null) return false;
    return timeLeft.inMinutes <= 5;
  }
  
  // Verificar si una reserva ya expiró
  static bool hasExpired(String hora) {
    return getTimeUntilNoShow(hora) == null;
  }
  
  // Formatear tiempo restante para mostrar
  static String formatTimeRemaining(Duration timeLeft) {
    final minutes = timeLeft.inMinutes;
    final seconds = timeLeft.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Obtener reservas por rango de fechas (7, 15, 30 días)
  static Future<List<Map<String, dynamic>>> getReservationsByDateRange(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .gte('fecha', startDate.toIso8601String().split('T')[0])
          .lte('fecha', endDate.toIso8601String().split('T')[0])
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reservations by date range: $e');
      return [];
    }
  }

  // Obtener estadísticas de reservas por período
  static Future<Map<String, dynamic>> getReservationStats(int days) async {
    try {
      final reservations = await getReservationsByDateRange(days);
      
      final total = reservations.length;
      final confirmadas = reservations.where((r) => r['estado'] == 'confirmada').length;
      final completadas = reservations.where((r) => r['estado'] == 'completada').length;
      final noShows = reservations.where((r) => r['estado'] == 'no_show').length;
      final canceladas = reservations.where((r) => r['estado'] == 'cancelada').length;
      final enMesa = reservations.where((r) => r['estado'] == 'en_mesa').length;

      return {
        'total': total,
        'confirmadas': confirmadas,
        'completadas': completadas,
        'no_shows': noShows,
        'canceladas': canceladas,
        'en_mesa': enMesa,
        'tasa_completadas': total > 0 ? (completadas / total * 100).round() : 0,
        'tasa_no_shows': total > 0 ? (noShows / total * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('Error calculating reservation stats: $e');
      return {};
    }
  }

  // Obtener reservas agrupadas por fecha para el calendario
  static Future<Map<DateTime, List<Map<String, dynamic>>>> getReservationsForCalendar(int days) async {
    try {
      final reservations = await getReservationsByDateRange(days);
      final Map<DateTime, List<Map<String, dynamic>>> groupedReservations = {};

      for (final reservation in reservations) {
        final date = DateTime.parse(reservation['fecha']);
        final dateKey = DateTime(date.year, date.month, date.day);
        
        if (groupedReservations[dateKey] == null) {
          groupedReservations[dateKey] = [];
        }
        
        groupedReservations[dateKey]!.add(reservation);
      }

      return groupedReservations;
    } catch (e) {
      debugPrint('Error grouping reservations for calendar: $e');
      return {};
    }
  }

  // Obtener reservas futuras (próximos 30 días desde hoy)
  static Future<Map<DateTime, List<Map<String, dynamic>>>> getFutureReservations() async {
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30));
      
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .gte('fecha', startDate.toIso8601String().split('T')[0])
          .lte('fecha', endDate.toIso8601String().split('T')[0])
          .order('fecha', ascending: true)
          .order('hora', ascending: true);

      final reservations = List<Map<String, dynamic>>.from(response);
      final Map<DateTime, List<Map<String, dynamic>>> groupedReservations = {};

      for (final reservation in reservations) {
        final date = DateTime.parse(reservation['fecha']);
        final dateKey = DateTime(date.year, date.month, date.day);
        
        if (groupedReservations[dateKey] == null) {
          groupedReservations[dateKey] = [];
        }
        
        groupedReservations[dateKey]!.add(reservation);
      }

      return groupedReservations;
    } catch (e) {
      debugPrint('Error getting future reservations: $e');
      return {};
    }
  }

  // Obtener reservas por fecha específica
  static Future<List<Map<String, dynamic>>> getReservationsBySpecificDate(DateTime date) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .order('hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reservations for specific date: $e');
      return [];
    }
  }

  // Obtener estadísticas de ocupación por fecha
  static Future<Map<String, dynamic>> getDateOccupancyStats(DateTime date) async {
    try {
      final reservations = await getReservationsBySpecificDate(date);
      final allTables = await getMesas();
      final totalTables = allTables.length;
      
      final totalReservations = reservations.length;
      final confirmedReservations = reservations.where((r) => r['estado'] == 'confirmada').length;
      final activeReservations = reservations.where((r) => r['estado'] == 'en_mesa').length;
      final completedReservations = reservations.where((r) => r['estado'] == 'completada').length;
      final cancelledReservations = reservations.where((r) => r['estado'] == 'cancelada').length;
      
      // Mesas únicas ocupadas
      final occupiedTables = reservations
          .where((r) => r['estado'] == 'confirmada' || r['estado'] == 'en_mesa')
          .map((r) => r['mesa_id'])
          .toSet()
          .length;
      
      final occupancyRate = totalTables > 0 ? (occupiedTables / totalTables * 100).round() : 0;
      
      return {
        'total_reservations': totalReservations,
        'confirmed': confirmedReservations,
        'active': activeReservations,
        'completed': completedReservations,
        'cancelled': cancelledReservations,
        'total_tables': totalTables,
        'occupied_tables': occupiedTables,
        'free_tables': totalTables - occupiedTables,
        'occupancy_rate': occupancyRate,
        'reservations': reservations,
      };
    } catch (e) {
      debugPrint('Error calculating date occupancy stats: $e');
      return {};
    }
  }
}