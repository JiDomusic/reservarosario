import '../supabase_config.dart';

class MultiRestaurantService {
  static final _client = supabase;

  // Obtener todas las mesas de un restaurante específico
  static Future<List<Map<String, dynamic>>> getMesas(String restaurantId) async {
    try {
      print('🔍 Cargando mesas del restaurante $restaurantId...');
      final response = await _client
          .from('restaurant_tables')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('table_number');

      print('✅ Mesas cargadas: ${response.length} mesas encontradas');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching mesas: $e');
      return [];
    }
  }

  // Crear una nueva reserva (EXACTO COMO SODITA)
  static Future<Map<String, dynamic>?> createReservation({
    required String restaurantId,
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
      print('🍽️ Creando reserva en restaurante $restaurantId:');

      final reservationData = <String, dynamic>{
        'restaurant_id': restaurantId,
        'table_id': mesaId,
        'reservation_date': date.toIso8601String().split('T')[0],
        'reservation_time': time,
        'party_size': partySize,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'status': 'confirmed',
        'confirmation_code': 'RES${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}',
      };

      if (customerEmail != null && customerEmail.isNotEmpty) {
        reservationData['customer_email'] = customerEmail;
      }

      if (comments != null && comments.isNotEmpty) {
        reservationData['notes'] = comments;
      }

      final response = await _client
          .from('restaurant_reservations')
          .insert(reservationData)
          .select()
          .single();

      print('✅ Reserva creada exitosamente: ${response['codigo_confirmacion']}');
      return response;
    } catch (e) {
      print('❌ Error creating reservation: $e');
      return null;
    }
  }

  // Verificar disponibilidad de mesa
  static Future<bool> isTableAvailable({
    required String restaurantId,
    required String mesaId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('id')
          .eq('restaurant_id', restaurantId)
          .eq('table_id', mesaId)
          .eq('reservation_date', date.toIso8601String().split('T')[0])
          .eq('reservation_time', time)
          .eq('status', 'confirmed');

      return response.isEmpty;
    } catch (e) {
      print('Error checking table availability: $e');
      return false;
    }
  }

  // Obtener mesas ocupadas para una fecha y hora específica
  static Future<List<String>> getOccupiedTables({
    required String restaurantId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('table_id')
          .eq('restaurant_id', restaurantId)
          .eq('reservation_date', date.toIso8601String().split('T')[0])
          .eq('reservation_time', time)
          .or('status.eq.confirmed,status.eq.seated');

      return response.map<String>((item) => item['table_id'] as String).toList();
    } catch (e) {
      print('Error fetching occupied tables: $e');
      return [];
    }
  }

  // Obtener mesas ocupadas actualmente (clientes en mesa)
  static Future<List<String>> getCurrentlyOccupiedTables({
    required String restaurantId,
    required DateTime date,
  }) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('table_id')
          .eq('restaurant_id', restaurantId)
          .eq('reservation_date', date.toIso8601String().split('T')[0])
          .eq('status', 'seated');

