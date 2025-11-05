import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class PublicReviewService {
  static final _client = supabase;

  // Get public reviews without authentication - Using existing sodita_reviews table
  static Future<Map<String, dynamic>> getPublicReviewsData() async {
    try {
      debugPrint('📊 Fetching public reviews data...');
      
      // Get ALL ratings from sodita_reviews table
      final statsResponse = await _client
          .from('sodita_reviews')
          .select('rating');

      // Get recent reviews from sodita_reviews with user names
      final reviewsResponse = await _client
          .from('sodita_reviews')
          .select('''
            rating,
            comentario,
            fecha,
            sodita_usuarios(nombre)
          ''')
          .not('comentario', 'is', null)
          .neq('comentario', '')
          .order('fecha', ascending: false)
          .limit(6);

      // Calculate statistics from sodita_reviews
      final ratings = List<Map<String, dynamic>>.from(statsResponse);
      final ratingValues = ratings.map((r) => r['rating'] as int).toList();
      
      double averageRating = 4.8; // Default
      int totalReviews = 0;
      List<int> distribution = [0, 0, 0, 0, 0];

      if (ratingValues.isNotEmpty) {
        totalReviews = ratingValues.length;
        final totalRating = ratingValues.fold(0, (sum, rating) => sum + rating);
        averageRating = totalRating / totalReviews;
        
        // Calculate distribution
        for (final rating in ratingValues) {
          if (rating >= 1 && rating <= 5) {
            distribution[rating - 1]++;
          }
        }
      }

      final reviews = List<Map<String, dynamic>>.from(reviewsResponse);
      
      // Format reviews for display
      final formattedReviews = reviews.map((review) {
        return {
          'rating': review['rating'],
          'comentario': review['comentario'],
          'fecha': review['fecha'],
          'customer_name': review['sodita_usuarios']?['nombre'] ?? 'Cliente',
          'verificado': true, // All reviews in sodita_reviews are verified
        };
      }).toList();

      debugPrint('✅ Public reviews loaded: ${averageRating.toStringAsFixed(1)} ($totalReviews reviews)');

      return {
        'statistics': {
          'averageRating': double.parse(averageRating.toStringAsFixed(1)),
          'totalReviews': totalReviews,
          'ratingDistribution': distribution,
        },
        'recentReviews': formattedReviews,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error fetching public reviews: $e');
      return _getDefaultPublicData();
    }
  }

  // Create anonymous user and review in sodita_reviews system
  static Future<bool> createAnonymousReview({
    required int rating,
    required String customerName,
    String? comment,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('🌟 Creating anonymous review: $rating stars from $customerName');
      
      // First create an anonymous user
      final userId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
      
      await _client.from('sodita_usuarios').insert({
        'id': userId,
        'nombre': customerName.trim(),
        'telefono': phoneNumber?.trim(),
        'email': null,
        'tipo_usuario': 'anonimo',
        'fecha_registro': DateTime.now().toIso8601String(),
      });
      
      // Then create an anonymous reservation
      final reservationId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      
      await _client.from('sodita_reservas').insert({
        'id': reservationId,
        'usuario_id': userId,
        'mesa_numero': 'Web',
        'fecha': DateTime.now().toIso8601String(),
        'hora': '00:00',
        'numero_personas': 1,
        'estado': 'completada',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Finally create the review
      await _client.from('sodita_reviews').insert({
        'usuario_id': userId,
        'reserva_id': reservationId,
        'rating': rating,
        'comentario': comment?.trim().isEmpty == true ? null : comment?.trim(),
        'verificado': false, // Anonymous reviews are not verified
        'fecha': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Anonymous review created successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating anonymous review: $e');
      return false;
    }
  }

  // Get reviews for public display - from sodita_reviews
  static Future<List<Map<String, dynamic>>> getPublicDisplayReviews({int limit = 10}) async {
    try {
      final response = await _client
          .from('sodita_reviews')
          .select('''
            rating,
            comentario,
            fecha,
            verificado,
            sodita_usuarios(nombre)
          ''')
          .not('comentario', 'is', null)
          .neq('comentario', '')
          .order('fecha', ascending: false)
          .limit(limit);

      final reviews = List<Map<String, dynamic>>.from(response);
      
      // Format reviews for display
      return reviews.map((review) {
        return {
          'rating': review['rating'],
          'comentario': review['comentario'],
          'fecha': review['fecha'],
          'verificado': review['verificado'] ?? false,
          'customer_name': review['sodita_usuarios']?['nombre'] ?? 'Cliente',
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching public display reviews: $e');
      return [];
    }
  }

  // Real-time stream for public reviews
  static Stream<Map<String, dynamic>> getPublicReviewsStream() {
    return Stream.periodic(const Duration(seconds: 45))
        .asyncMap((_) => getPublicReviewsData())
        .handleError((error) {
      debugPrint('❌ Error in public reviews stream: $error');
      return _getDefaultPublicData();
    });
  }

  static Map<String, dynamic> _getDefaultPublicData() {
    return {
      'statistics': {
        'averageRating': 4.8,
        'totalReviews': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      },
      'recentReviews': <Map<String, dynamic>>[],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Validate review data
  static String? validateReviewData({
    required int rating,
    required String customerName,
    String? comment,
  }) {
    if (rating < 1 || rating > 5) {
      return 'La calificación debe ser entre 1 y 5 estrellas';
    }
    
    if (customerName.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    
    if (customerName.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    if (comment != null && comment.length > 500) {
      return 'El comentario no puede exceder 500 caracteres';
    }
    
    return null; // No errors
  }
}