import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

class SimpleReviewService {
  static final _client = supabase;

  // Get public reviews data using ONLY existing verified reviews
  static Future<Map<String, dynamic>> getPublicReviewsData() async {
    try {
      debugPrint('📊 Fetching verified reviews data...');
      
      // Get statistics from existing verified reviews
      final statsResponse = await _client
          .from('sodita_reviews')
          .select('rating')
          .eq('verificado', true);

      // Get recent reviews with user names (only verified)
      final reviewsResponse = await _client
          .from('sodita_reviews')
          .select('''
            rating,
            comentario,
            fecha,
            verificado,
            sodita_usuarios(nombre)
          ''')
          .eq('verificado', true)
          .not('comentario', 'is', null)
          .neq('comentario', '')
          .order('fecha', ascending: false)
          .limit(6);

      // Calculate statistics
      final ratings = List<Map<String, dynamic>>.from(statsResponse);
      final ratingValues = ratings.map((r) => r['rating'] as int).toList();
      
      double averageRating = 4.8; // Default fallback
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
          'customer_name': review['sodita_usuarios']?['nombre'] ?? 'Cliente Verificado',
          'verificado': true, // All existing reviews are verified
        };
      }).toList();

      debugPrint('✅ Verified reviews loaded: ${averageRating.toStringAsFixed(1)} ($totalReviews reviews)');

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
      debugPrint('❌ Error fetching verified reviews: $e');
      return _getDefaultData();
    }
  }

  // Editar comentario desde admin - sincronización automática
  static Future<bool> editReview({
    required String reviewId,
    String? newComment,
    int? newRating,
  }) async {
    try {
      debugPrint('✏️ Editando review desde admin: $reviewId');
      
      Map<String, dynamic> updates = {};
      if (newComment != null) updates['comentario'] = newComment;
      if (newRating != null) updates['rating'] = newRating;
      
      final response = await _client
          .from('sodita_reviews')
          .update(updates)
          .eq('id', reviewId);
      
      debugPrint('✅ Review editado exitosamente - carrusel se actualizará automáticamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error editando review: $e');
      return false;
    }
  }

  // Eliminar comentario desde admin - sincronización automática
  static Future<bool> deleteReview(String reviewId) async {
    try {
      debugPrint('🗑️ Eliminando review desde admin: $reviewId');
      
      final response = await _client
          .from('sodita_reviews')
          .delete()
          .eq('id', reviewId);
      
      debugPrint('✅ Review eliminado exitosamente - carrusel se actualizará automáticamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando review: $e');
      return false;
    }
  }

  // Marcar review como verificado/no verificado desde admin
  static Future<bool> toggleVerification(String reviewId, bool verified) async {
    try {
      debugPrint('✔️ Cambiando verificación de review: $reviewId -> $verified');
      
      final response = await _client
          .from('sodita_reviews')
          .update({'verificado': verified})
          .eq('id', reviewId);
      
      debugPrint('✅ Verificación actualizada - carrusel se sincronizará automáticamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando verificación: $e');
      return false;
    }
  }

  // Create anonymous review using a simplified approach - CREATE TEMPORARY USER
  static Future<bool> createAnonymousReview({
    required int rating,
    required String customerName,
    String? comment,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('🌟 Creating anonymous review: $rating stars from $customerName');
      
      // Generate unique identifiers to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final microseconds = DateTime.now().microsecondsSinceEpoch;
      final randomSuffix = (microseconds % 999999).toString().padLeft(6, '0');
      final uniquePhone = phoneNumber?.trim() ?? 'web-anon-$timestamp-$randomSuffix';
      
      // Step 1: Create temporary anonymous user (let Supabase generate UUID)
      final userResponse = await _client.from('sodita_usuarios').insert({
        'nombre': customerName.trim(),
        'telefono': uniquePhone, // Guaranteed unique phone
        'email': null,
        'reputacion': 50, // Lower reputation for anonymous users
        'verificado': false,
        'fecha_registro': DateTime.now().toIso8601String(),
      }).select('id').single();
      
      final userId = userResponse['id'];
      
      // Step 2: Create temporary reservation record (let Supabase generate UUID)
      final reservationResponse = await _client.from('sodita_reservas').insert({
        'usuario_id': userId,
        'mesa_id': null, // Will be handled by the service
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        'hora': '00:00:00',
        'personas': 1,
        'nombre': customerName.trim(),
        'telefono': uniquePhone, // Use the same unique phone
        'estado': 'completada',
        'codigo_confirmacion': 'W${timestamp.toString().substring(7)}', // Max 10 chars: W + last 9 digits
        'creado_en': DateTime.now().toIso8601String(),
      }).select('id').single();
      
      final reservationId = reservationResponse['id'];
      
      // Step 3: Create the review
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
      debugPrint('Error details: ${e.toString()}');
      return false;
    }
  }

  // Get all reviews (verified + anonymous) for display
  static Future<List<Map<String, dynamic>>> getAllReviews({int limit = 10}) async {
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
      debugPrint('❌ Error fetching all reviews: $e');
      return [];
    }
  }

  // Stream for real-time updates
  static Stream<Map<String, dynamic>> getReviewsStream() {
    return Stream.periodic(const Duration(seconds: 45))
        .asyncMap((_) => getPublicReviewsData())
        .handleError((error) {
      debugPrint('❌ Error in reviews stream: $error');
      return _getDefaultData();
    });
  }

  static Map<String, dynamic> _getDefaultData() {
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