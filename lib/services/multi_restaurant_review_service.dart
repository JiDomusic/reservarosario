import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class MultiRestaurantReviewService {
  static final _client = supabase;

  // Obtener datos de reviews públicas para un restaurante específico
  static Future<Map<String, dynamic>> getPublicReviewsData(String restaurantId) async {
    try {
      debugPrint('📊 Fetching reviews for restaurant $restaurantId...');
      
      // Obtener estadísticas de reviews verificadas
      final statsResponse = await _client
          .from('restaurant_reviews')
          .select('rating')
          .eq('restaurant_id', restaurantId)
          .eq('is_public', true);

      // Obtener reviews recientes con nombres de clientes
      final reviewsResponse = await _client
          .from('restaurant_reviews')
          .select('rating, comment, created_at, customer_name')
          .eq('restaurant_id', restaurantId)
          .eq('is_public', true)
          .not('comment', 'is', null)
          .neq('comment', '')
          .order('created_at', ascending: false)
          .limit(5);

      debugPrint('✅ Found ${statsResponse.length} total reviews and ${reviewsResponse.length} recent reviews');

      // Calcular estadísticas
      final statistics = _calculateStatistics(statsResponse);
      
      // Formatear reviews recientes
      final recentReviews = reviewsResponse.map((review) => {
        'rating': review['rating'] ?? 5,
        'comment': review['comment'] ?? '',
        'customer_name': review['customer_name'] ?? 'Cliente',
        'created_at': review['created_at'] ?? DateTime.now().toIso8601String(),
      }).toList();

      return {
        'statistics': statistics,
        'recentReviews': recentReviews,
      };

    } catch (e) {
      debugPrint('❌ Error fetching restaurant reviews: $e');
      // Retornar datos por defecto en caso de error
      return {
        'statistics': _getDefaultStatistics(),
        'recentReviews': [],
      };
    }
  }

  static Map<String, dynamic> _calculateStatistics(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return _getDefaultStatistics();
    }

    final ratings = reviews.map((r) => r['rating'] as int).toList();
    final totalReviews = ratings.length;
    final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

    // Contar distribución de estrellas
    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = ratings.where((r) => r == i).length;
    }

    // Calcular porcentajes
    final ratingPercentages = <int, double>{};
    for (int i = 1; i <= 5; i++) {
      ratingPercentages[i] = totalReviews > 0 
          ? (ratingDistribution[i]! / totalReviews) * 100 
          : 0.0;
    }

    return {
      'totalReviews': totalReviews,
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'ratingDistribution': ratingDistribution,
      'ratingPercentages': ratingPercentages,
      'starCounts': ratingDistribution,
    };
  }

  static Map<String, dynamic> _getDefaultStatistics() {
    return {
      'totalReviews': 0,
      'averageRating': 0.0,
      'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      'ratingPercentages': {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0},
      'starCounts': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    };
  }

  // Crear una nueva review para un restaurante
  static Future<bool> createReview({
    required String restaurantId,
    required String reservationId,
    required String customerName,
    required int rating,
    String? comment,
  }) async {
    try {
      debugPrint('📝 Creating review for restaurant $restaurantId...');

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

      debugPrint('✅ Review created successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating review: $e');
      return false;
    }
  }

  // Obtener reviews públicas de un restaurante (formato simple)
  static Future<List<Map<String, dynamic>>> getRestaurantReviews(String restaurantId) async {
    try {
      final response = await _client
          .from('restaurant_reviews')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching restaurant reviews: $e');
      return [];
    }
  }

  // Obtener promedio de calificaciones de un restaurante
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
      debugPrint('❌ Error calculating average rating: $e');
      return {'average': 0.0, 'count': 0};
    }
  }

  // Verificar si un cliente puede dejar una review (debe tener una reserva completada)
  static Future<bool> canCreateReview({
    required String restaurantId,
    required String customerPhone,
  }) async {
    try {
      final response = await _client
          .from('restaurant_reservations')
          .select('id')
          .eq('restaurant_id', restaurantId)
          .eq('customer_phone', customerPhone)
          .eq('status', 'completed')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking review eligibility: $e');
      return false;
    }
  }
}