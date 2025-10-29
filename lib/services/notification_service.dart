import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';

// SISTEMA DE NOTIFICACIONES INTELIGENTES ESTILO WOKI PARA SODITA
class NotificationService {
  static final _client = supabase;
  
  // Tipos de notificaciones
  static const String MESA_DISPONIBLE = 'mesa_disponible';
  static const String RECORDATORIO_RESERVA = 'recordatorio_reserva';
  static const String CONFIRMACION_REQUERIDA = 'confirmacion_requerida';
  static const String MESA_LIBERADA = 'mesa_liberada';
  static const String TIEMPO_AGOTANDOSE = 'tiempo_agotandose';
  static const String REVIEW_REQUEST = 'review_request';

  // NOTIFICACIONES PUSH INTELIGENTES

  /// Enviar notificación de mesa disponible (Cola Virtual)
  static Future<void> notifyTableAvailable({
    required String userId,
    required String userName,
    required String userPhone,
    required int tableNumber,
    required String tableLocation,
    int minutesToConfirm = 5,
  }) async {
    try {
      debugPrint('📨 Sending table available notification to $userName');
      
      // Crear notificación en BD
      await _createNotification(
        userId: userId,
        type: MESA_DISPONIBLE,
        title: '🎉 ¡Tu mesa está lista!',
        message: 'Mesa $tableNumber ($tableLocation) disponible. Tenés $minutesToConfirm minutos para confirmar.',
        data: {
          'table_number': tableNumber,
          'table_location': tableLocation,
          'minutes_to_confirm': minutesToConfirm,
          'action_required': true,
        },
      );

      // Enviar push notification (simulado)
      await _sendPushNotification(
        phone: userPhone,
        title: '🎉 ¡Tu mesa está lista en SODITA!',
        body: 'Mesa $tableNumber disponible. Confirmá en $minutesToConfirm minutos.',
        data: {'type': MESA_DISPONIBLE, 'table_number': tableNumber.toString()},
      );

      // Opcional: Enviar WhatsApp si es crítico
      if (minutesToConfirm <= 5) {
        await _sendWhatsAppAlert(
          phone: userPhone,
          message: '''🔥 *SODITA - Mesa Disponible*

¡Hola $userName! Tu mesa está lista:

🍽️ Mesa: $tableNumber
📍 Ubicación: $tableLocation
⏰ Tiempo para confirmar: $minutesToConfirm minutos

*Confirmá ahora o perderás tu lugar en la cola.*

¡Te esperamos! 🎉''',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending table available notification: $e');
    }
  }

  /// Recordatorio de reserva (30 min antes)
  static Future<void> notifyReservationReminder({
    required String userId,
    required String userName,
    required String userPhone,
    required int tableNumber,
    required String reservationTime,
    required String confirmationCode,
  }) async {
    try {
      debugPrint('⏰ Sending reservation reminder to $userName');
      
      await _createNotification(
        userId: userId,
        type: RECORDATORIO_RESERVA,
        title: '⏰ Recordatorio de Reserva',
        message: 'Tu reserva en SODITA es en 30 minutos (Mesa $tableNumber a las $reservationTime)',
        data: {
          'table_number': tableNumber,
          'reservation_time': reservationTime,
          'confirmation_code': confirmationCode,
        },
      );

      await _sendPushNotification(
        phone: userPhone,
        title: '⏰ Tu reserva en SODITA es en 30 min',
        body: 'Mesa $tableNumber a las $reservationTime. ¡No llegues tarde!',
        data: {'type': RECORDATORIO_RESERVA, 'table_number': tableNumber.toString()},
      );
    } catch (e) {
      debugPrint('❌ Error sending reservation reminder: $e');
    }
  }

  /// Alerta de tiempo agotándose (5 min antes del no-show)
  static Future<void> notifyTimeRunningOut({
    required String userId,
    required String userName,
    required String userPhone,
    required int tableNumber,
    required int minutesLeft,
  }) async {
    try {
      debugPrint('🚨 Sending time running out alert to $userName');
      
      await _createNotification(
        userId: userId,
        type: TIEMPO_AGOTANDOSE,
        title: '🚨 ¡Tiempo agotándose!',
        message: 'Tu mesa $tableNumber se libera en $minutesLeft minutos. ¡Llegá ya!',
        data: {
          'table_number': tableNumber,
          'minutes_left': minutesLeft,
          'urgent': true,
        },
      );

      await _sendPushNotification(
        phone: userPhone,
        title: '🚨 ¡URGENTE! - Mesa $tableNumber',
        body: 'Se libera en $minutesLeft min. ¡Llegá YA o perdés la reserva!',
        data: {'type': TIEMPO_AGOTANDOSE, 'urgent': 'true'},
      );

      // WhatsApp urgente
      await _sendWhatsAppAlert(
        phone: userPhone,
        message: '''🚨 *SODITA - URGENTE*

¡$userName! Tu mesa se libera en $minutesLeft MINUTOS.

🍽️ Mesa: $tableNumber
⏰ Tiempo restante: $minutesLeft minutos

*¡Llegá YA o perdés tu reserva!*

La mesa se libera automáticamente a los 15 minutos.''',
      );
    } catch (e) {
      debugPrint('❌ Error sending time running out notification: $e');
    }
  }

  /// Solicitar review después de comer
  static Future<void> requestReview({
    required String userId,
    required String userName,
    required String userPhone,
    required String reservationId,
    required int tableNumber,
  }) async {
    try {
      debugPrint('⭐ Requesting review from $userName');
      
      await _createNotification(
        userId: userId,
        type: REVIEW_REQUEST,
        title: '⭐ ¿Cómo estuvo tu experiencia?',
        message: 'Contanos cómo estuvo tu visita a SODITA. Tu opinión nos ayuda a mejorar.',
        data: {
          'reservation_id': reservationId,
          'table_number': tableNumber,
          'action_required': false,
        },
      );

      await _sendPushNotification(
        phone: userPhone,
        title: '⭐ ¿Cómo estuvo SODITA?',
        body: 'Tu opinión nos ayuda a mejorar. ¡Dejanos tu review!',
        data: {'type': REVIEW_REQUEST, 'reservation_id': reservationId},
      );
    } catch (e) {
      debugPrint('❌ Error requesting review: $e');
    }
  }

  /// Notificar mesa liberada (para admin)
  static Future<void> notifyTableReleased({
    required int tableNumber,
    required String reason, // 'no_show', 'completed', 'manual'
    required String customerName,
  }) async {
    try {
      debugPrint('🔓 Table $tableNumber released: $reason');
      
      // Notificación para admin/staff
      await _createNotification(
        userId: 'admin',
        type: MESA_LIBERADA,
        title: '🔓 Mesa Liberada',
        message: 'Mesa $tableNumber liberada ($reason): $customerName',
        data: {
          'table_number': tableNumber,
          'reason': reason,
          'customer_name': customerName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ Error notifying table released: $e');
    }
  }

  // MÉTODOS PRIVADOS DE UTILIDAD

  /// Crear notificación en base de datos
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client
          .from('sodita_notificaciones')
          .insert({
            'usuario_id': userId,
            'tipo': type,
            'titulo': title,
            'mensaje': message,
            'data': data,
            'leida': false,
            'fecha': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('❌ Error creating notification in DB: $e');
    }
  }

  /// Simular envío de push notification
  static Future<void> _sendPushNotification({
    required String phone,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // En implementación real, usar Firebase Cloud Messaging
      debugPrint('📱 PUSH NOTIFICATION:');
      debugPrint('   To: $phone');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   Data: $data');
      
      // Simular vibración del dispositivo
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
    }
  }

  /// Enviar alerta por WhatsApp (casos urgentes)
  static Future<void> _sendWhatsAppAlert({
    required String phone,
    required String message,
  }) async {
    try {
      // En implementación real, usar WhatsApp Business API
      debugPrint('📞 WHATSAPP ALERT:');
      debugPrint('   To: $phone');
      debugPrint('   Message: $message');
      
    } catch (e) {
      debugPrint('❌ Error sending WhatsApp alert: $e');
    }
  }

  // GESTIÓN DE NOTIFICACIONES

  /// Obtener notificaciones del usuario
  static Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool onlyUnread = false,
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from('sodita_notificaciones')
          .select('*')
          .eq('usuario_id', userId);

      if (onlyUnread) {
        query = query.eq('leida', false);
      }

      final notifications = await query
          .order('fecha', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(notifications);
    } catch (e) {
      debugPrint('❌ Error getting user notifications: $e');
      return [];
    }
  }

  /// Marcar notificación como leída
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from('sodita_notificaciones')
          .update({'leida': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Marcar todas las notificaciones como leídas
  static Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from('sodita_notificaciones')
          .update({'leida': true})
          .eq('usuario_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Obtener count de notificaciones no leídas
  static Future<int> getUnreadCount(String userId) async {
    try {
      final result = await _client
          .from('sodita_notificaciones')
          .select('count')
          .eq('usuario_id', userId)
          .eq('leida', false);

      return result[0]['count'] ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // PROGRAMACIÓN AUTOMÁTICA DE NOTIFICACIONES

  /// Programar recordatorio de reserva
  static Future<void> scheduleReservationReminder({
    required String userId,
    required String userName,
    required String userPhone,
    required DateTime reservationDateTime,
    required int tableNumber,
    required String confirmationCode,
  }) async {
    try {
      final reminderTime = reservationDateTime.subtract(const Duration(minutes: 30));
      
      // En implementación real, programar con trabajo en background
      debugPrint('📅 Scheduled reminder for ${reminderTime.toIso8601String()}');
      
      // Simular programación (en real usarías cron jobs o Firebase Functions)
      await _client
          .from('sodita_tareas_programadas')
          .insert({
            'tipo': 'recordatorio_reserva',
            'usuario_id': userId,
            'fecha_ejecucion': reminderTime.toIso8601String(),
            'data': {
              'user_name': userName,
              'user_phone': userPhone,
              'table_number': tableNumber,
              'reservation_time': '${reservationDateTime.hour.toString().padLeft(2, '0')}:${reservationDateTime.minute.toString().padLeft(2, '0')}',
              'confirmation_code': confirmationCode,
            },
            'estado': 'programada',
          });
          
    } catch (e) {
      debugPrint('❌ Error scheduling reservation reminder: $e');
    }
  }

  /// Programar alerta de tiempo agotándose
  static Future<void> scheduleTimeRunningOutAlert({
    required String userId,
    required String userName,
    required String userPhone,
    required DateTime reservationDateTime,
    required int tableNumber,
  }) async {
    try {
      final alertTime = reservationDateTime.add(const Duration(minutes: 10)); // 10 min después de la hora = 5 min antes del no-show
      
      debugPrint('🚨 Scheduled time running out alert for ${alertTime.toIso8601String()}');
      
      await _client
          .from('sodita_tareas_programadas')
          .insert({
            'tipo': 'alerta_tiempo_agotandose',
            'usuario_id': userId,
            'fecha_ejecucion': alertTime.toIso8601String(),
            'data': {
              'user_name': userName,
              'user_phone': userPhone,
              'table_number': tableNumber,
              'minutes_left': 5,
            },
            'estado': 'programada',
          });
          
    } catch (e) {
      debugPrint('❌ Error scheduling time running out alert: $e');
    }
  }

  /// Programar solicitud de review
  static Future<void> scheduleReviewRequest({
    required String userId,
    required String userName,
    required String userPhone,
    required String reservationId,
    required int tableNumber,
    required DateTime completedTime,
  }) async {
    try {
      final reviewRequestTime = completedTime.add(const Duration(hours: 2)); // 2 horas después de completar
      
      debugPrint('⭐ Scheduled review request for ${reviewRequestTime.toIso8601String()}');
      
      await _client
          .from('sodita_tareas_programadas')
          .insert({
            'tipo': 'solicitar_review',
            'usuario_id': userId,
            'fecha_ejecucion': reviewRequestTime.toIso8601String(),
            'data': {
              'user_name': userName,
              'user_phone': userPhone,
              'reservation_id': reservationId,
              'table_number': tableNumber,
            },
            'estado': 'programada',
          });
          
    } catch (e) {
      debugPrint('❌ Error scheduling review request: $e');
    }
  }

  // ESTADÍSTICAS DE NOTIFICACIONES

  /// Obtener estadísticas de notificaciones
  static Future<Map<String, dynamic>> getNotificationStats({
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final notifications = await _client
          .from('sodita_notificaciones')
          .select('tipo, leida, fecha')
          .gte('fecha', startDate.toIso8601String());

      final total = notifications.length;
      final read = notifications.where((n) => n['leida'] == true).length;
      final unread = total - read;
      
      final byType = <String, int>{};
      for (final notification in notifications) {
        final type = notification['tipo'] ?? 'unknown';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'total_enviadas': total,
        'leidas': read,
        'no_leidas': unread,
        'tasa_lectura': total > 0 ? (read / total * 100).round() : 0,
        'por_tipo': byType,
        'periodo_dias': days,
      };
    } catch (e) {
      debugPrint('❌ Error getting notification stats: $e');
      return {};
    }
  }
}