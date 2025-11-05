import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/multi_restaurant_review_service.dart';

class MultiRestaurantReviewsSection extends StatefulWidget {
  final String restaurantId;
  final bool showAddReviewButton;
  final bool compactView;

  const MultiRestaurantReviewsSection({
    super.key,
    required this.restaurantId,
    this.showAddReviewButton = true,
    this.compactView = false,
  });

  @override
  State<MultiRestaurantReviewsSection> createState() => _MultiRestaurantReviewsSectionState();
}

class _MultiRestaurantReviewsSectionState extends State<MultiRestaurantReviewsSection> {
  Map<String, dynamic>? _reviewsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviewsData();
  }

  Future<void> _loadReviewsData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await MultiRestaurantReviewService.getPublicReviewsData(widget.restaurantId);
      setState(() {
        _reviewsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    final statistics = _reviewsData?['statistics'] ?? {};
    final recentReviews = _reviewsData?['recentReviews'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatisticsCard(statistics),
          const SizedBox(height: 16),
          if (widget.showAddReviewButton) ...[
            _buildAddReviewButton(),
            const SizedBox(height: 16),
          ],
          _buildRecentReviewsSection(recentReviews),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.star_rate_rounded,
          color: Colors.amber[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Calificaciones y Reseñas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1B1F),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> statistics) {
    final totalReviews = statistics['totalReviews'] ?? 0;
    final averageRating = statistics['averageRating'] ?? 0.0;
    final ratingPercentages = statistics['ratingPercentages'] ?? {};

    if (widget.compactView) {
      return _buildCompactStats(totalReviews, averageRating);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Calificación promedio
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1C1B1F),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/ 5',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating.floor()
                              ? Icons.star_rate_rounded
                              : index < averageRating
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                          color: Colors.amber[600],
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews ${totalReviews == 1 ? 'reseña' : 'reseñas'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Distribución de estrellas
              Expanded(
                flex: 3,
                child: _buildRatingDistribution(ratingPercentages, totalReviews),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(int totalReviews, double averageRating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.floor()
                    ? Icons.star_rate_rounded
                    : index < averageRating
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                color: Colors.amber[600],
                size: 16,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '($totalReviews)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(Map<String, dynamic> percentages, int totalReviews) {
    if (totalReviews == 0) {
      return const Center(
        child: Text(
          'Sin reseñas aún',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(5, (index) {
        final starNumber = 5 - index;
        final percentage = percentages[starNumber] ?? 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$starNumber',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star_rate_rounded,
                color: Colors.amber[600],
                size: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${percentage.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAddReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddReviewDialog(),
        icon: const Icon(Icons.rate_review_rounded, size: 18),
        label: Text(
          'Escribir una reseña',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF86704),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildRecentReviewsSection(List<dynamic> reviews) {
    if (reviews.isEmpty || widget.compactView) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reseñas Recientes',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 12),
        ...reviews.take(3).map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 5;
    final comment = review['comment'] ?? '';
    final customerName = review['customer_name'] ?? 'Cliente';
    final createdAt = DateTime.tryParse(review['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rate_rounded : Icons.star_outline_rounded,
                    color: Colors.amber[600],
                    size: 16,
                  );
                }),
              ),
              const Spacer(),
              Text(
                _formatDate(createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '- $customerName',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showAddReviewDialog() {
    // Implementar dialog para agregar reseñas
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escribir Reseña'),
        content: const Text('Función de reseñas próximamente disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else {
      return 'Hace un momento';
    }
  }
}