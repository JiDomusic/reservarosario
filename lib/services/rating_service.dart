import '../supabase_config.dart';

class RatingService {
  static final _client = supabase;

  // Crear una nueva valoración
  static Future<bool> createRating({
    required String reservationId,
    required String customerName,
    required int stars,
    String? comment,
    int? mesaNumero,
  }) async {
    try {
      await _client.from('reviews').insert({
        'reservation_id': reservationId,
        'customer_name': customerName,
        'stars': stars,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Rating created successfully');
      return true;
    } catch (e) {
      print('❌ Error creating rating: $e');
      return false;
    }
  }

  // Obtener todas las valoraciones
  static Future<List<Map<String, dynamic>>> getAllRatings() async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      return [];
    }
  }

  // Obtener valoraciones por rango de fechas
  static Future<List<Map<String, dynamic>>> getRatingsByDateRange(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final response = await _client
          .from('reviews')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching ratings by date range: $e');
      return [];
    }
  }

  // Obtener estadísticas de valoraciones
  static Future<Map<String, dynamic>> getRatingStatistics(int days) async {
    try {
      final ratings = await getRatingsByDateRange(days);
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'rating_distribution': {},
        };
      }

      final totalRatings = ratings.length;
      final sumRatings = ratings.fold<int>(0, (sum, rating) => sum + (rating['stars'] as int));
      final averageRating = sumRatings / totalRatings;

      // Distribución por estrellas
      final ratingDistribution = <String, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i.toString()] = 0;
      }

      for (var rating in ratings) {
        final stars = rating['stars'].toString();
        ratingDistribution[stars] = (ratingDistribution[stars] ?? 0) + 1;
      }

      return {
        'average_rating': averageRating,
        'total_ratings': totalRatings,
        'rating_distribution': ratingDistribution,
        'ratings_by_star': {
          '5': ratingDistribution['5'] ?? 0,
          '4': ratingDistribution['4'] ?? 0,
          '3': ratingDistribution['3'] ?? 0,
          '2': ratingDistribution['2'] ?? 0,
          '1': ratingDistribution['1'] ?? 0,
        }
      };
    } catch (e) {
      print('❌ Error calculating rating statistics: $e');
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
        'rating_distribution': {},
      };
    }
  }

  // Verificar si una reserva ya tiene valoración
  static Future<bool> hasRating(String reservationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('id')
          .eq('reservation_id', reservationId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if reservation has rating: $e');
      return false;
    }
  }

  // Obtener valoración de una reserva específica
  static Future<Map<String, dynamic>?> getRatingByReservation(String reservationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .eq('reservation_id', reservationId)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching rating by reservation: $e');
      return null;
    }
  }

  // Obtener valoraciones recientes (últimas 10)
  static Future<List<Map<String, dynamic>>> getRecentRatings() async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching recent ratings: $e');
      return [];
    }
  }

  // Obtener promedio de valoraciones por mes
  static Future<List<Map<String, dynamic>>> getMonthlyRatingAverages() async {
    try {
      final response = await _client.rpc('get_monthly_rating_averages');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching monthly rating averages: $e');
      return [];
    }
  }

  // Obtener valoraciones por mesa
  static Future<Map<int, List<Map<String, dynamic>>>> getRatingsByTable() async {
    try {
      final ratings = await getAllRatings();
      final Map<int, List<Map<String, dynamic>>> ratingsByTable = {};

      for (var rating in ratings) {
        final mesaNumero = rating['mesa_numero'] as int?;
        if (mesaNumero != null) {
          if (ratingsByTable[mesaNumero] == null) {
            ratingsByTable[mesaNumero] = [];
          }
          ratingsByTable[mesaNumero]!.add(rating);
        }
      }

      return ratingsByTable;
    } catch (e) {
      print('❌ Error fetching ratings by table: $e');
      return {};
    }
  }

  // Obtener promedio de valoraciones por mesa
  static Future<Map<int, double>> getAverageRatingsByTable() async {
    try {
      final ratingsByTable = await getRatingsByTable();
      final Map<int, double> averagesByTable = {};

      ratingsByTable.forEach((mesaNumero, ratings) {
        if (ratings.isNotEmpty) {
          final sum = ratings.fold<int>(0, (sum, rating) => sum + (rating['stars'] as int));
          averagesByTable[mesaNumero] = sum / ratings.length;
        }
      });

      return averagesByTable;
    } catch (e) {
      print('❌ Error calculating average ratings by table: $e');
      return {};
    }
  }
}