import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/animated_card.dart';
import '../services/user_service.dart';
import '../supabase_config.dart';

// PANTALLA DE CALIFICACIÓN POST-VISITA ESTILO WOKI
class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> reservationData;
  final String userId;

  const ReviewScreen({
    super.key,
    required this.reservationData,
    required this.userId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _currentRating = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Iniciar animaciones
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_currentRating == 0) {
      _showSnackBar('Por favor selecciona una calificación', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = supabase;
      
      // Insertar review en la base de datos
      await client.from('sodita_reviews').insert({
        'usuario_id': widget.userId,
        'reserva_id': widget.reservationData['id'],
        'rating': _currentRating,
        'comentario': _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        'verificado': true, // Siempre true porque viene de reserva completada
        'fecha': DateTime.now().toIso8601String(),
      });

      // Actualizar reputación del usuario (bonificación por reviewar)
      await UserService.updateUserReputation(
        userId: widget.userId,
        reservationResult: 'reviewed', // Bonificación por dejar review
      );

      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });

      _showSnackBar('¡Gracias por tu calificación!', isError: false);
      
      // Cerrar pantalla después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true); // true indica que se completó el review
        }
      });

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar('Error al enviar calificación: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError 
            ? const Color(0xFFEF4444) 
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Califica tu experiencia',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        leading: !_isSubmitted ? IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        automaticallyImplyLeading: !_isSubmitted,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isSubmitted ? _buildSuccessView() : _buildReviewForm(),
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información de la reserva
            _buildReservationInfo(),
            
            const SizedBox(height: 32),
            
            // Calificación con estrellas
            AnimatedCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '¿Cómo fue tu experiencia en SODITA?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    StarRatingWidget(
                      starSize: 40,
                      onRatingChanged: (rating) {
                        setState(() {
                          _currentRating = rating;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Campo de comentario opcional
            AnimatedCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuéntanos más (opcional)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Comparte tu experiencia, qué te gustó más, sugerencias...',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botón de enviar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Texto informativo
            Text(
              'Tu calificación nos ayuda a mejorar y es verificada porque visitaste el restaurante.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationInfo() {
    final mesa = widget.reservationData['mesa_numero'] ?? 'N/A';
    final fecha = widget.reservationData['fecha'] ?? '';
    final hora = widget.reservationData['hora'] ?? '';
    final personas = widget.reservationData['personas'] ?? 0;

    return AnimatedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF4F46E5),
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SODITA Rosario',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Mesa $mesa • $personas personas',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  
                  Text(
                    '$fecha • $hora',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              '¡Gracias por tu calificación!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Tu opinión nos ayuda a mejorar la experiencia para todos nuestros clientes.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            if (_currentRating > 0)
              DisplayStarRating(
                rating: _currentRating.toDouble(),
                starSize: 32,
                showRatingNumber: false,
              ),
          ],
        ),
      ),
    );
  }
}