      return response.map<String>((item) => item['table_id'] as String).toList();
    } catch (e) {
      print('Error fetching currently occupied tables: $e');
      return [];
    }
  }

  // Obtener reservas por fecha CON MESAS
  static Future<List<Map<String, dynamic>>> getReservationsByDate(String restaurantId, DateTime date) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('''
            *,
            restaurant_tables!inner(table_number, capacity, location)
          ''')
          .eq('restaurant_id', restaurantId)
          .eq('reservation_date', date.toIso8601String().split('T')[0])
          .order('reservation_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reservations: $e');
      return [];
    }
  }

  // Obtener reservas activas (en mesa) para estadísticas
  static Future<List<Map<String, dynamic>>> getActiveReservationsByDate(String restaurantId, DateTime date) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('''
            *,
            restaurant_tables!inner(table_number, capacity, location)
          ''')
          .eq('restaurant_id', restaurantId)
          .eq('reservation_date', date.toIso8601String().split('T')[0])
          .eq('status', 'seated')
          .order('reservation_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching active reservations: $e');
      return [];
    }
  }

  // Actualizar estado de reserva
  static Future<bool> updateReservationStatus(String reservationId, String status) async {
    try {
      await _client
          .from('restaurant_reservations')
          .update({'status': status})
          .eq('id', reservationId);
      return true;
    } catch (e) {
      print('Error updating reservation status: $e');
      return false;
    }
  }

  // Check-in: Marcar que el cliente llegó a la mesa
  static Future<bool> checkInReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'seated');
  }

  // Completar reserva (cliente terminó de comer)
  static Future<bool> completeReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'completed');
  }

  // Cancelar reserva
  static Future<bool> cancelReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, 'cancelled');
  }

  // TOLERANCIA DE 15 MINUTOS - COUNTDOWN EXACTO COMO SODITA
  static Future<List<Map<String, dynamic>>> getExpiredReservations(String restaurantId) async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      final response = await _client
          .from('restaurant_reservations')
          .select('*, restaurant_tables(*)')
          .eq('restaurant_id', restaurantId)
          .eq('reservation_date', today)
          .eq('status', 'confirmed');
      
      List<Map<String, dynamic>> expiredReservations = [];
      
      print('🔍 Verificando ${response.length} reservas confirmadas para expiración...');
      
      for (var reservation in response) {
        final timeString = reservation['reservation_time'].toString();
        final cleanTimeString = timeString.contains(':00:00') ? timeString.substring(0, 5) : timeString;
        final reservationTime = DateTime.parse('${reservation['reservation_date']} $cleanTimeString:00');
        final toleranceTime = reservationTime.add(const Duration(minutes: 15));
        
        print('📋 Reserva: ${reservation['customer_name']} - Mesa ${reservation['restaurant_tables']['table_number']}');
        print('⏰ Hora reserva: $reservationTime');
        print('⏱️ Expira a las: $toleranceTime');
        print('🕒 Hora actual: $now');
        print('❓ ¿Expiró? ${now.isAfter(toleranceTime)}');
        print('---');
        
        if (now.isAfter(toleranceTime)) {
          print('🚨 RESERVA EXPIRADA: ${reservation['customer_name']} - Mesa ${reservation['restaurant_tables']['table_number']}');
          expiredReservations.add(reservation);
        }
      }
      
      return expiredReservations;
    } catch (e) {
      print('❌ Error getting expired reservations: $e');
      return [];
    }
  }

  // Liberar automáticamente una reserva expirada
  static Future<bool> releaseExpiredReservation(String reservationId) async {
    try {
      await _client
          .from('restaurant_reservations')
          .update({
            'status': 'expired',
            'notes': 'Liberada automáticamente - Cliente no se presentó en 15 minutos'
          })
          .eq('id', reservationId);
      
      print('✅ Reserva $reservationId liberada automáticamente');
      return true;
    } catch (e) {
      print('❌ Error releasing reservation: $e');
      return false;
    }
  }

  // Procesar liberación automática de reservas expiradas
  static Future<List<Map<String, dynamic>>> processExpiredReservations(String restaurantId) async {
    try {
      final expiredReservations = await getExpiredReservations(restaurantId);
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

  // COUNTDOWN - Obtener tiempo restante en segundos para countdown preciso
  static int? getTimeUntilExpirationSeconds(String reservationTime) {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final reservationDateTime = DateTime.parse('$today $reservationTime:00');
      final expirationTime = reservationDateTime.add(const Duration(minutes: 15));
      
      print('🕒 TIMEZONE CHECK: Hora actual Argentina: ${now.toString()}');
      print('📅 Reserva: $reservationDateTime | Expira: $expirationTime');
      
      // Si aún no ha llegado la hora de la reserva, mostrar tiempo hasta que inicie el countdown
      if (now.isBefore(reservationDateTime)) {
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
  static String getReservationStatus(String reservationTime) {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final reservationDateTime = DateTime.parse('$today $reservationTime:00');
      final expirationTime = reservationDateTime.add(const Duration(minutes: 15));
      
      if (now.isBefore(reservationDateTime)) {
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

  // Verificar si una reserva está en período crítico (últimos 5 minutos)
  static bool isInCriticalPeriod(String reservationTime) {
    final timeLeft = getTimeUntilExpirationSeconds(reservationTime);
    if (timeLeft == null) return false;
    return timeLeft <= 300; // 5 minutos = 300 segundos
  }

  // Verificar si una reserva ya expiró
  static bool hasExpired(String reservationTime) {
    return getTimeUntilExpirationSeconds(reservationTime) == 0;
  }

  // Formatear tiempo restante para mostrar en admin (MM:SS)
  static String formatTimeRemaining(int timeLeft) {
    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // SISTEMA DE CALIFICACIONES - EXACTO COMO SODITA
  static Future<bool> createReview({
    required String restaurantId,
    required String reservationId,
    required String customerName,
    required int rating,
    String? comment,
  }) async {
    try {
      final reviewData = {
        'restaurant_id': restaurantId,
        'reservation_id': reservationId,
        'customer_name': customerName,
        'rating': rating,
        'comment': comment,
        'is_public': true,
      };

      await _client
          .from('restaurant_reviews')
          .insert(reviewData);

      return true;
    } catch (e) {
      print('❌ Error creating review: $e');
      return false;
    }
  }

  // Obtener calificaciones públicas del restaurante
  static Future<List<Map<String, dynamic>>> getPublicReviews(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_reviews')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      return [];
    }
  }

  // Obtener promedio de calificaciones
  static Future<Map<String, dynamic>> getAverageRating(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_reviews')
          .select('rating')
          .eq('restaurant_id', restaurantId)
          .eq('is_public', true);

      if (response.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;

      return {
        'average': double.parse(average.toStringAsFixed(1)),
        'count': ratings.length,
      };
    } catch (e) {
      print('❌ Error calculating average rating: $e');
      return {'average': 0.0, 'count': 0};
    }
  }

  // Obtener información del restaurante
  static Future<Map<String, dynamic>?> getRestaurantInfo(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurants')
          .select('*')
          .eq('id', restaurantId)
          .single();
      
      return response;
    } catch (e) {
      print('❌ Error getting restaurant info: $e');
      return null;
    }
  }

  // Obtener horarios del restaurante
  static Future<List<Map<String, dynamic>>> getRestaurantSchedules(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_schedules')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .order('day_of_week');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching schedules: $e');
      return [];
    }
  }

  // Verificar si el restaurante está lleno
  static Future<bool> isRestaurantFull(String restaurantId) async {
    try {
      final now = DateTime.now();
      final currentHour = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      final allTables = await getMesas(restaurantId);
      final occupiedTables = await getCurrentlyOccupiedTables(restaurantId: restaurantId, date: now);
      final reservedTables = await getOccupiedTables(restaurantId: restaurantId, date: now, time: currentHour);
      
      final unavailableTables = {...occupiedTables, ...reservedTables};
      
      return unavailableTables.length >= allTables.length;
    } catch (e) {
      print('❌ Error checking if restaurant is full: $e');
      return false;
    }
  }

  // Obtener reserva activa actual
  static Future<Map<String, dynamic>?> getActiveReservation(String restaurantId) async {
    try {
      final now = DateTime.now();
      final reservations = await getActiveReservationsByDate(restaurantId, now);
      
      return reservations.isNotEmpty ? reservations.first : null;
    } catch (e) {
      print('❌ Error getting active reservation: $e');
      return null;
    }
  }
}