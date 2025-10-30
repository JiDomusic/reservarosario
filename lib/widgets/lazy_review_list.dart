import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../models/review_model.dart';

class LazyReviewList extends StatefulWidget {
  final int initialLimit;
  final int loadMoreCount;
  final bool showLoadMore;

  const LazyReviewList({
    super.key,
    this.initialLimit = 10,
    this.loadMoreCount = 5,
    this.showLoadMore = true,
  });

  @override
  State<LazyReviewList> createState() => _LazyReviewListState();
}

class _LazyReviewListState extends State<LazyReviewList> {
  final ScrollController _scrollController = ScrollController();
  List<Review> _allReviews = [];
  List<Review> _displayedReviews = [];
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadInitialReviews() async {
    try {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      final reviews = await reviewProvider.getReviews();
      
      setState(() {
        _allReviews = reviews;
        _displayedReviews = reviews.take(widget.initialLimit).toList();
        _hasMoreData = reviews.length > widget.initialLimit;
      });
    } catch (e) {
      debugPrint('Error loading initial reviews: $e');
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreData || !widget.showLoadMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      final currentLength = _displayedReviews.length;
      final nextBatch = _allReviews
          .skip(currentLength)
          .take(widget.loadMoreCount)
          .toList();
      
      _displayedReviews.addAll(nextBatch);
      _hasMoreData = _displayedReviews.length < _allReviews.length;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _displayedReviews.length) {
                  return _buildReviewItem(_displayedReviews[index], index);
                }
                
                // Loading indicator at the bottom
                if (_isLoadingMore && widget.showLoadMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                // Load more button
                if (_hasMoreData && widget.showLoadMore && !_isLoadingMore) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _loadMoreReviews,
                        child: const Text('Cargar más reseñas'),
                      ),
                    ),
                  );
                }
                
                // End of list
                if (!_hasMoreData && _displayedReviews.isNotEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No hay más reseñas',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
              childCount: _displayedReviews.length + 
                         (_isLoadingMore ? 1 : 0) + 
                         (_hasMoreData && widget.showLoadMore ? 1 : 0) +
                         (!_hasMoreData && _displayedReviews.isNotEmpty ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Star rating
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber[600],
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                
                // User name
                Expanded(
                  child: Text(
                    review.usuarioNombre ?? 'Usuario',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Date
                Text(
                  _formatDate(review.fecha),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            if (review.comentario.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comentario,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            
            // Table number if available
            if (review.mesaNumero != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mesa ${review.mesaNumero}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    
    try {
      final reviews = await reviewProvider.getReviews(forceRefresh: true);
      
      setState(() {
        _allReviews = reviews;
        _displayedReviews = reviews.take(widget.initialLimit).toList();
        _hasMoreData = reviews.length > widget.initialLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error refreshing reviews: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Ahora';
        }
        return 'Hace ${difference.inMinutes}m';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace ${weeks}sem';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months}mes';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}