import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../supabase_config.dart';

// SERVICIO DE ANALYTICS GRATUITO - FIREBASE ANALYTICS + SUPABASE LOGS
class FreeAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final _client = supabase;

  // EVENTOS DE RESERVAS
  
  /// Track cuando usuario ve la pantalla principal
  static Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('📊 Screen view tracked: $screenName');
    } catch (e) {
      debugPrint('❌ Error tracking screen view: $e');
    }
  }

  /// Track cuando usuario hace una reserva
  static Future<void> trackReservationCreated({
    required String mesaId,
    required int personas,
    required String fecha,
    required String hora,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'reservation_created',
        parameters: {
          'mesa_id': mesaId,
          'party_size': personas,
          'date': fecha,
          'time': hora,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // También guardar en Supabase para análisis detallado
      await _logToSupabase('reservation_created', {
        'mesa_id': mesaId,
        'personas': personas,
        'fecha': fecha,
        'hora': hora,
      });
      
      debugPrint('📊 Reservation created tracked');
    } catch (e) {
      debugPrint('❌ Error tracking reservation: $e');
    }
  }

  /// Track cuando usuario cancela reserva
  static Future<void> trackReservationCancelled(String reservationId) async {
    try {
      await _analytics.logEvent(
        name: 'reservation_cancelled',
        parameters: {
          'reservation_id': reservationId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('reservation_cancelled', {
        'reservation_id': reservationId,
      });
      
      debugPrint('📊 Reservation cancelled tracked');
    } catch (e) {
      debugPrint('❌ Error tracking cancellation: $e');
    }
  }

  /// Track Mesa Ya! usage
  static Future<void> trackMesaYaUsed({
    required String mesaId,
    required int personas,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'mesa_ya_used',
        parameters: {
          'mesa_id': mesaId,
          'party_size': personas,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('mesa_ya_used', {
        'mesa_id': mesaId,
        'personas': personas,
      });
      
      debugPrint('📊 Mesa Ya! usage tracked');
    } catch (e) {
      debugPrint('❌ Error tracking Mesa Ya!: $e');
    }
  }

  /// Track cuando usuario deja review
  static Future<void> trackReviewSubmitted({
    required String reservationId,
    required int rating,
    bool hasComment = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'review_submitted',
        parameters: {
          'reservation_id': reservationId,
          'rating': rating,
          'has_comment': hasComment,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('review_submitted', {
        'reservation_id': reservationId,
        'rating': rating,
        'has_comment': hasComment,
      });
      
      debugPrint('📊 Review submitted tracked');
    } catch (e) {
      debugPrint('❌ Error tracking review: $e');
    }
  }

  /// Track errores importantes
  static Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage.length > 100 
              ? errorMessage.substring(0, 100) 
              : errorMessage,
          'screen': screen ?? 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('app_error', {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen': screen,
      });
      
      debugPrint('📊 Error tracked: $errorType');
    } catch (e) {
      debugPrint('❌ Error tracking error: $e');
    }
  }

  // EVENTOS DE USUARIO

  /// Track login de usuario
  static Future<void> trackUserLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      
      await _logToSupabase('user_login', {
        'method': method,
      });
      
      debugPrint('📊 User login tracked: $method');
    } catch (e) {
      debugPrint('❌ Error tracking login: $e');
    }
  }

  /// Track cuando usuario cambia idioma
  static Future<void> trackLanguageChanged(String language) async {
    try {
      await _analytics.logEvent(
        name: 'language_changed',
        parameters: {
          'language': language,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('language_changed', {
        'language': language,
      });
      
      debugPrint('📊 Language change tracked: $language');
    } catch (e) {
      debugPrint('❌ Error tracking language change: $e');
    }
  }

  // MÉTRICAS DE NEGOCIO

  /// Track ocupación de mesas
  static Future<void> trackTableOccupancy({
    required int totalTables,
    required int occupiedTables,
    required String timeSlot,
  }) async {
    try {
      final occupancyRate = (occupiedTables / totalTables * 100).round();
      
      await _analytics.logEvent(
        name: 'table_occupancy',
        parameters: {
          'total_tables': totalTables,
          'occupied_tables': occupiedTables,
          'occupancy_rate': occupancyRate,
          'time_slot': timeSlot,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      await _logToSupabase('table_occupancy', {
        'total_tables': totalTables,
        'occupied_tables': occupiedTables,
        'occupancy_rate': occupancyRate,
        'time_slot': timeSlot,
      });
      
      debugPrint('📊 Table occupancy tracked: $occupancyRate%');
    } catch (e) {
      debugPrint('❌ Error tracking occupancy: $e');
    }
  }

  // HELPERS

  /// Guardar evento en Supabase para análisis detallado
  static Future<void> _logToSupabase(String eventType, Map<String, dynamic> data) async {
    try {
      await _client.from('sodita_analytics_events').insert({
        'event_type': eventType,
        'event_data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      // Fallar silenciosamente para no interrumpir la UX
      debugPrint('⚠️ Failed to log to Supabase: $e');
    }
  }

  /// Configurar propiedades de usuario para análisis
  static Future<void> setUserProperties({
    String? userId,
    bool? isVip,
    int? totalReservations,
    double? averageRating,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      
      if (isVip != null) {
        await _analytics.setUserProperty(name: 'is_vip', value: isVip.toString());
      }
      
      if (totalReservations != null) {
        await _analytics.setUserProperty(
          name: 'total_reservations', 
          value: totalReservations.toString()
        );
      }
      
      if (averageRating != null) {
        await _analytics.setUserProperty(
          name: 'avg_rating_given', 
          value: averageRating.toStringAsFixed(1)
        );
      }
      
      debugPrint('📊 User properties updated');
    } catch (e) {
      debugPrint('❌ Error setting user properties: $e');
    }
  }

  /// Obtener resumen de analytics desde Supabase
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Obtener eventos de hoy
      final events = await _client
          .from('sodita_analytics_events')
          .select('event_type')
          .gte('timestamp', '${today}T00:00:00')
          .lte('timestamp', '${today}T23:59:59');

      final eventCounts = <String, int>{};
      for (final event in events) {
        final type = event['event_type'] as String;
        eventCounts[type] = (eventCounts[type] ?? 0) + 1;
      }

      return {
        'date': today,
        'total_events': events.length,
        'event_breakdown': eventCounts,
      };
    } catch (e) {
      debugPrint('❌ Error getting analytics summary: $e');
      return {'error': e.toString()};
    }
  }
}