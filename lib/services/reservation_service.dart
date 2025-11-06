import '../supabase_config.dart';

class ReservationService {
  static final _client = supabase;

  // Obtener todas las mesas
  static Future<List<Map<String, dynamic>>> getMesas() async {
    try {
      print('🔍 Cargando mesas desde la base de datos...');
      final response = await _client
          .from('sodita_mesas')
          .select('*')
          .eq('activa', true)
          .order('numero');

      print('✅ Mesas cargadas: ${response.length} mesas encontradas');
      print('📋 Datos de mesas: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching mesas: $e');
      print('⚠️ IMPORTANTE: Ejecuta supabase_setup_clean.sql en tu panel de Supabase');
      print('📍 Panel: https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo');
      return [];
    }
  }


  // Crear una nueva reserva en Supabase
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
      print('🍽️ Creando reserva en Supabase:');
      print('   Mesa ID: $mesaId');
      print('   Fecha: ${date.toIso8601String().split('T')[0]}');
      print('   Hora: $time');
      print('   Personas: $partySize');
      print('   Cliente: $customerName');
      print('   Teléfono: $customerPhone');

      // Buscar el UUID real de la mesa basado en el número
      final mesas = await getMesas();
      final mesa = mesas.firstWhere(
        (m) => m['numero'].toString() == mesaId,
        orElse: () => {'id': mesaId}, // Fallback si no se encuentra
      );
      
      final realMesaId = mesa['id'];
      print('🔄 Mesa número $mesaId -> UUID: $realMesaId');

