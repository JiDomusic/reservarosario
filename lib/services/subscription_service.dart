import '../supabase_config.dart';

class SubscriptionService {
  static final _client = supabase;

  // Verificar estado de suscripción de un restaurante
  static Future<Map<String, dynamic>?> getSubscriptionStatus(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurants')
          .select('subscription_status, monthly_fee, next_payment_date, is_active')
          .eq('id', restaurantId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error getting subscription status: $e');
      return null;
    }
  }

  // Obtener todos los restaurantes con sus estados de suscripción
  static Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      final response = await _client.rpc('get_all_subscriptions');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting all subscriptions: $e');
      return [];
    }
  }

  // Activar un restaurante (cuando se confirma el pago)
  static Future<bool> activateRestaurant(String restaurantId) async {
    try {
      final response = await _client.rpc('activate_restaurant', params: {
        'restaurant_uuid': restaurantId,
      });

      print('✅ Restaurant activated: $response');
      return true;
    } catch (e) {
      print('❌ Error activating restaurant: $e');
      return false;
    }
  }

  // Suspender un restaurante (por falta de pago)
  static Future<bool> suspendRestaurant(String restaurantId) async {
    try {
      final response = await _client.rpc('suspend_restaurant', params: {
        'restaurant_uuid': restaurantId,
      });

      print('✅ Restaurant suspended: $response');
      return true;
    } catch (e) {
      print('❌ Error suspending restaurant: $e');
      return false;
    }
  }

  // Verificar si un restaurante puede recibir reservas
  static Future<bool> canReceiveReservations(String restaurantId) async {
    try {
      final status = await getSubscriptionStatus(restaurantId);
      if (status == null) return false;

      return status['is_active'] == true && 
             status['subscription_status'] == 'active';
    } catch (e) {
      print('❌ Error checking reservation permissions: $e');
      return false;
    }
  }

  // Obtener historial de pagos de un restaurante
  static Future<List<Map<String, dynamic>>> getPaymentHistory(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_payment_history')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting payment history: $e');
      return [];
    }
  }

  // Registrar un nuevo pago
  static Future<bool> recordPayment({
    required String restaurantId,
    required double amount,
    required String transactionReference,
    String status = 'confirmed',
    String? notes,
  }) async {
    try {
      await _client.from('restaurant_payment_history').insert({
        'restaurant_id': restaurantId,
        'amount': amount,
        'status': status,
        'transaction_reference': transactionReference,
        'notes': notes,
      });

      // Si el pago está confirmado, extender la fecha de próximo pago
      if (status == 'confirmed') {
        await _client
            .from('restaurants')
            .update({
              'next_payment_date': DateTime.now()
                  .add(const Duration(days: 30))
                  .toIso8601String()
                  .split('T')[0],
            })
            .eq('id', restaurantId);
      }

      return true;
    } catch (e) {
      print('❌ Error recording payment: $e');
      return false;
    }
  }

  // Verificar restaurantes con pagos vencidos
  static Future<List<Map<String, dynamic>>> getOverduePayments() async {
    try {
      final response = await _client.rpc('check_overdue_payments');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting overdue payments: $e');
      return [];
    }
  }

  // Obtener información de suscripción para mostrar en el formulario
  static Map<String, dynamic> getSubscriptionInfo() {
    return {
      'monthly_fee': 50000.00,
      'currency': 'ARS',
      'payment_method': 'bank_transfer',
      'cbu': 'TU_CBU_AQUI',
      'holder_name': 'jido_only',
      'cuit': '27-29623120-2',
      'whatsapp': '+54 341 3363551',
      'description': 'Suscripción mensual al sistema de reservas Gastronómica Rosario',
      'features': [
        'Sistema de reservas online 24/7',
        'Tolerancia automática de 15 minutos',
        'Panel administrativo completo',
        'Sistema de calificaciones y reseñas',
        'Liberación automática de mesas',
        'Estadísticas y analytics',
        'Soporte técnico incluido',
      ],
    };
  }

  // Formatear estado de suscripción para mostrar
  static String formatSubscriptionStatus(String status) {
    switch (status) {
      case 'active':
        return 'Activa';
      case 'pending_payment':
        return 'Pendiente de Pago';
      case 'suspended':
        return 'Suspendida';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  // Calcular días hasta próximo pago
  static int getDaysUntilNextPayment(String nextPaymentDate) {
    try {
      final paymentDate = DateTime.parse(nextPaymentDate);
      final now = DateTime.now();
      return paymentDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }
}