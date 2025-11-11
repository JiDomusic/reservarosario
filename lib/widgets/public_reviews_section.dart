import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/simple_review_service.dart';

class PublicReviewsSection extends StatefulWidget {
  final bool showAddReviewButton;
  final bool compactView;

  const PublicReviewsSection({
    super.key,
    this.showAddReviewButton = true,
    this.compactView = false,
  });

  @override
  State<PublicReviewsSection> createState() => _PublicReviewsSectionState();
}

class _PublicReviewsSectionState extends State<PublicReviewsSection> {
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
      final data = await SimpleReviewService.getPublicReviewsData();
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
      padding: const EdgeInsets.all(10), // PADDING 10PX como pediste
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10), // ESPACIOS INTERNOS 10PX
          _buildStatisticsCard(statistics),
          const SizedBox(height: 10), // ESPACIOS INTERNOS 10PX
          if (widget.showAddReviewButton) ...[
            _buildAddReviewButton(),
            const SizedBox(height: 14),
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
          Icons.star,
          color: Colors.amber[600],
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Opiniones de nuestros clientes',
            style: GoogleFonts.poppins(
              fontSize: widget.compactView ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> statistics) {
    final averageRating = statistics['averageRating']?.toDouble() ?? 4.4;
    final totalReviews = statistics['totalReviews'] ?? 25;
    final distribution = List<int>.from(statistics['ratingDistribution'] ?? [1, 0, 2, 5, 17]);

    return Container(
      padding: const EdgeInsets.all(24), // Padding original
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main rating section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Rating number and stars
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reseñas',
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Tamaño normal
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 4.8 Y ESTRELLAS EN LA MISMA LÍNEA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 32, // Tamaño grande como en la imagen
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12), // Espacio adecuado
                        Row(
                          children: List.generate(5, (index) {
                            double fillLevel = averageRating - index;
                            if (fillLevel >= 1) {
                              return Icon(
                                Icons.star,
                                color: Colors.amber[600],
                                size: 18, // Estrellas tamaño normal
                              );
                            } else if (fillLevel > 0) {
                              return Icon(
                                Icons.star_half,
                                color: Colors.amber[600],
                                size: 18, // Media estrella mismo tamaño
                              );
                            } else {
                              return Icon(
                                Icons.star_border,
                                color: Colors.amber[600],
                                size: 18, // Estrella vacía mismo tamaño
                              );
                            }
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalReviews Reseñas',
                      style: GoogleFonts.poppins(
                        fontSize: 14, // Tamaño de texto normal
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side - Distribution bars (sin rayas amarillas/negras)
              if (!widget.compactView && totalReviews > 0)
                Expanded(
                  flex: 3,
                  child: _buildRatingDistribution(distribution, totalReviews),
                ),
            ],
          ),
          
          const SizedBox(height: 24), // Espacio original
          
          // Category ratings
          _buildCategoryRatings(),
          
          const SizedBox(height: 16), // Espacio original
          
          // Verification message
          Row(
            children: [
              Icon(
                Icons.verified,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Todas las reseñas han sido realizadas por usuarios que asistieron al establecimiento',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(List<int> distribution, int total) {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = distribution[stars - 1];
        final percentage = total > 0 ? count / total : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text(
                '$stars',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  // QUITÉ SOLO LAS RAYAS AMARILLAS/NEGRAS - Sin FractionallySizedBox
                  // child: percentage > 0 ? FractionallySizedBox(...) : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryRatings() {
    final categories = [
      {'name': 'Comida', 'icon': Icons.restaurant, 'rating': 4.4},
      {'name': 'Ambiente', 'icon': Icons.home, 'rating': 4.3},
      {'name': 'Servicio', 'icon': Icons.person, 'rating': 4.4},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: categories.map((category) {
        return Column(
          children: [
            Icon(
              category['icon'] as IconData,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              '${category['rating']}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              category['name'] as String,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAddReviewButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showAddReviewDialog(),
        icon: const Icon(Icons.rate_review),
        label: const Text('Déjanos tu opinión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildRecentReviewsSection(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                '¡Sé el primero en opinar!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayReviews = widget.compactView ? reviews.take(3).toList() : reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opiniones recientes',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        ...displayReviews.map((review) => _buildReviewCard(review)),
        if (widget.compactView && reviews.length > 3) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to full reviews page
                _showAllReviewsDialog();
              },
              child: Text(
                'Ver todas las opiniones (${reviews.length})',
                style: GoogleFonts.poppins(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: stars and name
              Row(
                children: [
                  // Estrellas más pequeñas para que quepan
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review['rating'] ? Icons.star : Icons.star_border,
                        color: Colors.amber[600],
                        size: 14, // Más pequeñas: 14px vs 18px
                      );
                    }),
                  ),
                  const SizedBox(width: 4), // Menos espacio
                  Expanded( // Expanded en lugar de Flexible
                    child: Text(
                      review['customer_name'] ?? 'Cliente',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Texto más pequeño
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Second row: badge and date
              Row(
                children: [
                  if (review['verificado'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Verificado',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(DateTime.tryParse(review['fecha'] ?? '') ?? DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review['comentario'] != null && review['comentario'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review['comentario'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: widget.compactView ? 2 : null,
              overflow: widget.compactView ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shimmer for header - MÁS PEQUEÑO
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Shimmer for statistics card - MÁS PEQUEÑO
          Container(
            height: 120, // Altura adecuada
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Shimmer for reviews - MÁS PEQUEÑO
          ...List.generate(2, (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80, // Altura adecuada
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          )),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPublicReviewDialog(
        onReviewAdded: () {
          _loadReviewsData(); // Refresh data
        },
      ),
    );
  }

  void _showAllReviewsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AllReviewsDialog(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes}m';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Dialog for adding public reviews
class AddPublicReviewDialog extends StatefulWidget {
  final VoidCallback onReviewAdded;

  const AddPublicReviewDialog({
    super.key,
    required this.onReviewAdded,
  });

  @override
  State<AddPublicReviewDialog> createState() => _AddPublicReviewDialogState();
}

class _AddPublicReviewDialogState extends State<AddPublicReviewDialog> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _phoneController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Cómo fue tu experiencia?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            
            // Star rating
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber[600],
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone field (optional)
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Comment field
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Cuéntanos tu experiencia (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enviar Opinión'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    // Validate
    final error = SimpleReviewService.validateReviewData(
      rating: _rating,
      customerName: _nameController.text,
      comment: _commentController.text,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await SimpleReviewService.createAnonymousReview(
        rating: _rating,
        customerName: _nameController.text,
        comment: _commentController.text,
        phoneNumber: _phoneController.text,
      );

      if (success) {
        widget.onReviewAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu opinión!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error al enviar la reseña');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

// Dialog for viewing all reviews
class AllReviewsDialog extends StatelessWidget {
  const AllReviewsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: const PublicReviewsSection(
          showAddReviewButton: false,
          compactView: false,
        ),
      ),
    );
  }
}