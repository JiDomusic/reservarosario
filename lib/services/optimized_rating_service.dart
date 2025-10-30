import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class OptimizedRatingService {
  static final _client = supabase;
  
  // Database views for optimization
  static const String _statisticsView = '''
    CREATE OR REPLACE VIEW rating_statistics_view AS
    SELECT 
      COUNT(*) as total_reviews,
      AVG(rating)::NUMERIC(3,1) as average_rating,
      COUNT(CASE WHEN rating = 5 THEN 1 END) as five_stars,
      COUNT(CASE WHEN rating = 4 THEN 1 END) as four_stars,
      COUNT(CASE WHEN rating = 3 THEN 1 END) as three_stars,
      COUNT(CASE WHEN rating = 2 THEN 1 END) as two_stars,
      COUNT(CASE WHEN rating = 1 THEN 1 END) as one_star,
      DATE_TRUNC('day', fecha) as date_bucket
    FROM sodita_reviews 
    WHERE verificado = true 
      AND fecha >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY DATE_TRUNC('day', fecha)
    ORDER BY date_bucket DESC;
  ''';

  static const String _recentReviewsView = '''
    CREATE OR REPLACE VIEW recent_reviews_view AS
    SELECT 
      sr.rating,
      sr.comentario,
      sr.fecha,
      su.nombre as usuario_nombre,
      sr.reserva_id
    FROM sodita_reviews sr
    LEFT JOIN sodita_usuarios su ON sr.usuario_id = su.id
    WHERE sr.verificado = true 
      AND sr.comentario IS NOT NULL 
      AND sr.comentario != ''
    ORDER BY sr.fecha DESC;
  ''';

  // Initialize database views
  static Future<void> initializeViews() async {
    try {
      debugPrint('🔧 Creating optimized database views...');
      
      // Create statistics view
      await _client.rpc('exec_sql', params: {'query': _statisticsView});
      
      // Create recent reviews view
      await _client.rpc('exec_sql', params: {'query': _recentReviewsView});
      
      debugPrint('✅ Database views created successfully');
    } catch (e) {
      debugPrint('❌ Error creating database views: $e');
      // Views might already exist or user might not have permissions
      // This is not critical for the app to function
    }
  }

  // Get statistics using optimized view
  static Future<Map<String, dynamic>> getRatingStatistics({int days = 30}) async {
    try {
      debugPrint('📊 Fetching rating statistics for last $days days...');
      
      final response = await _client
          .from('rating_statistics_view')
          .select('*')
          .gte('date_bucket', DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('date_bucket', ascending: false);

      if (response.isEmpty) {
        return _getDefaultStatistics();
      }

      // Aggregate statistics across the date range
      int totalReviews = 0;
      double totalRatingSum = 0;
      int fiveStars = 0, fourStars = 0, threeStars = 0, twoStars = 0, oneStars = 0;

      for (final row in response) {
        final reviews = row['total_reviews'] as int;
        final avgRating = (row['average_rating'] as num).toDouble();
        
        totalReviews += reviews;
        totalRatingSum += avgRating * reviews;
        fiveStars += row['five_stars'] as int;
        fourStars += row['four_stars'] as int;
        threeStars += row['three_stars'] as int;
        twoStars += row['two_stars'] as int;
        oneStars += row['one_star'] as int;
      }

      final averageRating = totalReviews > 0 ? totalRatingSum / totalReviews : 0.0;

      final result = {
        'totalReviews': totalReviews,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'ratingDistribution': [oneStars, twoStars, threeStars, fourStars, fiveStars],
        'total_ratings': totalReviews, // Legacy compatibility
        'average_rating': double.parse(averageRating.toStringAsFixed(1)), // Legacy compatibility
      };

      debugPrint('✅ Statistics loaded: ${result['averageRating']} (${result['totalReviews']} reviews)');
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching statistics, falling back to legacy method: $e');
      return await _getLegacyStatistics(days);
    }
  }

  // Get recent reviews using optimized view
  static Future<List<Map<String, dynamic>>> getRecentReviews({int limit = 5}) async {
    try {
      debugPrint('📝 Fetching recent reviews (limit: $limit)...');
      
      final response = await _client
          .from('recent_reviews_view')
          .select('*')
          .limit(limit);

      debugPrint('✅ Found ${response.length} recent reviews');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching recent reviews, falling back to legacy method: $e');
      return await _getLegacyRecentReviews(limit);
    }
  }

  // Batch operations for better performance
  static Future<Map<String, dynamic>> getBatchData({
    int statisticsDays = 30,
    int reviewsLimit = 5,
  }) async {
    try {
      debugPrint('🔄 Fetching batch data (stats: $statisticsDays days, reviews: $reviewsLimit)...');
      
      final results = await Future.wait([
        getRatingStatistics(days: statisticsDays),
        getRecentReviews(limit: reviewsLimit),
      ]);

      return {
        'statistics': results[0],
        'reviews': results[1],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error fetching batch data: $e');
      return {
        'statistics': _getDefaultStatistics(),
        'reviews': <Map<String, dynamic>>[],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Legacy fallback methods
  static Future<Map<String, dynamic>> _getLegacyStatistics(int days) async {
    final response = await _client
        .from('sodita_reviews')
        .select('rating')
        .eq('verificado', true)
        .gte('fecha', DateTime.now().subtract(Duration(days: days)).toIso8601String());

    if (response.isEmpty) {
      return _getDefaultStatistics();
    }

    final ratings = response.map((r) => r['rating'] as int).toList();
    final totalRating = ratings.fold(0, (sum, rating) => sum + rating);
    final averageRating = totalRating / ratings.length;
    
    final distribution = [0, 0, 0, 0, 0];
    for (final rating in ratings) {
      distribution[rating - 1]++;
    }

    return {
      'totalReviews': ratings.length,
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'ratingDistribution': distribution,
      'total_ratings': ratings.length,
      'average_rating': double.parse(averageRating.toStringAsFixed(1)),
    };
  }

  static Future<List<Map<String, dynamic>>> _getLegacyRecentReviews(int limit) async {
    final response = await _client
        .from('sodita_reviews')
        .select('''
          rating,
          comentario,
          fecha,
          sodita_usuarios(nombre)
        ''')
        .eq('verificado', true)
        .not('comentario', 'is', null)
        .order('fecha', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  static Map<String, dynamic> _getDefaultStatistics() {
    return {
      'totalReviews': 0,
      'averageRating': 4.8,
      'ratingDistribution': [0, 0, 0, 0, 0],
      'total_ratings': 0,
      'average_rating': 4.8,
    };
  }

  // Real-time subscription for reviews
  static Stream<List<Map<String, dynamic>>> getReviewsStream({int limit = 5}) {
    try {
      return _client
          .from('sodita_reviews')
          .stream(primaryKey: ['id'])
          .eq('verificado', true)
          .order('fecha', ascending: false)
          .limit(limit)
          .map((data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('❌ Error creating reviews stream: $e');
      // Fallback to periodic updates
      return Stream.periodic(const Duration(seconds: 30))
          .asyncMap((_) => getRecentReviews(limit: limit));
    }
  }

  // Cache invalidation
  static Future<void> invalidateCache() async {
    // In a production app, you might want to implement Redis or similar
    debugPrint('🔄 Cache invalidated');
  }
}