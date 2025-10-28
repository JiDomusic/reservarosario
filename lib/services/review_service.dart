import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

// SERVICIO DE REVIEWS Y CALIFICACIONES ESTILO WOKI
class ReviewService {
  static final _client = supabase;

  // OBTENER CALIFICACIÓN PROMEDIO DEL RESTAURANTE
  static Future<Map<String, dynamic>> getRestaurantRating() async {
    try {
      debugPrint('📊 Fetching restaurant rating...');
      
      final response = await _client
          .from('sodita_reviews')
          .select('rating')
          .eq('verificado', true);

      if (response.isEmpty) {
        return {
          'average_rating': 4.8, // Rating inicial por defecto
          'total_reviews': 0,
          'rating_distribution': [0, 0, 0, 0, 0], // [1star, 2star, 3star, 4star, 5star]
        };
      }

      final reviews = List<Map<String, dynamic>>.from(response);
      final ratings = reviews.map((r) => r['rating'] as int).toList();
      
      // Calcular promedio
      final totalRating = ratings.fold(0, (sum, rating) => sum + rating);
      final averageRating = totalRating / ratings.length;
      
      // Distribución por estrellas
      final distribution = [0, 0, 0, 0, 0];
      for (final rating in ratings) {
        distribution[rating - 1]++;
      }

      debugPrint('✅ Restaurant rating: ${averageRating.toStringAsFixed(1)} (${ratings.length} reviews)');
      
      return {
        'average_rating': double.parse(averageRating.toStringAsFixed(1)),
        'total_reviews': ratings.length,
        'rating_distribution': distribution,
      };
    } catch (e) {
      debugPrint('❌ Error fetching restaurant rating: $e');
      // Fallback con datos por defecto
      return {
        'average_rating': 4.8,
        'total_reviews': 0,
        'rating_distribution': [0, 0, 0, 0, 0],
      };
    }
  }

  // VERIFICAR SI USUARIO PUEDE DEJAR REVIEW
  static Future<bool> canUserReview({
    required String userId,
    required String reservationId,
  }) async {
    try {
      // Verificar si ya reviewó esta reserva
      final existingReview = await _client
          .from('sodita_reviews')
          .select('id')
          .eq('usuario_id', userId)
          .eq('reserva_id', reservationId)
          .maybeSingle();

      return existingReview == null;
    } catch (e) {
      debugPrint('❌ Error checking review eligibility: $e');
      return false;
    }
  }

  // OBTENER REVIEWS RECIENTES PARA MOSTRAR
  static Future<List<Map<String, dynamic>>> getRecentReviews({int limit = 5}) async {
    try {
      debugPrint('📝 Fetching recent reviews...');
      
      final response = await _client
          .from('sodita_reviews')
          .select('''
            rating,
            comentario,
            fecha,
            sodita_usuarios(nombre)
          ''')
          .eq('verificado', true)
          .not('comentario', 'is', null) // Solo reviews con comentario
          .order('fecha', ascending: false)
          .limit(limit);

      final reviews = List<Map<String, dynamic>>.from(response);
      
      debugPrint('✅ Found ${reviews.length} recent reviews');
      return reviews;
    } catch (e) {
      debugPrint('❌ Error fetching recent reviews: $e');
      return [];
    }
  }

  // CREAR REVIEW
  static Future<bool> createReview({
    required String userId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    try {
      debugPrint('🌟 Creating review: Rating $rating for reservation $reservationId');
      
      await _client.from('sodita_reviews').insert({
        'usuario_id': userId,
        'reserva_id': reservationId,
        'rating': rating,
        'comentario': comment?.trim().isEmpty == true ? null : comment?.trim(),
        'verificado': true,
        'fecha': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Review created successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating review: $e');
      return false;
    }
  }

  // OBTENER REVIEWS DEL USUARIO
  static Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    try {
      final response = await _client
          .from('sodita_reviews')
          .select('''
            rating,
            comentario,
            fecha,
            sodita_reservas(fecha, hora, mesa_numero)
          ''')
          .eq('usuario_id', userId)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching user reviews: $e');
      return [];
    }
  }

  // OBTENER ESTADÍSTICAS DE CALIFICACIÓN
  static Future<Map<String, int>> getRatingStats() async {
    try {
      final response = await _client
          .from('sodita_reviews')
          .select('rating')
          .eq('verificado', true);

      final ratings = List<Map<String, dynamic>>.from(response);
      final stats = <String, int>{
        'total': ratings.length,
        '5_stars': 0,
        '4_stars': 0,
        '3_stars': 0,
        '2_stars': 0,
        '1_star': 0,
      };

      for (final review in ratings) {
        final rating = review['rating'] as int;
        switch (rating) {
          case 5:
            stats['5_stars'] = stats['5_stars']! + 1;
            break;
          case 4:
            stats['4_stars'] = stats['4_stars']! + 1;
            break;
          case 3:
            stats['3_stars'] = stats['3_stars']! + 1;
            break;
          case 2:
            stats['2_stars'] = stats['2_stars']! + 1;
            break;
          case 1:
            stats['1_star'] = stats['1_star']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Error fetching rating stats: $e');
      return {
        'total': 0,
        '5_stars': 0,
        '4_stars': 0,
        '3_stars': 0,
        '2_stars': 0,
        '1_star': 0,
      };
    }
  }

  // NOTIFICAR PARA SOLICITAR REVIEW (automático)
  static Future<void> scheduleReviewRequest({
    required String userId,
    required String reservationId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      debugPrint('📅 Scheduling review request for user $userName');
      
      // Programar solicitud de review 1 hora después
      final reviewRequestTime = DateTime.now().add(const Duration(hours: 1));
      
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
            },
          });

      debugPrint('✅ Review request scheduled for ${reviewRequestTime.toIso8601String()}');
    } catch (e) {
      debugPrint('❌ Error scheduling review request: $e');
    }
  }
}