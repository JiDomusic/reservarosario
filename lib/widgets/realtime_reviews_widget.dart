import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/realtime_ratings_service.dart';

class RealTimeReviewsWidget extends StatefulWidget {
  final bool showModerationActions;
  final Function(Map<String, dynamic>)? onEditReview;
  final Function(String)? onDeleteReview;
  final Function(String)? onHideReview;
  
  const RealTimeReviewsWidget({
    super.key,
    this.showModerationActions = false,
    this.onEditReview,
    this.onDeleteReview,
    this.onHideReview,
  });

  @override
  State<RealTimeReviewsWidget> createState() => _RealTimeReviewsWidgetState();
}

class _RealTimeReviewsWidgetState extends State<RealTimeReviewsWidget> 
    with TickerProviderStateMixin {
  
  List<Map<String, dynamic>> _reviews = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Animación para transiciones suaves
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _startListening();
  }

  void _startListening() {
    // Iniciar el servicio de tiempo real
    RealTimeRatingsService.startListening();
    
    // Escuchar actualizaciones
    _subscription = RealTimeRatingsService.ratingsStream.listen(
      (reviews) {
        if (mounted) {
          setState(() {
            _reviews = reviews;
            _isLoading = false;
          });
          _animationController.forward();
        }
      },
      onError: (error) {
        print('❌ Error en widget realtime: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando comentarios en tiempo real...'),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay comentarios aún',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return _buildReviewCard(review, index);
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, int index) {
    final isNegative = (review['stars'] as int?) != null && review['stars'] <= 2;
    final comment = (review['comentario'] ?? review['comment'] ?? '') as String;
    final customerName = review['customer_name'] ?? 
                       review['nombre_cliente'] ?? 
                       review['name'] ?? 
                       'Cliente Anónimo';
    
    final hasOffensiveContent = comment.toLowerCase().contains(
      RegExp(r'(asco|horrible|ladrón|maleducado|pésimo|odio|basura)')
    );
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: hasOffensiveContent ? 8 : 2,
        color: hasOffensiveContent ? Colors.red[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasOffensiveContent 
              ? const BorderSide(color: Colors.red, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar y info del usuario
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isNegative ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      isNegative ? Icons.sentiment_very_dissatisfied : Icons.sentiment_satisfied,
                      color: isNegative ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              Icons.star,
                              size: 16,
                              color: i < (review['stars'] ?? 0) 
                                  ? Colors.amber 
                                  : Colors.grey[300],
                            )),
                            const SizedBox(width: 8),
                            Text(
                              '${review['stars'] ?? 0}/5',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasOffensiveContent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'REVISAR',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Comentario
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasOffensiveContent ? Colors.red[100] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: hasOffensiveContent 
                        ? Border.all(color: Colors.red[300]!, width: 1)
                        : null,
                  ),
                  child: Text(
                    comment,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: hasOffensiveContent ? Colors.red[800] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
              
              // Acciones de moderación (solo si se habilitan)
              if (widget.showModerationActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => widget.onEditReview?.call(review),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => widget.onHideReview?.call(review['id']),
                      icon: const Icon(Icons.visibility_off, size: 16),
                      label: Text('Ocultar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => widget.onDeleteReview?.call(review['id']),
                      icon: const Icon(Icons.delete, size: 16),
                      label: Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}