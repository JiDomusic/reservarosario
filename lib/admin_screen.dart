import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:reservarosario/supabase_config.dart';
import 'services/reservation_service.dart';
import 'services/rating_service.dart';
import 'widgets/reservation_countdown.dart';
import 'widgets/rating_widget.dart';
import 'screens/analytics_screen.dart';
import 'l10n.dart';
import 'dart:async';
import 'dart:math' as math;

// Widget de reloj animado personalizado
class AnimatedClock extends StatefulWidget {
  final Duration? timeRemaining;
  final String status;
  final double size;
  final bool showNumbers;

  const AnimatedClock({
    super.key,
    required this.timeRemaining,
    required this.status,
    this.size = 48.0,
    this.showNumbers = false,
  });

  @override
  State<AnimatedClock> createState() => _AnimatedClockState();
}

class _AnimatedClockState extends State<AnimatedClock>
    with TickerProviderStateMixin {
  late AnimationController _secondHandController;
  late AnimationController _minuteHandController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para la manecilla de segundos (1 segundo por rotación)
    _secondHandController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    // Controlador para la manecilla de minutos (1 minuto por rotación completa)
    _minuteHandController = AnimationController(
      duration: const Duration(minutes: 1),
      vsync: this,
    )..repeat();
    
    // Controlador para el efecto de pulso en estados críticos
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _updatePulseAnimation();
  }

  void _updatePulseAnimation() {
    if (widget.status == 'critical' || widget.status == 'expired') {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void didUpdateWidget(AnimatedClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updatePulseAnimation();
    }
  }

  @override
  void dispose() {
    _secondHandController.dispose();
    _minuteHandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getClockColor() {
    switch (widget.status) {
      case 'normal':
        return const Color(0xFF2E7D32); // Verde más oscuro y visible
      case 'late':
        return const Color(0xFFEF6C00); // Naranja más oscuro y visible
      case 'critical':
        return const Color(0xFFD32F2F); // Rojo más oscuro y visible
      case 'expired':
        return const Color(0xFF212121); // Negro más visible
      default:
        return const Color(0xFF424242);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black12,
              border: Border.all(
                color: _getClockColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getClockColor().withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: ClockPainter(
                secondHandAnimation: _secondHandController,
                minuteHandAnimation: _minuteHandController,
                timeRemaining: widget.timeRemaining,
                clockColor: _getClockColor(),
                showNumbers: widget.showNumbers,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReviewModerationPanel() {
    print('🔍 ABRIENDO PANEL DE MODERACIÓN...');
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: _ReviewModerationPanel(),
      ),
    );
  }
}

class _ReviewModerationPanel extends StatefulWidget {
  @override
  _ReviewModerationPanelState createState() => _ReviewModerationPanelState();
}

class _ReviewModerationPanelState extends State<_ReviewModerationPanel> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  int currentPage = 0;
  final int pageSize = 20;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      print('🔍 CARGANDO RESEÑAS PARA MODERACIÓN...');
      setState(() => isLoading = true);
      final newReviews = await RatingService.getRatingsForModerationPaginated(
        limit: pageSize,
        offset: currentPage * pageSize,
      );
      
      print('📋 RESEÑAS ENCONTRADAS: ${newReviews.length}');
      if (newReviews.isNotEmpty) {
        print('📝 PRIMERA RESEÑA: ${newReviews.first}');
      }
      
      setState(() {
        if (currentPage == 0) {
          reviews = newReviews;
        } else {
          reviews.addAll(newReviews);
        }
        hasMore = newReviews.length == pageSize;
        isLoading = false;
      });
      
      print('✅ MODERACIÓN CARGADA: ${reviews.length} reseñas total');
    } catch (e) {
      print('❌ ERROR EN MODERACIÓN: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando reseñas: $e')),
      );
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reseña'),
        content: const Text('¿Estás seguro de que deseas eliminar esta reseña? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RatingService.deleteRating(reviewId);
      if (success) {
        setState(() {
          reviews.removeWhere((review) => review['id'] == reviewId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña eliminada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la reseña'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    final commentController = TextEditingController(text: review['comment'] ?? '');
    int selectedStars = review['stars'] ?? 5;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Reseña'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cliente: ${review['customer_name']}'),
                const SizedBox(height: 16),
                const Text('Calificación:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedStars = index + 1;
                        });
                      },
                      icon: Icon(
                        index < selectedStars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comentario',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await RatingService.updateRating(
                  ratingId: review['id'],
                  comment: commentController.text,
                  stars: selectedStars,
                );
                
                Navigator.pop(context);
                
                if (success) {
                  setState(() {
                    final index = reviews.indexWhere((r) => r['id'] == review['id']);
                    if (index != -1) {
                      reviews[index]['comment'] = commentController.text;
                      reviews[index]['stars'] = selectedStars;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reseña actualizada exitosamente')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al actualizar la reseña'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Moderar Comentarios',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              currentPage = 0;
              _loadReviews();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: isLoading && currentPage == 0
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total de reseñas: ${reviews.length}${hasMore ? '+' : ''}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay reseñas para moderar',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (!isLoading && 
                                hasMore && 
                                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                              currentPage++;
                              _loadReviews();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: reviews.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == reviews.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final review = reviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final DateTime createdAt = DateTime.parse(review['created_at']);
    final String formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customer_name'] ?? 'Cliente anónimo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (review['stars'] ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  review['comment'],
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editReview(review),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteReview(review['id']),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Painter personalizado para dibujar el reloj
class ClockPainter extends CustomPainter {
  final AnimationController secondHandAnimation;
  final AnimationController minuteHandAnimation;
  final Duration? timeRemaining;
  final Color clockColor;
  final bool showNumbers;

  ClockPainter({
    required this.secondHandAnimation,
    required this.minuteHandAnimation,
    required this.timeRemaining,
    required this.clockColor,
    required this.showNumbers,
  }) : super(
          repaint: Listenable.merge([
            secondHandAnimation,
            minuteHandAnimation,
          ]),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Dibujar marcas de horas
    _drawHourMarks(canvas, center, radius);
    
    // Dibujar números si está habilitado
    if (showNumbers) {
      _drawNumbers(canvas, center, radius);
    }
    
    // Dibujar manecillas
    _drawHands(canvas, center, radius);
    
    // Dibujar centro
    _drawCenter(canvas, center);
    
    // Dibujar indicador de tiempo restante
    if (timeRemaining != null) {
      _drawTimeRemainingArc(canvas, center, radius);
    }
  }

  void _drawHourMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = clockColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMainHour = i % 3 == 0;
      final markLength = isMainHour ? 6.0 : 3.0;
      final markWidth = isMainHour ? 2.0 : 1.0;
      
      paint.strokeWidth = markWidth;
      
      final startX = center.dx + (radius - markLength) * math.cos(angle);
      final startY = center.dy + (radius - markLength) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x = center.dx + (radius - 15) * math.cos(angle);
      final y = center.dy + (radius - 15) * math.sin(angle);

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: clockColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawHands(Canvas canvas, Offset center, double radius) {
    final now = DateTime.now();
    
    // Manecilla de minutos (basada en tiempo real)
    final minuteAngle = (now.minute * 6 - 90) * math.pi / 180;
    _drawHand(
      canvas,
      center,
      minuteAngle,
      radius * 0.7,
      2.5,
      clockColor,
    );
    
    // Manecilla de segundos (animada)
    final secondAngle = (secondHandAnimation.value * 360 - 90) * math.pi / 180;
    _drawHand(
      canvas,
      center,
      secondAngle,
      radius * 0.8,
      1.0,
      clockColor.withValues(alpha: 0.8),
    );
    
    // Manecilla de horas (basada en tiempo real)
    final hourAngle = ((now.hour % 12) * 30 + now.minute * 0.5 - 90) * math.pi / 180;
    _drawHand(
      canvas,
      center,
      hourAngle,
      radius * 0.5,
      3.0,
      clockColor,
    );
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length, double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final endX = center.dx + length * math.cos(angle);
    final endY = center.dy + length * math.sin(angle);

    canvas.drawLine(center, Offset(endX, endY), paint);
  }

  void _drawCenter(Canvas canvas, Offset center) {
    final paint = Paint()..color = clockColor;
    canvas.drawCircle(center, 3, paint);
  }

  void _drawTimeRemainingArc(Canvas canvas, Offset center, double radius) {
    if (timeRemaining == null) return;
    
    final totalSeconds = 15 * 60; // 15 minutos en segundos
    final remainingSeconds = timeRemaining!.inSeconds;
    final progress = remainingSeconds / totalSeconds;
    
    if (progress <= 0) return;
    
    final paint = Paint()
      ..color = clockColor.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius + 6);
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      rect,
      -math.pi / 2, // Empezar desde arriba
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return oldDelegate.timeRemaining != timeRemaining ||
           oldDelegate.clockColor != clockColor;
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

// 🔐 PANTALLA DE LOGIN SÚPER SEGURA
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // 📧 CREDENCIALES TEMPORALES (cambiar en Supabase después)
  static const String ADMIN_EMAIL = 'admin@sodita.com';
  static const String ADMIN_PASSWORD = 'sodita2025!';

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simular autenticación (reemplazar con Supabase Auth)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (email == ADMIN_EMAIL && password == ADMIN_PASSWORD) {
        // 💰 VERIFICAR SUSCRIPCIÓN DESPUÉS DEL LOGIN
        final hasValidSubscription = await _checkSubscription();
        
        if (mounted) {
          if (hasValidSubscription) {
            // Acceso completo al admin
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreen()),
            );
          } else {
            // Mostrar pantalla de suscripción
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            );
          }
        }
      } else {
        _showError('Credenciales incorrectas');
      }
    } catch (e) {
      _showError('Error de conexión');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Logo y título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SODITA Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Panel de Control del Restaurante',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Formulario de login
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email de Administrador',
                        hintText: 'admin@sodita.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _login(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de login
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Ingresar al Panel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info de credenciales temporales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Credenciales Temporales',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: admin@sodita.com\nContraseña: sodita2025!',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💰 VERIFICAR SUSCRIPCIÓN
  Future<bool> _checkSubscription() async {
    try {
      // Simular verificación de suscripción (reemplazar con lógica real)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Para SODITA (sistema de prueba) devolver false para mostrar pantalla de pago
      return false; // Cambiar a true después del pago
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> reservations = []; // Lista filtrada para mostrar
  List<Map<String, dynamic>> allReservations = []; // Todas las reservas sin filtrar
  Map<String, dynamic> stats = {};
  Map<DateTime, List<Map<String, dynamic>>> calendarEvents = {};
  bool isLoading = true;
  Timer? _autoCheckTimer;
  Timer? _countdownTimer;
  
  // Variables para filtros y vista
  int selectedPeriod = 7; // 7, 15, 30 días
  bool showCalendarView = false;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  
  // Controladores de animación
  late AnimationController _statsAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
  // Sistema de notificaciones automáticas y liberación de reservas
  Timer? _notificationTimer;
  Timer? _autoReleaseTimer;
  final Set<String> _notifiedReservations = {}; // Para evitar duplicados
  final List<OverlayEntry> _activeAlerts = []; // Alertas flotantes activas

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _loadCalendarData(); // 🗓️ CARGAR DATOS INICIALES DEL CALENDARIO
    _startAutoCheck();
    _startAutoReleaseSystem();
    
    // Iniciar animaciones
    _statsAnimationController.forward();
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationTimer?.cancel();
    _autoReleaseTimer?.cancel();
    
    // Limpiar alertas flotantes
    for (var alert in _activeAlerts) {
      alert.remove();
    }
    _activeAlerts.clear();
    
    _statsAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  // NO MÁS AUTO-REFRESH - Solo refresh manual
  void _startAutoCheck() {
    // COMPLETAMENTE DESACTIVADO - Solo refresh manual con botón
    print('✅ Auto-refresh DESACTIVADO - Solo refresh manual');
  }

  // SOLO liberación de mesas - SIN refresh de UI
  void _startAutoReleaseSystem() {
    print('🔄 Iniciando SOLO sistema de liberación de mesas...');
    // Timer EXCLUSIVO para liberar mesas expiradas (NO refresh de UI)
    _autoReleaseTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _processExpiredReservations(); // Solo procesa expiraciones, no actualiza UI
      }
    });
  }

  // Procesar reservas expiradas y mostrar alertas
  // FUNCIÓN ELIMINADA: _loadDataWithAnimation no se usa
  
  // Verificar si hay cambios reales en las reservas
  bool _hasReservationChanges(List<Map<String, dynamic>> newReservations) {
    if (reservations.length != newReservations.length) return true;
    
    for (int i = 0; i < reservations.length; i++) {
      if (reservations[i]['id'] != newReservations[i]['id'] ||
          reservations[i]['estado'] != newReservations[i]['estado']) {
        return true;
      }
    }
    return false;
  }

  // Detectar cambios INTELIGENTES - sin rebuilds innecesarios
  bool _hasActualChanges(
    List<Map<String, dynamic>> newAllReservations,
    List<Map<String, dynamic>> newActiveReservations,
    Map<String, dynamic> newStats
  ) {
    // Verificar cambios en reservas
    if (_hasReservationChanges(newActiveReservations)) return true;
    
    // Verificar cambios en estadísticas importantes
    if (stats['total'] != newStats['total']) return true;
    if (stats['confirmadas'] != newStats['confirmadas']) return true;
    if (stats['en_mesa'] != newStats['en_mesa']) return true;
    if (stats['completadas'] != newStats['completadas']) return true;
    
    // No hay cambios significativos
    return false;
  }

  Future<void> _processExpiredReservations() async {
    try {
      final wasRestaurantFull = await ReservationService.isRestaurantFull();
      final releasedTables = await ReservationService.processExpiredReservations();
      
      for (var reservation in releasedTables) {
        // Mostrar alerta de reserva expirada
        _showReservationExpiredAlert(reservation);
        
        // Si el restaurante estaba lleno, mostrar alerta de mesa liberada
        if (wasRestaurantFull) {
          _showTableReleasedAlert(reservation);
        }
      }
      
      // SOLO actualizar si se liberaron reservas (no refresh constante)
      if (releasedTables.isNotEmpty) {
        print('✅ ${releasedTables.length} mesa(s) liberada(s) automáticamente');
        // Actualización mínima sin loops
        if (mounted) {
          _loadData();
        }
      }
    } catch (e) {
      print('❌ Error in auto release system: $e');
    }
  }

  // Mostrar alerta flotante de reserva expirada
  void _showReservationExpiredAlert(Map<String, dynamic> reservation) {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 0,
        right: 0,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚠️ Reserva Expirada', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text('Mesa ${reservation['sodita_mesas']['numero']} - ${reservation['nombre']}'),
                ElevatedButton(
                  onPressed: () {
                    overlayEntry.remove();
                    _activeAlerts.remove(overlayEntry);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    _activeAlerts.add(overlayEntry);
    
    // Auto-remover después de 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (_activeAlerts.contains(overlayEntry)) {
        overlayEntry.remove();
        _activeAlerts.remove(overlayEntry);
      }
    });
  }

  // Mostrar alerta flotante de mesa liberada (solo cuando estaba lleno)
  void _showTableReleasedAlert(Map<String, dynamic> reservation) {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✅ Mesa Liberada', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text('Mesa ${reservation['sodita_mesas']['numero']} disponible'),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          overlayEntry.remove();
                          _activeAlerts.remove(overlayEntry);
                        },
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          overlayEntry.remove();
                          _activeAlerts.remove(overlayEntry);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💡 Funcionalidad de reserva rápida por implementar'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        child: const Text('Reservar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    _activeAlerts.add(overlayEntry);
    
    // Auto-remover después de 15 segundos
    Timer(const Duration(seconds: 15), () {
      if (_activeAlerts.contains(overlayEntry)) {
        overlayEntry.remove();
        _activeAlerts.remove(overlayEntry);
      }
    });
  }

  // Loading state suave - NO ocultar datos anteriores  
  bool _isSoftLoading = false;
  
  Future<void> _loadData() async {
    // NUNCA pantalla en blanco - mantener datos anteriores
    if (!mounted) return;
    
    // Indicador sutil sin ocultar contenido
    if (mounted) {
      setState(() {
        _isSoftLoading = true;
        // NUNCA isLoading = true después de tener datos
      });
    }

    try {
      if (showCalendarView) {
        // 📅 CARGAR HISTORIAL COMPLETO PARA CALENDARIO
        print('🗓️ Cargando historial de $selectedPeriod días para calendario...');
        final calendarData = await ReservationService.getReservationsForCalendar(selectedPeriod);
        final statsData = await ReservationService.getReservationStats(selectedPeriod);
        
        print('📊 Datos calendario cargados: ${calendarData.length} días con reservas');
        print('📈 Stats calculadas: $statsData');
        
        if (mounted) {
          setState(() {
            calendarEvents = calendarData;
            stats = statsData;
            _isSoftLoading = false;
            // NUNCA cambiar isLoading = false si ya hay datos
          });
        }
      } else {
        // Cargar SOLO las reservas activas del día actual (excluyendo completadas/no_show de días anteriores)
        final today = DateTime.now();
        final todaysReservations = await ReservationService.getReservationsByDate(today);
        final activeReservations = _filterActiveReservations(todaysReservations, today);
        final todayStats = await _calculateTodayStats(activeReservations);
        
        print('🔍 Admin: Cargadas ${todaysReservations.length} reservas totales para hoy');
        print('🔍 Admin: Filtradas ${activeReservations.length} reservas activas');
        print('📋 Reservas: ${activeReservations.map((r) => '${r['nombre']} - Mesa ${r['sodita_mesas']['numero']} - ${r['estado']}').toList()}');
        print('⏰ Reservas confirmadas: ${activeReservations.where((r) => r['estado'] == 'confirmada').length}');
        print('📊 Stats calculadas: $todayStats');
        
        // ACTUALIZACIÓN INTELIGENTE - Solo si hay cambios reales
        if (mounted && _hasActualChanges(todaysReservations, activeReservations, todayStats)) {
          setState(() {
            allReservations = todaysReservations;
            reservations = activeReservations;
            stats = todayStats;
            _isSoftLoading = false;
          });
          print('✅ Datos actualizados de forma inteligente');
        } else {
          // Solo actualizar el indicador de loading sin rebuild
          if (mounted) {
            setState(() {
              _isSoftLoading = false;
            });
          }
          print('🔄 Sin cambios detectados - no rebuild innecesario');
        }
        
        // Las alertas críticas se verifican en el timer independiente
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
        _isSoftLoading = false;
      });
    }
  }

  // 🗓️ CARGAR DATOS INICIALES DEL CALENDARIO SIEMPRE
  Future<void> _loadCalendarData() async {
    try {
      print('🗓️ Cargando datos iniciales del calendario para $selectedPeriod días...');
      final calendarData = await ReservationService.getReservationsForCalendar(selectedPeriod);
      final statsData = await ReservationService.getReservationStats(selectedPeriod);
      
      print('📊 Calendario inicializado: ${calendarData.length} días con datos');
      print('📅 Datos del calendario por fecha:');
      calendarData.forEach((fecha, eventos) {
        print('   ${fecha.toIso8601String().split('T')[0]}: ${eventos.length} reservas');
        for (var evento in eventos) {
          print('      - ${evento['nombre']} a las ${evento['hora']} (${evento['estado']})');
        }
      });
      
      if (mounted) {
        setState(() {
          calendarEvents = calendarData;
          // No sobrescribir stats si ya están cargados desde vista lista
        });
      }
    } catch (e) {
      print('❌ Error cargando datos calendario: $e');
    }
  }

  // 🚀 HYPER REFRESH - Actualización ultra-rápida con animaciones
  Future<void> _hyperRefresh() async {
    try {
      // Animación de feedback inmediato
      setState(() => isLoading = true);
      
      // Cargar datos de forma paralela para máxima velocidad
      await Future.wait([
        _loadData(),
        // _autoMarkNoShows(), // DESHABILITADO - Solo manual por ahora
        _processExpiredReservations(),
      ]);
      
      // Mostrar feedback de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.white),
                const SizedBox(width: 8),
                const Text('⚡ Datos actualizados instantáneamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error en hyper refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error actualizando datos'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _autoMarkNoShows() async {
    await ReservationService.autoMarkNoShow();
    _loadData(); // Recargar después de marcar no_shows
  }
  
  /// Filtrar reservas activas para mostrar en la vista de lista del admin
  /// Solo muestra reservas relevantes para el día actual:
  /// - Confirmadas (esperando cliente)
  /// - En mesa (clientes presentes)
  /// - Completadas del día actual (para seguimiento)
  /// - No shows del día actual (para estadísticas)
  List<Map<String, dynamic>> _filterActiveReservations(List<Map<String, dynamic>> allReservations, DateTime today) {
    final todayStr = today.toIso8601String().split('T')[0];
    
    return allReservations.where((reservation) {
      final reservationDate = reservation['fecha'];
      final estado = reservation['estado'];
      
      // Si es del día actual, solo mostrar confirmadas y en_mesa (trabajo pendiente)
      // Las completadas/no_show van solo a los cards superiores
      if (reservationDate == todayStr) {
        return estado == 'confirmada' || estado == 'en_mesa';
      }
      
      // Si es de días anteriores, solo mostrar estados activos (confirmadas, en_mesa)
      // Las completadas y no_show de días anteriores se ocultan pero quedan en BD para calendario
      if (estado == 'confirmada' || estado == 'en_mesa') {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  Future<Map<String, dynamic>> _calculateTodayStats(List<Map<String, dynamic>> todayReservations) async {
    final total = todayReservations.length;
    final confirmadas = todayReservations.where((r) => r['estado'] == 'confirmada').length;
    final completadas = todayReservations.where((r) => r['estado'] == 'completada').length;
    final noShows = todayReservations.where((r) => r['estado'] == 'no_show').length;
    final canceladas = todayReservations.where((r) => r['estado'] == 'cancelada').length;
    final enMesa = todayReservations.where((r) => r['estado'] == 'en_mesa').length;
    
    // Calcular mesas de manera más precisa
    final allTables = await ReservationService.getMesas();
    final totalTables = allTables.length;
    
    // Mesas ocupadas = reservas confirmadas (esperando) + mesas en uso
    final reservedTables = confirmadas; // Mesas reservadas esperando check-in
    final activeTables = enMesa; // Mesas actualmente ocupadas
    final cancelledTables = canceladas; // Reservas canceladas hoy
    
    // Mesas libres = total - (reservadas + activas)
    final freeTables = totalTables - (reservedTables + activeTables);
    
    return {
      'total': total,
      'confirmadas': confirmadas,
      'completadas': completadas,
      'no_shows': noShows,
      'canceladas': canceladas,
      'en_mesa': enMesa,
      'total_tables': totalTables,
      'occupied_tables': activeTables, // Solo mesas con clientes actualmente
      'reserved_tables': reservedTables, // Mesas reservadas esperando
      'cancelled_tables': cancelledTables,
      'free_tables': freeTables,
      'tasa_completadas': total > 0 ? (completadas / total * 100).round() : 0,
      'tasa_no_shows': total > 0 ? (noShows / total * 100).round() : 0,
      'tasa_canceladas': total > 0 ? (canceladas / total * 100).round() : 0,
    };
  }

  // Función para cerrar día y mover reservas al historial
  Future<void> _cerrarDia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Día'),
        content: const Text('¿Estás seguro de que deseas cerrar el día? Todas las reservas actuales se moverán al historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Día'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _procesarCierreDia();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Día cerrado exitosamente. Todas las reservas movidas al historial.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // Recargar datos
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar el día: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _procesarCierreDia() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Marcar todas las reservas confirmadas como completadas (SIN updated_at)
      await supabase.from('sodita_reservas').update({
        'estado': 'completada',
      }).eq('fecha', today).eq('estado', 'confirmada');
      
      // Marcar todas las reservas en mesa como completadas (SIN updated_at)
      await supabase.from('sodita_reservas').update({
        'estado': 'completada', 
      }).eq('fecha', today).eq('estado', 'en_mesa');
      
      print('✅ Día cerrado exitosamente');
    } catch (e) {
      print('❌ Error cerrando día: $e');
      throw e;
    }
  }

  // Obtener reservas liberadas automáticamente (expiradas por el sistema)
  List<Map<String, dynamic>> _getAutoExpiredReservations(List<Map<String, dynamic>> allReservations) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    return allReservations.where((reservation) {
      final reservationDate = reservation['fecha'];
      final estado = reservation['estado'];
      
      // Solo del día actual y con estado 'expirada' (liberadas automáticamente)
      return reservationDate == todayStr && estado == 'expirada';
    }).toList();
  }

  // Obtener cancelaciones manuales hechas por la recepcionista
  List<Map<String, dynamic>> _getManualCancellations(List<Map<String, dynamic>> allReservations) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    return allReservations.where((reservation) {
      final reservationDate = reservation['fecha'];
      final estado = reservation['estado'];
      
      // Solo del día actual y con estado 'cancelada' (canceladas manualmente)
      return reservationDate == todayStr && estado == 'cancelada';
    }).toList();
  }

  // Obtener no-show marcados manualmente por la recepcionista
  List<Map<String, dynamic>> _getManualNoShows(List<Map<String, dynamic>> allReservations) {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    return allReservations.where((reservation) {
      final reservationDate = reservation['fecha'];
      final estado = reservation['estado'];
      
      // Solo del día actual y con estado 'no_show' (marcadas manualmente como no vinieron)
      return reservationDate == todayStr && estado == 'no_show';
    }).toList();
  }

  // Funciones para cálculos en tiempo real de las estadísticas
  int _getTodayReservationsTotal() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    return allReservations.where((r) => r['fecha'] == todayStr).length;
  }

  int _getCompletedCount() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    return allReservations.where((r) => r['fecha'] == todayStr && (r['estado'] == 'completada' || r['estado'] == 'liberada_manual')).length;
  }


  int _getConfirmedCount() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    return allReservations.where((r) => r['fecha'] == todayStr && r['estado'] == 'confirmada').length;
  }

  int _getNoShowCount() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    // Incluir tanto 'no_show' (manual) como 'expirada' (automático)
    return allReservations.where((r) => 
      r['fecha'] == todayStr && 
      (r['estado'] == 'no_show' || r['estado'] == 'expirada')
    ).length;
  }

  int _getInTableCount() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    // Solo los que están actualmente comiendo en mesa
    return allReservations.where((r) => r['fecha'] == todayStr && r['estado'] == 'en_mesa').length;
  }
  
  // Verificar reservas críticas y mostrar notificaciones
  void _checkCriticalReservations() {
    if (!mounted || showCalendarView || reservations.isEmpty) return;
    
    for (final reservation in reservations) {
      if (reservation['estado'] != 'confirmada') continue;
      
      final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
      if (timeLeft == null) continue;
      
      final reservationId = reservation['id'];
      final mesa = reservation['sodita_mesas'];
      final minutesLeft = timeLeft.inMinutes;
      
      // 🔔 NUEVA ALERTA: Cuando EMPIEZAN los 15 minutos de tolerancia
      if (minutesLeft == 15 && !_notifiedReservations.contains('$reservationId-start15min')) {
        _notifiedReservations.add('$reservationId-start15min');
        _showCriticalAlert(
          '🕐 INICIA TOLERANCIA',
          'Mesa ${mesa['numero']} - ${reservation['nombre']}\n¡Ya es la hora de reserva! Inician los 15 minutos de tolerancia',
          Colors.blue,
          reservation,
        );
      }
      
      // Alerta a los 5 minutos exactos
      if (minutesLeft == 5 && !_notifiedReservations.contains('$reservationId-5min')) {
        _notifiedReservations.add('$reservationId-5min');
        _showCriticalAlert(
          '⚠️ ALERTA: 5 MINUTOS',
          'Mesa ${mesa['numero']} - ${reservation['nombre']}\nSolo quedan 5 minutos para llegar',
          Colors.orange,
          reservation,
        );
      }
      
      // Alerta a los 2 minutos (período súper crítico)
      if (minutesLeft == 2 && !_notifiedReservations.contains('$reservationId-2min')) {
        _notifiedReservations.add('$reservationId-2min');
        _showCriticalAlert(
          '🚨 CRÍTICO: 2 MINUTOS',
          'Mesa ${mesa['numero']} - ${reservation['nombre']}\n¡Solo quedan 2 minutos!',
          Colors.red,
          reservation,
        );
      }
      
      // Alerta cuando se vence (0 minutos)
      if (minutesLeft == 0 && !_notifiedReservations.contains('$reservationId-expired')) {
        _notifiedReservations.add('$reservationId-expired');
        _showCriticalAlert(
          '💀 VENCIDA',
          'Mesa ${mesa['numero']} - ${reservation['nombre']}\n¡Reserva vencida! Mesa disponible',
          Colors.red[800]!,
          reservation,
        );
      }
    }
    
    // Limpiar notificaciones de reservas que ya no están activas
    _cleanupNotifications();
  }
  
  void _cleanupNotifications() {
    final activeReservationIds = reservations
        .where((r) => r['estado'] == 'confirmada')
        .map((r) => r['id'])
        .toSet();
    
    _notifiedReservations.removeWhere((notification) {
      final reservationId = notification.split('-')[0];
      return !activeReservationIds.contains(reservationId);
    });
  }
  
  void _showCriticalAlert(String title, String message, Color color, Map<String, dynamic> reservation) {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            message,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => overlayEntry.remove(),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry.remove();
                          _updateReservationStatus(reservation['id'], 'en_mesa');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Llegó', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry.remove();
                          _updateReservationStatus(reservation['id'], 'no_show');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.no_accounts, size: 16),
                        label: const Text('No vino', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto-remover después de 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
    
    // Efecto de sonido/vibración (opcional)
    _playNotificationSound();
  }
  
  void _playNotificationSound() {
    // Aquí puedes agregar sonido o vibración
    // Por ahora dejamos un print para debug
    print('🔔 Notificación crítica enviada');
  }

  Future<void> _updateReservationStatus(String reservationId, String newStatus, [Map<String, dynamic>? reservationData]) async {
    bool success = false;
    
    switch (newStatus) {
      case 'en_mesa':
        success = await ReservationService.checkInReservation(reservationId);
        break;
      case 'completada':
        success = await ReservationService.completeReservation(reservationId);
        // Rating removido - no es necesario en admin
        break;
      case 'no_show':
        success = await ReservationService.markAsNoShow(reservationId);
        break;
      case 'cancelada':
        success = await ReservationService.cancelReservation(reservationId);
        break;
    }

    if (success) {
      // 🚀 ACTUALIZACIÓN INMEDIATA DEL UI (sin esperar BD)
      setState(() {
        // Actualizar estado local inmediatamente para feedback instantáneo
        final index = reservations.indexWhere((r) => r['id'] == reservationId);
        if (index != -1) {
          reservations[index]['estado'] = newStatus;
        }
      });
      
      // Luego cargar datos reales de BD (en paralelo)
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmada':
        return Colors.orange;
      case 'en_mesa':
        return Colors.green;
      case 'completada':
        return Colors.blue;
      case 'no_show':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmada':
        return Icons.schedule;
      case 'en_mesa':
        return Icons.restaurant;
      case 'completada':
        return Icons.check_circle;
      case 'no_show':
        return Icons.person_off;
      case 'cancelada':
        return Icons.cancel;
      case 'expirada':
        return Icons.access_time;
      default:
        return Icons.table_restaurant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmada':
        return 'Confirmada';
      case 'en_mesa':
        return 'En Mesa';
      case 'completada':
        return 'Completada';
      case 'no_show':
        return 'No Vino';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  bool _isLate(String hora) {
    final now = DateTime.now();
    final reservationTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(hora.split(':')[0]),
      int.parse(hora.split(':')[1]),
    );
    
    return now.isAfter(reservationTime.add(const Duration(minutes: 15)));
  }

  // Función de debug para verificar conexión a la base de datos
  Future<void> _debugDatabaseConnection() async {
    try {
      print('🔍 DEBUG: Iniciando verificación de conexión...');
      
      // Test 1: Verificar mesas
      final mesas = await ReservationService.getMesas();
      print('📋 DEBUG: Mesas encontradas: ${mesas.length}');
      
      // Test 2: Verificar todas las reservas
      final allReservations = await ReservationService.getAllReservations();
      print('📅 DEBUG: Total reservas en DB: ${allReservations.length}');
      
      // Test 3: Verificar reservas de hoy específicamente
      final today = DateTime.now();
      final todayReservations = await ReservationService.getReservationsByDate(today);
      print('📅 DEBUG: Reservas de hoy: ${todayReservations.length}');
      
      // Test 4: Verificar todas las reservas de hoy sin filtros
      final allTodayReservations = await ReservationService.getAllReservationsByDate(today);
      print('📅 DEBUG: Todas las reservas de hoy: ${allTodayReservations.length}');
      
      // Mostrar detalles de cada reserva de hoy
      for (var reservation in todayReservations) {
        print('👤 ${reservation['nombre']} - Mesa ${reservation['sodita_mesas']['numero']} - Estado: ${reservation['estado']} - Hora: ${reservation['hora']}');
      }
      
      // Mostrar resultado en UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔍 DEBUG:\n'
              '• Mesas: ${mesas.length}\n'
              '• Total reservas: ${allReservations.length}\n'
              '• Reservas hoy: ${todayReservations.length}/${allTodayReservations.length}'
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print('❌ DEBUG ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Test específico para verificar hora argentina y sistema de expiración
  Future<void> _testTimezoneAndExpiration() async {
    final now = DateTime.now();
    
    print('🧪 TEST SISTEMA LIBERACIÓN AUTOMÁTICA - RESERVAS REALES:');
    print('⏰ Hora actual Argentina: ${now.toString()}');
    print('🕒 Zona horaria: ${now.timeZoneName} (${now.timeZoneOffset})');
    print('📅 Fecha: ${now.toIso8601String().split('T')[0]}');
    print('');
    
    // Verificar reservas reales del día
    final todayReservations = await ReservationService.getReservationsByDate(now);
    print('📋 Reservas del día: ${todayReservations.length}');
    
    for (var reservation in todayReservations) {
      if (reservation['estado'] == 'confirmada') {
        final hora = reservation['hora'];
        final timeToExpiration = ReservationService.getTimeUntilExpirationSeconds(hora);
        final statusTest = ReservationService.getReservationStatus(hora);
        
        print('👤 ${reservation['nombre']} - Mesa ${reservation['sodita_mesas']['numero']}');
        print('⏰ Hora reserva: $hora');
        print('⏱️ Tiempo restante: ${timeToExpiration != null ? '${(timeToExpiration / 60).floor()} min ${timeToExpiration % 60} seg' : 'No iniciado/Expirado'}');
        print('📊 Estado: $statusTest');
        print('---');
      }
    }
    
    // Verificar sistema automático de liberación
    final expiredReservations = await ReservationService.getExpiredReservations();
    print('🔍 Reservas expiradas encontradas: ${expiredReservations.length}');
    
    if (expiredReservations.isNotEmpty) {
      print('🚨 RESERVAS EXPIRADAS:');
      for (var expired in expiredReservations) {
        print('💀 ${expired['nombre']} - Mesa ${expired['sodita_mesas']['numero']} - Hora: ${expired['hora']}');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🇦🇷 TEST SISTEMA REAL:\n'
            '⏰ ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.timeZoneName}\n'
            '📅 ${now.day}/${now.month}/${now.year}\n'
            '📋 Reservas del día: ${todayReservations.length}\n'
            '🔍 Reservas expiradas: ${expiredReservations.length}\n'
            '✅ Sistema funcionando con HORA REAL'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: _buildAppBar(l10n),
      body: isLoading
          ? _buildLoadingIndicator()
          : SafeArea(
              child: Column(
                children: [
                  _buildFilterTabs(l10n),
                  Flexible(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // print('📱 Manual refresh: Usuario actualizando admin...');
                        setState(() => isLoading = true);
                        await _loadData();
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🔄 Datos actualizados - ${reservations.length} reservas cargadas'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              _buildStatsCard(l10n),
                              const SizedBox(height: 12),
                              showCalendarView 
                                  ? _buildCalendarView(l10n)
                                  : _buildReservationsList(l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F2E8),
      foregroundColor: const Color(0xFF1C1B1F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: Color(0xFFC1263C),
          size: 24,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        tooltip: 'Volver al Home',
      ),
      title: Row(
        children: [
          // Logo HD - Fijo 50px
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo color.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2B48C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Color(0xFFA10319),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SODITA Admin',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA10319),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Scrollable actions to prevent overflow
        SizedBox(
          width: 300, // Fixed width to prevent overflow
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Home button
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.home,
                      color: Color(0xFFA10319),
                      size: 16,
                    ),
                    label: Text(
                      'Home',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B4513),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xB3DC0B3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
        // Analytics button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
            icon: const Icon(
              Icons.analytics,
              color: Color(0xFF8B4513),
              size: 20,
            ),
            label: Text(
              l10n.analytics,
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xB3DC0B3F).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        // Moderar Comentarios button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () => _showReviewModerationPanel(),
            icon: const Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF8B4513),
              size: 20,
            ),
            label: Text(
              'Moderar',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
              ],
            ),
          ),
        ),
        // Indicador de alertas críticas
        _buildCriticalAlertsIndicator(),
        IconButton(
          icon: Icon(
            showCalendarView ? Icons.view_list : Icons.calendar_month,
            color: const Color(0xFF6B7280),
          ),
          onPressed: () {
            setState(() {
              showCalendarView = !showCalendarView;
            });
            // 🗓️ CARGAR DATOS INMEDIATAMENTE AL CAMBIAR A CALENDARIO
            if (showCalendarView) {
              print('📅 Activando vista calendario - cargando datos históricos...');
              _loadCalendarData();
            }
          },
          tooltip: showCalendarView ? 'Vista Lista' : l10n.calendarView,
        ),
        // 🚀 REFRESH SÚPER INTELIGENTE
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRotation(
                  turns: (isLoading || _isSoftLoading) ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: Icon(
                    (isLoading || _isSoftLoading) ? Icons.sync : Icons.refresh,
                    color: isLoading ? Colors.blue : (_isSoftLoading ? Colors.green : null),
                  ),
                ),
                // Indicador sutil para soft loading
                if (_isSoftLoading && !isLoading)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              print('🔄 REFRESH MANUAL INICIADO');
              await _processExpiredReservations(); // Procesar liberaciones
              await _loadData(); // Actualizar vista
              print('✅ REFRESH MANUAL COMPLETADO');
            },
            tooltip: 'REFRESH MANUAL - Ver cambios ahora',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _debugDatabaseConnection,
          tooltip: 'Debug DB Connection',
        ),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: _testTimezoneAndExpiration,
          tooltip: 'Test Timezone Argentina',
        ),
        IconButton(
          icon: const Icon(Icons.person_off),
          onPressed: _autoMarkNoShows,
          tooltip: 'Marcar No-Shows',
        ),
        IconButton(
          icon: const Icon(Icons.bedtime),
          onPressed: _cerrarDia,
          tooltip: 'Cerrar Día',
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFF86704),
      ),
    );
  }
  
  Widget _buildCriticalAlertsIndicator() {
    if (showCalendarView) return const SizedBox.shrink();
    
    final criticalCount = reservations.where((r) {
      if (r['estado'] != 'confirmada') return false;
      final timeLeft = ReservationService.getTimeUntilNoShow(r['hora']);
      return timeLeft != null && timeLeft.inMinutes <= 5;
    }).length;
    
    if (criticalCount == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              // Mostrar lista de reservas críticas
              _showCriticalReservationsList();
            },
            tooltip: 'Reservas críticas: $criticalCount',
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                criticalCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCriticalReservationsList() {
    final criticalReservations = reservations.where((r) {
      if (r['estado'] != 'confirmada') return false;
      final timeLeft = ReservationService.getTimeUntilNoShow(r['hora']);
      return timeLeft != null && timeLeft.inMinutes <= 5;
    }).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Reservas Críticas (${criticalReservations.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: criticalReservations.length,
            itemBuilder: (context, index) {
              final reservation = criticalReservations[index];
              final mesa = reservation['sodita_mesas'];
              final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: reservation['estado'] == 'en_mesa' 
                    ? Icon(Icons.restaurant, color: Colors.green, size: 32)
                    : ReservationCountdown(
                        reservationTime: reservation['hora'],
                        onExpired: () {
                          // Auto-liberar cuando expire
                          _processExpiredReservations();
                        },
                      ),
                  title: Text('Mesa ${mesa['numero']} - ${reservation['nombre']}'),
                  subtitle: Text(
                    'Tiempo restante: ${timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : "Vencida"}\n'
                    'Teléfono: ${reservation['telefono']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          Navigator.pop(context);
                          _updateReservationStatus(reservation['id'], 'en_mesa');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _updateReservationStatus(reservation['id'], 'no_show');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _tabAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPeriodTab(7, l10n.last7Days),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodTab(15, l10n.last15Days),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodTab(30, l10n.last30Days),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPeriodTab(int days, String label) {
    final isSelected = selectedPeriod == days;
    
    return GestureDetector(
      onTap: () {
        if (selectedPeriod != days) {
          setState(() {
            selectedPeriod = days;
          });
          _loadData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF86704) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(AppLocalizations l10n) {
    print('🔍 STATS DEBUG: $stats');
    print('🔍 RESERVATIONS DEBUG: ${reservations.length}');
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservas de Hoy',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [
              _buildClickableDashboardCard(
                'Reservas Hoy',
                '${_getTodayReservationsTotal()}',
                Icons.event_note,
                const Color(0xFFE6F3FF),
                const Color(0xFF4A90E2),
                () => _showFilteredReservations('confirmada'),
              ),
              _buildClickableDashboardCard(
                'Completadas',
                '${_getCompletedCount()}',
                Icons.check_circle,
                const Color(0xFFE8F5E8),
                const Color(0xFF4CAF50),
                () => _showFilteredReservations('completada'),
              ),
              _buildClickableDashboardCard(
                'No Show',
                '${_getNoShowCount()}',
                Icons.person_off,
                const Color(0xFFFFEBEE),
                const Color(0xFFE53E3E),
                () => _showFilteredReservations('no_show'),
              ),
              _buildClickableDashboardCard(
                'En Mesa',
                '${_getInTableCount()}',
                Icons.restaurant,
                const Color(0xFFFFF8E1),
                const Color(0xFFFFD700),
                () => _showFilteredReservations('en_mesa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableDashboardCard(String title, String value, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: iconColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 14,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B4513),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar lista filtrada de reservas por estado
  void _showFilteredReservations(String estado) {
    final filteredReservations = allReservations.where((r) => r['estado'] == estado).toList();
    
    String titulo;
    Color color;
    IconData icono;
    
    switch (estado) {
      case 'confirmada':
        titulo = 'Reservas Confirmadas de Hoy';
        color = const Color(0xFF4A90E2);
        icono = Icons.event_note;
        break;
      case 'completada':
        titulo = 'Reservas Completadas';
        color = const Color(0xFF4CAF50);
        icono = Icons.check_circle;
        break;
      case 'no_show':
        titulo = 'No Shows del Día';
        color = const Color(0xFFE53E3E);
        icono = Icons.person_off;
        break;
      case 'en_mesa':
        titulo = 'Clientes en Mesa Ahora';
        color = const Color(0xFFFFD700);
        icono = Icons.restaurant;
        break;
      default:
        titulo = 'Reservas';
        color = Colors.grey;
        icono = Icons.list;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF7F0),
          appBar: AppBar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Icon(icono, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredReservations.length} ${estado == 'confirmada' ? 'reservas' : estado == 'completada' ? 'completadas' : estado == 'no_show' ? 'no shows' : 'en mesa'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          body: filteredReservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay reservas en este estado',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReservations.length,
                  itemBuilder: (context, index) {
                    final reserva = filteredReservations[index];
                    return _buildDetailedReservationCard(reserva, color);
                  },
                ),
        ),
      ),
    );
  }

  // Card detallada para cada reserva con todos los datos
  Widget _buildDetailedReservationCard(Map<String, dynamic> reserva, Color themeColor) {
    final mesa = reserva['sodita_mesas'];
    final nombre = reserva['nombre'] ?? 'Sin nombre';
    final telefono = reserva['telefono'] ?? 'Sin teléfono';
    final email = reserva['email'] ?? '';
    final hora = reserva['hora'] ?? '';
    final personas = reserva['personas'] ?? 0;
    final estado = reserva['estado'] ?? '';
    final numeroMesa = mesa?['numero']?.toString() ?? 'N/A';
    final ubicacionMesa = mesa?['ubicacion'] ?? 'Sin ubicación';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1B1F),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información principal
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(Icons.access_time, 'Hora', hora),
                ),
                Expanded(
                  child: _buildInfoRow(Icons.people, 'Personas', personas.toString()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(Icons.table_restaurant, 'Mesa', 'Mesa $numeroMesa'),
                ),
                Expanded(
                  child: _buildInfoRow(Icons.place, 'Ubicación', ubicacionMesa),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Datos de contacto
            _buildInfoRow(Icons.phone, 'Teléfono', telefono),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email, 'Email', email),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1B1F),
            ),
          ),
        ),
      ],
    );
  }
  



  Widget _buildCalendarView(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(l10n),
          Expanded(
            child: _buildSimpleCalendar(l10n),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleCalendar(AppLocalizations l10n) {
    final startDate = DateTime.now().subtract(Duration(days: selectedPeriod - 1));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedPeriod,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final dayEvents = calendarEvents[DateTime(date.year, date.month, date.day)] ?? [];
        final isToday = _isSameDay(date, DateTime.now());
        
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isToday 
                      ? const LinearGradient(
                          colors: [Color(0xB3DC0B3F), Color(0xFFFF8A33)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isToday ? null : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: dayEvents.isNotEmpty 
                      ? Border.all(
                          color: isToday ? Colors.white : const Color(0xFFF86704),
                          width: 2,
                        )
                      : null,
                ),
                child: InkWell(
                  onTap: dayEvents.isNotEmpty ? () => _showDayDetails(date, l10n) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateHeader(date, l10n),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                _formatDateSubtitle(date, l10n),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isToday ? Colors.white.withValues(alpha: 0.9) : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (dayEvents.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isToday 
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFFF86704).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 14,
                                    color: isToday ? Colors.white : const Color(0xFFF86704),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dayEvents.length}',
                                    style: GoogleFonts.inter(
                                      color: isToday ? Colors.white : const Color(0xFFF86704),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (dayEvents.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: dayEvents.take(3).map((event) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isToday 
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : _getStatusColor(event['estado']).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${event['hora']} - Mesa ${event['sodita_mesas']['numero']}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isToday ? Colors.white : _getStatusColor(event['estado']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (dayEvents.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${dayEvents.length - 3} más...',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isToday ? Colors.white.withValues(alpha: 0.8) : Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  String _formatDateHeader(DateTime date, AppLocalizations l10n) {
    return '${l10n.getDayName(date.weekday)}, ${date.day}';
  }
  
  String _formatDateSubtitle(DateTime date, AppLocalizations l10n) {
    return '${l10n.getMonthName(date.month)} ${date.year}';
  }
  
  Widget _buildCalendarHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFAC2828), Color(0xFFFF8A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.calendarView,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${calendarEvents.length} días con reservas',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReservationCard(Map<String, dynamic> reservation, int index) {
    final mesa = reservation['sodita_mesas'];
    
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 20.0,
        child: FadeInAnimation(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(reservation['estado']).withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation['estado']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(reservation['estado']),
                            color: _getStatusColor(reservation['estado']),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesa ${mesa['numero']}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              mesa['ubicacion'] ?? '',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation['estado']).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(reservation['estado']),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getStatusText(reservation['estado']),
                            style: GoogleFonts.inter(
                              color: _getStatusColor(reservation['estado']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // MI CONTADOR DIGITAL EN VIVO
                        _buildDigitalCounter(reservation['hora']),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reservation['nombre'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${reservation['hora']} • ${reservation['personas']} personas',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reservation['telefono'],
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!showCalendarView) _buildActionButtons(reservation),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDayDetails(DateTime day, AppLocalizations l10n) {
    final dayEvents = calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
    
    if (dayEvents.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFFB80821),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${day.day}/${day.month}/${day.year}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF86704).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dayEvents.length} reservas',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF86704),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final reservation = dayEvents[index];
                    return _buildReservationCard(reservation, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsList(AppLocalizations l10n) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay reservas para hoy',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las nuevas reservas aparecerán aquí',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (reservations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '✨ ¡Todo limpio!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay reservas activas en este momento.\nLas mesas están disponibles para nuevas reservas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < reservations.length; index++)
          _buildReservationCard(reservations[index], index),
        
        // 🗂️ SECCIÓN DE HISTORIAL DEL DÍA (NO VINO + COMPLETADAS)
        const SizedBox(height: 32),
        _buildHistorialSection(),
      ],
    );
  }

  // 🗂️ SECCIÓN INTELIGENTE DE HISTORIAL
  Widget _buildHistorialSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getHistorialReservations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final historialReservations = snapshot.data!;
        if (historialReservations.isEmpty) return const SizedBox.shrink();
        
        final noVino = historialReservations.where((r) => r['estado'] == 'no_vino').toList();
        final completadas = historialReservations.where((r) => r['estado'] == 'completada').toList();
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '📊 Historial del Día',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (noVino.isNotEmpty) ...[
                _buildHistorialSubsection('❌ No Vinieron', noVino, Colors.red),
                const SizedBox(height: 12),
              ],
              
              if (completadas.isNotEmpty) ...[
                _buildHistorialSubsection('✅ Completadas', completadas, Colors.green),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistorialSubsection(String title, List<Map<String, dynamic>> reservations, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${reservations.length})',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...reservations.map((reservation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '• Mesa ${reservation['sodita_mesas']['numero']} - ${reservation['nombre']} (${reservation['hora']})',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        )),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getHistorialReservations() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await ReservationService.getReservationsByDate(DateTime.now());
      return response.where((r) => 
        r['fecha'] == today && 
        (r['estado'] == 'no_vino' || r['estado'] == 'completada')
      ).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final status = reservation['estado'];
    final hasExpired = ReservationService.hasExpired(reservation['hora']);
    final isInCriticalPeriod = ReservationService.isInCriticalPeriod(reservation['hora']);
    
    // 🧠 LÓGICA INTELIGENTE HORARIA
    final now = DateTime.now();
    final reservationTime = DateTime.parse('${reservation['fecha']} ${reservation['hora']}');
    final difference = reservationTime.difference(now);
    final isPastReservationTime = difference.isNegative;
    final minutesUntilReservation = difference.inMinutes;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'confirmada') ...[
          // ✅ BOTÓN SIEMPRE DISPONIBLE: Cliente puede llegar antes de la hora
          _buildActionButton(
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: () => _updateReservationStatus(reservation['id'], 'en_mesa'),
            tooltip: 'Cliente llegó - Check-in',
          ),
          // Info adicional removida para interfaz más limpia
          const SizedBox(width: 8),
          
          // Botón de no-show (no vino) - Siempre disponible
          _buildActionButton(
            icon: Icons.no_accounts,
            color: Colors.red,
            onPressed: () => _showNoShowConfirmation(reservation),
            tooltip: 'Cliente no vino - Marcar como no-show',
          ),
          
          const SizedBox(width: 8),
          
          // 🔓 BOTÓN DE LIBERACIÓN MANUAL - Disponible para recepcionista
          _buildActionButton(
            icon: Icons.lock_open,
            color: Colors.orange[600]!,
            onPressed: () => _showManualReleaseConfirmation(reservation),
            tooltip: 'Liberar mesa manualmente (uso recepcionista)',
          ),
          
          // Botón especial para reservas vencidas (liberar mesa)
          if (hasExpired) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.delete_forever,
              color: Colors.red[700]!,
              onPressed: () => _showExpiredReservationDialog(reservation),
              tooltip: 'RESERVA VENCIDA: Liberar mesa automáticamente',
            ),
          ]
          // Botón de advertencia para período crítico
          else if (isInCriticalPeriod) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.warning,
              color: Colors.orange[700]!,
              onPressed: () => _showCriticalPeriodDialog(reservation),
              tooltip: 'PERÍODO CRÍTICO: Mesa se liberará pronto',
            ),
          ],
        ],
        if (status == 'en_mesa') ...[
          _buildActionButton(
            icon: Icons.restaurant_menu,
            color: Colors.blue,
            onPressed: () => _updateReservationStatus(reservation['id'], 'completada', reservation),
            tooltip: 'Cliente terminó - Completar reserva',
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,  // 🔥 BOTONES GRANDES PARA TABLET (era 26)
        height: 56, // 🔥 BOTONES GRANDES PARA TABLET (era 26) 
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16), // Bordes más redondeados
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            splashColor: color.withValues(alpha: 0.3),
            highlightColor: color.withValues(alpha: 0.1),
            child: Center(
              child: Icon(
                icon, 
                size: 28, // 🔥 ICONOS GRANDES (era 18)
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
  

  // Widget de reloj animado para indicar tiempo de reserva
  Widget _buildAnimatedTimeIndicator(
    Map<String, dynamic> reservation,
    Duration? timeLeft,
    bool hasExpired,
    bool isInCriticalPeriod,
    bool isLate,
  ) {
    String clockStatus;
    String tooltipMessage;
    
    if (hasExpired) {
      clockStatus = 'expired';
      tooltipMessage = 'RESERVA VENCIDA: Mesa disponible para nuevas reservas';
    } else if (isInCriticalPeriod) {
      clockStatus = 'critical';
      tooltipMessage = 'PERÍODO CRÍTICO: ${timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : ""} restantes';
    } else if (isLate) {
      clockStatus = 'late';
      tooltipMessage = 'CLIENTE TARDE: ${timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : ""} para liberar mesa';
    } else {
      clockStatus = 'normal';
      tooltipMessage = 'Tiempo restante: ${timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : ""}';
    }
    
    return Tooltip(
      message: tooltipMessage,
      child: Column(
        children: [
          ReservationCountdown(
            reservationTime: reservation['hora'],
            isLarge: true,
            onExpired: () {
              _processExpiredReservations();
            },
          ),
          const SizedBox(height: 4),
          if (timeLeft != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getClockStatusColor(clockStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ReservationService.formatTimeRemaining(timeLeft),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getClockStatusColor(clockStatus),
                ),
              ),
            )
          else if (hasExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'VENCIDA',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getClockStatusColor(String status) {
    switch (status) {
      case 'normal':
        return const Color(0xFF2E7D32); // Verde más oscuro
      case 'late':
        return const Color(0xFFEF6C00); // Naranja más oscuro
      case 'critical':
        return const Color(0xFFD32F2F); // Rojo más oscuro
      case 'expired':
        return const Color(0xFF212121); // Negro más oscuro
      default:
        return const Color(0xFF424242);
    }
  }
  
  // Diálogo de confirmación para no-show
  void _showNoShowConfirmation(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.no_accounts, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Confirmar No-Show',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas que el cliente NO vino a la reserva?',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Mesa ${mesa['numero']} - ${mesa['ubicacion']}'),
                  Text('👤 ${reservation['nombre']}'),
                  Text('⏰ ${reservation['hora']} - ${reservation['personas']} personas'),
                  Text('📞 ${reservation['telefono']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                '⚠️ La mesa se liberará inmediatamente para nuevas reservas.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReservationStatus(reservation['id'], 'no_show');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar No-Show', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Diálogo para reservas vencidas
  void _showExpiredReservationDialog(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule_outlined, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Reserva Vencida',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta reserva ya pasó los 15 minutos de tolerancia.',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍽️ Mesa ${mesa['numero']} - ${mesa['ubicacion']}'),
                  Text('👤 ${reservation['nombre']}'),
                  Text('⏰ Hora: ${reservation['hora']} (VENCIDA)'),
                  Text('👥 ${reservation['personas']} personas'),
                  Text('📞 ${reservation['telefono']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔄 OPCIONES:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  Text('• Liberar Mesa: Marcar como no-show'),
                  Text('• El sistema lo hará automáticamente'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dejar como está'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReservationStatus(reservation['id'], 'no_show');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mesa ${mesa['numero']} liberada - Reserva marcada como no-show'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Liberar Mesa Ahora', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Diálogo para período crítico
  void _showCriticalPeriodDialog(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              'Período Crítico',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta reserva está en período crítico.',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍽️ Mesa ${mesa['numero']} - ${mesa['ubicacion']}'),
                  Text('👤 ${reservation['nombre']}'),
                  Text('⏰ Hora: ${reservation['hora']}'),
                  Text('⏱️ Tiempo restante: ${timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : "Vencida"}'),
                  Text('📞 ${reservation['telefono']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                '⚠️ La mesa se liberará automáticamente cuando expire el tiempo.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReservationStatus(reservation['id'], 'no_show');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mesa ${mesa['numero']} liberada manualmente'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Liberar Ahora', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  /// Contador CIRCULAR ANIMADO - 15 minutos con colores y progreso visual
  Widget _buildDigitalCounter(String hora) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final reservationTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(hora.split(':')[0]),
          int.parse(hora.split(':')[1]),
        );
        
        final difference = now.difference(reservationTime);
        final totalSecondsElapsed = difference.inSeconds;
        
        // Total de 15 minutos = 900 segundos
        const totalToleranceSeconds = 15 * 60;
        final remainingSeconds = totalToleranceSeconds - totalSecondsElapsed;
        
        // Progreso de 0.0 a 1.0
        final progress = (totalSecondsElapsed / totalToleranceSeconds).clamp(0.0, 1.0);
        
        Color color;
        String timeText;
        IconData icon;
        
        if (totalSecondsElapsed < 0) {
          // Aún no es hora de la reserva
          final timeUntilStart = -totalSecondsElapsed;
          final minutes = timeUntilStart ~/ 60;
          final seconds = timeUntilStart % 60;
          timeText = 'En ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          color = Colors.blue[600]!;
          icon = Icons.schedule;
        } else if (remainingSeconds > 0) {
          // En período de tolerancia (contando hacia abajo)
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          icon = Icons.timer;
          
          // Colores según tiempo restante
          if (remainingSeconds <= 120) { // Últimos 2 minutos
            color = Colors.red[700]!;
          } else if (remainingSeconds <= 300) { // Últimos 5 minutos
            color = Colors.orange[700]!;
          } else if (remainingSeconds <= 600) { // Últimos 10 minutos
            color = Colors.yellow[700]!;
          } else {
            color = Colors.green[600]!;
          }
        } else {
          // Tiempo agotado
          timeText = "VENCIDA";
          color = Colors.red[800]!;
          icon = Icons.warning;
        }
        
        // 🎨 CONTADOR CIRCULAR ANIMADO CON COLORES DE PROGRESO  
        return Container(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculo base (gris claro)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
              ),
              
              // Progreso circular animado
              SizedBox(
                width: 56,
                height: 56,
                child: AnimatedBuilder(
                  animation: AlwaysStoppedAnimation(progress),
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              
              // Texto central con tiempo
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    timeText.contains(':') ? timeText.split(':')[0] : timeText.substring(0, 2),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (timeText.contains(':'))
                    Text(
                      timeText.split(':')[1],
                      style: TextStyle(
                        fontSize: 8,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
              
              // Efecto de pulso para estados críticos
              if (remainingSeconds > 0 && remainingSeconds <= 300)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: progress > 0.7 ? 70 : 60,
                  height: progress > 0.7 ? 70 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: progress > 0.7 ? 3 : 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 🔓 DIÁLOGO DE CONFIRMACIÓN PARA LIBERACIÓN MANUAL
  void _showManualReleaseConfirmation(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.lock_open,
          color: Colors.orange[600],
          size: 32,
        ),
        title: Text(
          'Liberar Mesa Manualmente',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmas que deseas liberar esta mesa manualmente?',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Mesa ${mesa?['numero'] ?? 'N/A'} - ${mesa?['ubicacion'] ?? 'N/A'}'),
                  Text('👤 ${reservation['nombre'] ?? 'N/A'}'),
                  Text('⏰ ${reservation['hora'] ?? 'N/A'} - ${reservation['personas'] ?? 0} personas'),
                  Text('📞 ${reservation['telefono'] ?? 'N/A'}'),
                  Text('🆔 Código: ${reservation['codigo_confirmacion'] ?? 'N/A'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción liberará la mesa inmediatamente para nuevas reservas.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processManualRelease(reservation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sí, liberar mesa',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  // 🔄 PROCESAR LIBERACIÓN MANUAL DE MESA
  Future<void> _processManualRelease(Map<String, dynamic> reservation) async {
    try {
      print('🔓 Liberación manual de mesa: ${reservation['id']}');
      
      // Actualizar estado a 'liberada_manual' para diferenciarlo de automático
      final response = await supabase
          .from('sodita_reservas')
          .update({
            'estado': 'liberada_manual',
            'liberado_manualmente_en': DateTime.now().toIso8601String(),
            'notas_liberacion': 'Mesa liberada manualmente por recepcionista',
          })
          .eq('id', reservation['id']);
      
      print('✅ Mesa liberada manualmente');
      
      // Recargar datos
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Mesa ${reservation['sodita_mesas']?['numero'] ?? 'N/A'} liberada manualmente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error en liberación manual: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al liberar mesa: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showRatingDialog(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        reservationId: reservation['id'],
        customerName: reservation['nombre'] ?? 'Cliente',
        mesaNumero: mesa?['numero'],
        onRatingSubmitted: (ratingData) async {
          final success = await RatingService.createRating(
            reservationId: ratingData['reservation_id'],
            customerName: ratingData['customer_name'],
            stars: ratingData['stars'],
            comment: ratingData['comment'],
            mesaNumero: ratingData['mesa_numero'],
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Valoración guardada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Error al guardar la valoración'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showReviewModerationPanel() {}

}

// 💳 PANTALLA DE SUSCRIPCIÓN Y PAGO
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _isProcessingPayment = false;

  // 🏦 DATOS BANCARIOS PARA TRANSFERENCIA
  static const String BANK_ALIAS = 'SODITA.RESERVAS';
  static const String BANK_ACCOUNT = 'CBU: 0070055630004012345678';
  static const String BANK_HOLDER = 'SODITA RESTAURANT S.R.L.';
  static const String MONTHLY_AMOUNT = '\$50.000';

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    
    try {
      // Simular procesamiento de pago
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        // Mostrar diálogo de éxito
        _showPaymentSuccessDialog();
      }
    } catch (e) {
      _showError('Error procesando el pago. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pago Exitoso!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu suscripción ha sido activada.\nYa puedes acceder al panel de administración.',
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Acceder al Admin',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    // Simular copiar al portapapeles
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Header con logo y título
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2563EB),
                                    const Color(0xFF3B82F6),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SODITA Premium',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1B1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Gestión de Reservas Profesional',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Dirección del restaurante
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Laprida 1301, Rosario',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Plan de suscripción
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2563EB), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan Mensual',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1B1F),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Recomendado',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Precio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            MONTHLY_AMOUNT,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ARS / mes',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Características
                      Column(
                        children: [
                          _buildFeatureItem('✅ Gestión completa de reservas'),
                          _buildFeatureItem('✅ Sistema de cola virtual MesaYa!'),
                          _buildFeatureItem('✅ Analytics en tiempo real'),
                          _buildFeatureItem('✅ Notificaciones automáticas'),
                          _buildFeatureItem('✅ Gestión de valoraciones'),
                          _buildFeatureItem('✅ Liberación automática de mesas'),
                          _buildFeatureItem('✅ Panel de administración avanzado'),
                          _buildFeatureItem('✅ Soporte técnico 24/7'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Información de pago
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Datos para Transferencia',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1B1F),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Alias
                      _buildPaymentInfo(
                        'Alias',
                        BANK_ALIAS,
                        Icons.alternate_email,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // CBU
                      _buildPaymentInfo(
                        'CBU',
                        BANK_ACCOUNT,
                        Icons.numbers,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Titular
                      _buildPaymentInfo(
                        'Titular',
                        BANK_HOLDER,
                        Icons.person,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Monto
                      _buildPaymentInfo(
                        'Monto',
                        MONTHLY_AMOUNT,
                        Icons.attach_money,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Instrucciones
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Instrucciones de Pago',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Realiza la transferencia con los datos arriba\n'
                              '2. Envía el comprobante por WhatsApp al +54 341 123-4567\n'
                              '3. Tu suscripción será activada en menos de 24hs',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF4B5563),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Botón de pago
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessingPayment
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Ya Realicé la Transferencia',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón secundario
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Volver al Login',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value, label),
            icon: const Icon(
              Icons.copy,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

}
