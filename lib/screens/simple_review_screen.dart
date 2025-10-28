import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/star_rating_widget.dart';
import '../supabase_config.dart';

// PANTALLA DE CALIFICACIÓN SIMPLE Y CÓMODA
class SimpleReviewScreen extends StatefulWidget {
  final Map<String, dynamic> reservationData;
  final String userId;

  const SimpleReviewScreen({
    super.key,
    required this.reservationData,
    required this.userId,
  });

  @override
  State<SimpleReviewScreen> createState() => _SimpleReviewScreenState();
}

class _SimpleReviewScreenState extends State<SimpleReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_currentRating == 0) {
      _showMessage('Selecciona una calificación', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await supabase.from('sodita_reviews').insert({
        'usuario_id': widget.userId,
        'reserva_id': widget.reservationData['id'],
        'rating': _currentRating,
        'comentario': _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        'verificado': true,
        'fecha': DateTime.now().toIso8601String(),
      });

      _showMessage('¡Gracias por tu calificación!', isError: false);
      
      // Cerrar después de mostrar el mensaje
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop(true);
      });

    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Error al enviar', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 3 : 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Califica tu experiencia',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Logo o icono
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 40,
                  color: Color(0xFF4F46E5),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Título principal
              Text(
                'SODITA Rosario',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                '¿Cómo fue tu experiencia?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Estrellas grandes y cómodas
              StarRatingWidget(
                starSize: 50,
                onRatingChanged: (rating) {
                  setState(() => _currentRating = rating);
                },
              ),
              
              const SizedBox(height: 40),
              
              // Campo de comentario simple
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Comparte tu experiencia (opcional)',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              
              const Spacer(),
              
              // Botón de enviar grande y cómodo
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _currentRating == 0 ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentRating > 0 
                        ? const Color(0xFF4F46E5) 
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enviar calificación',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Texto discreto
              Text(
                'Tu opinión es anónima y nos ayuda a mejorar',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}