      final reservationData = <String, dynamic>{
        'mesa_id': realMesaId,
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

      print('✅ Reserva creada exitosamente!');
      print('   Código: ${response['codigo_confirmacion'] ?? response['id']}');
      print('   ⏰ IMPORTANTE: Tienes 15 minutos para confirmar tu llegada');
      print('📊 Reserva ID: ${response['id']}, Estado: ${response['estado']}');
      
      return response;
      
    } catch (e) {
      print('❌ Error creating reservation: $e');
      print('⚠️ IMPORTANTE: Ejecuta supabase_setup_clean.sql en tu panel de Supabase');
      print('📍 Panel: https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo');
      return null;
    }
  }

  // Verificar disponibilidad de mesa
  static Future<bool> isTableAvailable({
    required String mesaId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _client
          .rpc('verificar_disponibilidad_mesa', params: {
            'p_mesa_id': mesaId,
            'p_fecha': date.toIso8601String().split('T')[0],
            'p_hora': time,
            'p_duracion_minutos': 120,
          });

      return response as bool;
    } catch (e) {
      print('Error checking table availability: $e');
      return false;
    }
  }

  // Obtener mesas ocupadas para una fecha y hora específica
  static Future<List<String>> getOccupiedTables({
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('hora', time)
          .or('estado.eq.confirmada,estado.eq.en_mesa'); // Incluir mesas ocupadas

      return response.map<String>((item) => item['mesa_id'] as String).toList();
    } catch (e) {
      print('Error fetching occupied tables: $e');
      return [];
    }
  }

  // Obtener todas las mesas reservadas del día (sin filtrar por hora específica)
  static Future<List<String>> getAllReservedTablesForDay({
    required DateTime date,
  }) async {
    try {
      final response = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', date.toIso8601String().split('T')[0])
          .eq('estado', 'confirmada');

      return response.map<String>((item) => item['mesa_id'] as String).toList();
    } catch (e) {
      print('Error fetching all reserved tables for day: $e');
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
      print('Error fetching currently occupied tables: $e');
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
        case 'expirada':
          return 'available';
        default:
          return 'available';
      }
    } catch (e) {
      print('Error getting table status: $e');
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
          // Mostrar TODAS las reservas del día, no solo confirmadas
          .order('hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reservations: $e');
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
      print('Error fetching active reservations: $e');
      return [];
    }
  }
  
  // Obtener todas las reservas del día (para estadísticas completas)
  static Future<List<Map<String, dynamic>>> getAllReservationsByDate(DateTime date) async {
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
      print('Error fetching all reservations: $e');
      return [];
    }
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
      print('Error fetching all reservations: $e');
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
      print('Error updating reservation status: $e');
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
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
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
      print('Error fetching reservations needing check-in: $e');
      return [];
    }
  }

  // Marcar automáticamente como no_show las reservas que pasaron 15 minutos
  static Future<void> autoMarkNoShow() async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      // Calcular 15 minutos atrás
      final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
      final timeLimit = '${fifteenMinutesAgo.hour.toString().padLeft(2, '0')}:${fifteenMinutesAgo.minute.toString().padLeft(2, '0')}';

      // Buscar reservas confirmadas que pasaron 15 minutos
      final response = await _client
          .from('sodita_reservas')
          .select('id, hora')
          .eq('fecha', today)
          .eq('estado', 'confirmada')
          .lt('hora', timeLimit);

      // Marcar cada una como no_show
      for (final reservation in response) {
        await updateReservationStatus(reservation['id'], 'no_show');
        print('⏰ Marcada como no_show: ${reservation['id']} (hora: ${reservation['hora']})');
      }
    } catch (e) {
      print('Error auto-marking no_show: $e');
    }
  }
  
  // Calcular tiempo restante antes de que se marque como no_show
  static Duration? getTimeUntilNoShow(String hora) {
    final now = DateTime.now();
    final reservationTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(hora.split(':')[0]),
      int.parse(hora.split(':')[1]),
    );
    
    final expireTime = reservationTime.add(const Duration(minutes: 15));
    
    if (now.isAfter(expireTime)) {
      return null; // Ya expiró
    }
    
    return expireTime.difference(now);
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
      print('Error fetching reservations by date range: $e');
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
      print('Error calculating reservation stats: $e');
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
      print('Error grouping reservations for calendar: $e');
      return {};
    }
  }

  // Obtener reservas que han pasado los 15 minutos de tolerancia
  static Future<List<Map<String, dynamic>>> getExpiredReservations() async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      final response = await _client
          .from('sodita_reservas')
          .select('*, sodita_mesas(*)')
          .eq('fecha', today)
          .eq('estado', 'confirmada');
      
      List<Map<String, dynamic>> expiredReservations = [];
      
      print('🔍 Verificando ${response.length} reservas confirmadas para expiración...');
      
      for (var reservation in response) {
        final timeString = reservation['hora'].toString();
        final cleanTimeString = timeString.contains(':00:00') ? timeString.substring(0, 5) : timeString;
        final reservationTime = DateTime.parse('${reservation['fecha']} $cleanTimeString:00');
        final toleranceTime = reservationTime.add(const Duration(minutes: 15));
        
        print('📋 Reserva: ${reservation['nombre']} - Mesa ${reservation['sodita_mesas']['numero']}');
        print('⏰ Hora reserva: $reservationTime');
        print('⏱️ Expira a las: $toleranceTime');
        print('🕒 Hora actual: $now');
        print('❓ ¿Expiró? ${now.isAfter(toleranceTime)}');
        print('---');
        
        if (now.isAfter(toleranceTime)) {
          print('🚨 RESERVA EXPIRADA: ${reservation['nombre']} - Mesa ${reservation['sodita_mesas']['numero']}');
          expiredReservations.add(reservation);
        }
      }
      
      return expiredReservations;
    } catch (e) {
      print('❌ Error getting expired reservations: $e');
      return [];
    }
  }

  // Liberar automáticamente una reserva
  static Future<bool> releaseExpiredReservation(String reservationId) async {
    try {
      await _client
          .from('sodita_reservas')
          .update({
            'estado': 'expirada',
            'comentarios': 'Liberada automáticamente - Cliente no se presentó en 15 minutos'
          })
          .eq('id', reservationId);
      
      print('✅ Reserva $reservationId liberada automáticamente');
      return true;
    } catch (e) {
      print('❌ Error releasing reservation: $e');
      return false;
    }
  }

  // Obtener tiempo restante para que expire una reserva (en minutos)
  static int? getTimeUntilExpiration(String hora) {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final reservationTime = DateTime.parse('$today $hora:00');
      final expirationTime = reservationTime.add(const Duration(minutes: 15));
      
      if (now.isAfter(expirationTime)) {
        return 0; // Ya expiró
      }
      
      final difference = expirationTime.difference(now);
      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }

  // Obtener tiempo restante en segundos para countdown preciso
  static int? getTimeUntilExpirationSeconds(String hora) {
    try {
      // Usar hora de Argentina específicamente
      final now = DateTime.now(); // Ya configurado en America/Argentina/Buenos_Aires
      final today = now.toIso8601String().split('T')[0];
      final reservationTime = DateTime.parse('$today $hora:00');
      final expirationTime = reservationTime.add(const Duration(minutes: 15));
      
      print('🕒 TIMEZONE CHECK: Hora actual Argentina: ${now.toString()}');
      print('📅 Reserva: $reservationTime | Expira: $expirationTime');
      
      // Si aún no ha llegado la hora de la reserva, mostrar tiempo hasta que inicie el countdown
      if (now.isBefore(reservationTime)) {
        // Mostrar que falta tiempo para que inicie la reserva
        return null; // No mostrar countdown aún
      }
      
      if (now.isAfter(expirationTime)) {
        return 0; // Ya expiró
      }
      
      final difference = expirationTime.difference(now);
      return difference.inSeconds;
    } catch (e) {
      return null;
    }
  }

  // Obtener estado de la reserva (antes de la hora, en tolerancia, expirada)
  static String getReservationStatus(String hora) {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final reservationTime = DateTime.parse('$today $hora:00');
      final expirationTime = reservationTime.add(const Duration(minutes: 15));
      
      if (now.isBefore(reservationTime)) {
        return 'pending'; // Esperando hora de reserva
      } else if (now.isAfter(expirationTime)) {
        return 'expired'; // Expirada
      } else {
        return 'active'; // En período de tolerancia
      }
    } catch (e) {
      return 'unknown';
    }
  }

  // Obtener tiempo hasta que inicie la reserva (si es en el futuro)
  static int? getTimeUntilReservationStart(String hora) {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final reservationTime = DateTime.parse('$today $hora:00');
      
      if (now.isBefore(reservationTime)) {
        final difference = reservationTime.difference(now);
        return difference.inSeconds;
      }
      
      return null; // Ya es hora o ya pasó
    } catch (e) {
      return null;
    }
  }

  // Verificar si el restaurante está lleno (todas las mesas ocupadas o reservadas)
  static Future<bool> isRestaurantFull() async {
    try {
      final now = DateTime.now();
      final currentHour = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // Obtener todas las mesas activas
      final allTables = await getMesas();
      
      // Obtener mesas ocupadas actualmente
      final occupiedTables = await getCurrentlyOccupiedTables(date: now);
      
      // Obtener mesas reservadas para la hora actual
      final reservedTables = await getOccupiedTables(date: now, time: currentHour);
      
      // Combinar mesas ocupadas y reservadas
      final unavailableTables = {...occupiedTables, ...reservedTables};
      
      // Si todas las mesas están ocupadas o reservadas, el restaurante está lleno
      return unavailableTables.length >= allTables.length;
    } catch (e) {
      print('❌ Error checking if restaurant is full: $e');
      return false;
    }
  }

  // Procesar liberación automática de reservas expiradas
  static Future<List<Map<String, dynamic>>> processExpiredReservations() async {
    try {
      final expiredReservations = await getExpiredReservations();
      List<Map<String, dynamic>> releasedTables = [];
      
      for (var reservation in expiredReservations) {
        final success = await releaseExpiredReservation(reservation['id']);
        if (success) {
          releasedTables.add(reservation);
        }
      }
      
      return releasedTables;
    } catch (e) {
      print('❌ Error processing expired reservations: $e');
      return [];
    }
  }

  // Obtener reserva activa actual
  static Future<Map<String, dynamic>?> getActiveReservation() async {
    try {
      final now = DateTime.now();
      final reservations = await getActiveReservationsByDate(now);
      
      // Retornar la primera reserva activa encontrada o null si no hay ninguna
      return reservations.isNotEmpty ? reservations.first : null;
    } catch (e) {
      print('❌ Error getting active reservation: $e');
      return null;
    }
  }
}