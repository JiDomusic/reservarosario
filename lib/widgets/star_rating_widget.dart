import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// WIDGET DE CALIFICACIÓN CON ESTRELLAS INTERACTIVO ESTILO WOKI
class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final double starSize;
  final bool allowHalfStars;
  final bool readOnly;
  final String? label;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.starSize = 32.0,
    this.allowHalfStars = false,
    this.readOnly = false,
    this.label,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with TickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onStarTapped(int rating) {
    if (widget.readOnly) return;
    
    setState(() {
      _currentRating = rating;
    });
    
    // Animación de feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Vibración suave (si está disponible)
    // HapticFeedback.lightImpact();
    
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Estrellas más anchas
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _currentRating;
                
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _onStarTapped(starNumber),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          final scale = starNumber == _currentRating && !widget.readOnly
                              ? _scaleAnimation.value
                              : 1.0;
                          
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected 
                                    ? const Color(0xFFFBBF24).withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: widget.starSize * 1.2,
                                color: isSelected 
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        
        // Texto descriptivo según la calificación
        if (_currentRating > 0 && !widget.readOnly) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingText(_currentRating),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getRatingColor(_currentRating),
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo 😞';
      case 2:
        return 'Malo 😐';
      case 3:
        return 'Regular 🙂';
      case 4:
        return 'Bueno 😊';
      case 5:
        return 'Excelente 🤩';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return const Color(0xFFEF4444); // Rojo
      case 3:
        return const Color(0xFFF59E0B); // Amarillo
      case 4:
      case 5:
        return const Color(0xFF10B981); // Verde
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }
}

// WIDGET SIMPLE PARA MOSTRAR CALIFICACIÓN (SOLO LECTURA)
class DisplayStarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final bool showRatingNumber;
  final int totalReviews;

  const DisplayStarRating({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.showRatingNumber = true,
    this.totalReviews = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Estrellas con más espaciado
          ...List.generate(5, (index) {
            final starValue = index + 1;
            final isFilled = rating >= starValue;
            final isHalfFilled = rating >= starValue - 0.5 && rating < starValue;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isFilled 
                    ? Icons.star_rounded
                    : isHalfFilled 
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                size: starSize * 1.2,
                color: isFilled || isHalfFilled
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFD1D5DB),
              ),
            );
          }),
          
          if (showRatingNumber) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: starSize * 0.8,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            
            if (totalReviews > 0) ...[
              const SizedBox(width: 8),
              Text(
                '($totalReviews)',
                style: GoogleFonts.poppins(
                  fontSize: starSize * 0.7,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}