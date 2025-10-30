import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/rating_service.dart';
import '../services/optimized_rating_service.dart';

class ReviewProvider extends ChangeNotifier {
  
  // Cache with TTL
  Map<String, CachedData<List<Review>>> _reviewsCache = {};
  Map<String, CachedData<Map<String, dynamic>>> _statisticsCache = {};
  
  // Loading states
  bool _isLoading = false;
  String? _error;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Cache TTL (5 minutes)
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  // Get reviews with caching
  Future<List<Review>> getReviews({bool forceRefresh = false}) async {
    const cacheKey = 'all_reviews';
    
    // Check cache first
    if (!forceRefresh && _reviewsCache.containsKey(cacheKey)) {
      final cached = _reviewsCache[cacheKey]!;
      if (!cached.isExpired) {
        return cached.data;
      }
    }
    
    try {
      _setLoading(true);
      final reviewsData = await OptimizedRatingService.getRecentReviews();
      
      // Convert to Review objects
      final reviews = reviewsData.map((data) => Review(
        rating: data['rating'] ?? 0,
        comentario: data['comentario'] ?? '',
        usuarioId: '',
        reservaId: data['reserva_id'] ?? '',
        fecha: DateTime.tryParse(data['fecha'] ?? '') ?? DateTime.now(),
        usuarioNombre: data['usuario_nombre'] ?? data['sodita_usuarios']?['nombre'],
      )).toList();
      
      // Update cache
      _reviewsCache[cacheKey] = CachedData(reviews, DateTime.now().add(_cacheTTL));
      
      _setLoading(false);
      return reviews;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }
  
  // Get statistics with caching (optimized)
  Future<Map<String, dynamic>> getStatistics({int days = 30, bool forceRefresh = false}) async {
    final cacheKey = 'stats_$days';
    
    // Check cache first
    if (!forceRefresh && _statisticsCache.containsKey(cacheKey)) {
      final cached = _statisticsCache[cacheKey]!;
      if (!cached.isExpired) {
        return cached.data;
      }
    }
    
    try {
      _setLoading(true);
      final stats = await OptimizedRatingService.getRatingStatistics(days: days);
      
      // Update cache
      _statisticsCache[cacheKey] = CachedData(stats, DateTime.now().add(_cacheTTL));
      
      _setLoading(false);
      return stats;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }
  
  // Add review with optimistic update
  Future<void> addReview(Review review) async {
    try {
      _setLoading(true);
      
      // Optimistic update - add to cache immediately
      const cacheKey = 'all_reviews';
      if (_reviewsCache.containsKey(cacheKey)) {
        final cached = _reviewsCache[cacheKey]!;
        final updatedReviews = [review, ...cached.data];
        _reviewsCache[cacheKey] = CachedData(updatedReviews, cached.expiresAt);
        notifyListeners();
      }
      
      // Make API call
      await ReviewService.createReview(
        userId: review.usuarioId,
        reservationId: review.reservaId,
        rating: review.rating,
        comment: review.comentario,
      );
      
      // Invalidate cache to ensure fresh data on next fetch
      _invalidateCache();
      
      _setLoading(false);
    } catch (e) {
      // Revert optimistic update on error
      _invalidateCache();
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }
  
  // Stream for real-time updates (optimized)
  Stream<List<Review>> get reviewsStream {
    return OptimizedRatingService.getReviewsStream()
        .map((reviewsData) => reviewsData.map((data) => Review(
          rating: data['rating'] ?? 0,
          comentario: data['comentario'] ?? '',
          usuarioId: data['usuario_id'] ?? '',
          reservaId: data['reserva_id'] ?? '',
          fecha: DateTime.tryParse(data['fecha'] ?? '') ?? DateTime.now(),
          usuarioNombre: data['usuario_nombre'] ?? data['sodita_usuarios']?['nombre'],
        )).toList())
        .handleError((error) {
      _setError(error.toString());
    });
  }
  
  // Clear cache manually
  void clearCache() {
    _reviewsCache.clear();
    _statisticsCache.clear();
    notifyListeners();
  }
  
  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void _invalidateCache() {
    _reviewsCache.clear();
    _statisticsCache.clear();
  }
}

// Cache data model
class CachedData<T> {
  final T data;
  final DateTime expiresAt;
  
  CachedData(this.data, this.expiresAt);
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}