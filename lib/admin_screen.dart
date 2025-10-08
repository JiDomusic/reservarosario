import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'services/reservation_service.dart';
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
              color: Colors.white,
              border: Border.all(
                color: _getClockColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getClockColor().withOpacity(0.3),
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
      ..color = clockColor.withOpacity(0.6)
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
    if (timeRemaining == null) {
      // Si no hay tiempo restante, mostrar reloj estático en 12:00
      _drawStaticHands(canvas, center, radius);
      return;
    }
    
    final totalSeconds = 15 * 60; // 15 minutos total
    final remainingSeconds = timeRemaining!.inSeconds;
    final progress = remainingSeconds / totalSeconds;
    
    // Manecilla principal que muestra el tiempo restante (de 0 a 15 minutos)
    // Comienza en 12 (arriba) y se mueve en sentido horario
    final timeAngle = ((1 - progress) * 90 - 90) * math.pi / 180; // 90 grados = 15 minutos
    _drawHand(
      canvas,
      center,
      timeAngle,
      radius * 0.8,
      3.0,
      clockColor,
    );
    
    // Manecilla de segundos (animada para mostrar que está funcionando)
    final secondAngle = (secondHandAnimation.value * 360 - 90) * math.pi / 180;
    _drawHand(
      canvas,
      center,
      secondAngle,
      radius * 0.6,
      1.0,
      clockColor.withOpacity(0.6),
    );
    
    // Dibujar números de minutos (5, 10, 15)
    _drawMinuteNumbers(canvas, center, radius);
  }
  
  void _drawStaticHands(Canvas canvas, Offset center, double radius) {
    // Manecilla principal apuntando a 12 (sin tiempo restante)
    _drawHand(
      canvas,
      center,
      -math.pi / 2, // 12 en punto
      radius * 0.8,
      3.0,
      clockColor.withOpacity(0.5),
    );
  }
  
  void _drawMinuteNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Dibujar números 5, 10, 15 en las posiciones correspondientes
    final positions = [
      {'number': '5', 'angle': 0}, // 3 en punto = 5 minutos
      {'number': '10', 'angle': 90}, // 6 en punto = 10 minutos  
      {'number': '15', 'angle': 180}, // 9 en punto = 15 minutos
    ];
    
    for (final pos in positions) {
      final angle = ((pos['angle'] as int) - 90) * math.pi / 180;
      final x = center.dx + (radius - 20) * math.cos(angle);
      final y = center.dy + (radius - 20) * math.sin(angle);

      textPainter.text = TextSpan(
        text: pos['number'] as String,
        style: TextStyle(
          color: clockColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
    
    // Dibujar "0" en la parte superior (12 en punto)
    final topX = center.dx;
    final topY = center.dy - (radius - 20);
    
    textPainter.text = TextSpan(
      text: '0',
      style: TextStyle(
        color: clockColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(topX - textPainter.width / 2, topY - textPainter.height / 2),
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
    
    // Color del arco basado en el tiempo restante
    Color arcColor;
    if (progress > 0.66) {
      arcColor = const Color(0xFF10B981); // Verde
    } else if (progress > 0.33) {
      arcColor = const Color(0xFFEF6C00); // Naranja
    } else {
      arcColor = const Color(0xFFE53E3E); // Rojo
    }
    
    final paint = Paint()
      ..color = arcColor.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius + 8);
    
    // Dibujar arco completo de fondo (gris claro)
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius + 8, backgroundPaint);
    
    // Dibujar arco de progreso (solo la parte restante)
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      rect,
      -math.pi / 2, // Empezar desde arriba (12 en punto)
      sweepAngle,
      false,
      paint,
    );
    
    // Dibujar marcadores cada 5 minutos (3 marcadores)
    _drawTimeMarkers(canvas, center, radius + 8);
  }
  
  void _drawTimeMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = clockColor.withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    // Marcadores a los 5, 10 y 15 minutos
    for (int i = 1; i <= 3; i++) {
      final angle = (i * (360 / 4) - 90) * math.pi / 180; // Cada 5 min = 90 grados
      final startRadius = radius - 4;
      final endRadius = radius + 4;
      
      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        markerPaint,
      );
    }
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

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> reservations = [];
  Map<String, dynamic> stats = {};
  Map<DateTime, List<Map<String, dynamic>>> calendarEvents = {};
  Map<DateTime, List<Map<String, dynamic>>> futureReservations = {};
  bool isLoading = true;
  Timer? _autoCheckTimer;
  Timer? _countdownTimer;
  
  // Variables para filtros y vista
  int selectedPeriod = 7; // 7, 15, 30 días
  bool showCalendarView = false;
  bool showFutureView = false;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  
  // Controladores de animación
  late AnimationController _statsAnimationController;
  late AnimationController _tabAnimationController;
  late Animation<double> _statsAnimation;
  late Animation<double> _tabAnimation;
  
  // Sistema de notificaciones automáticas
  Timer? _notificationTimer;
  Set<String> _notifiedReservations = {}; // Para evitar duplicados
  List<String> _criticalAlerts = []; // Lista de alertas activas

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
    
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsAnimationController, curve: Curves.easeOutBack),
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _startAutoCheck();
    
    // Iniciar animaciones
    _statsAnimationController.forward();
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationTimer?.cancel();
    _statsAnimationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  // Iniciar verificación automática y contadores
  void _startAutoCheck() {
    // Auto-marcar no-shows cada 2 minutos (más frecuente)
    _autoCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted && !showCalendarView && !showFutureView) {
        _autoMarkNoShows();
      }
    });
    
    // Contador en tiempo real cada segundo para actualizar los tiempos
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !showCalendarView && !showFutureView) {
        setState(() {
          // Forzar reconstrucción para actualizar contadores y filtrar vencidas
        });
        
        // Cada 30 segundos, recargar datos para filtrar reservas vencidas
        if (DateTime.now().second % 30 == 0) {
          _loadData();
        }
      }
    });
    
    // Timer para notificaciones críticas cada 30 segundos
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !showCalendarView && !showFutureView) {
        _checkCriticalReservations();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (showFutureView) {
        // Cargar reservas futuras (próximos 30 días)
        final futureData = await ReservationService.getFutureReservations();
        setState(() {
          futureReservations = futureData;
          isLoading = false;
        });
      } else if (showCalendarView) {
        // Cargar datos para el calendario
        final calendarData = await ReservationService.getReservationsForCalendar(selectedPeriod);
        final statsData = await ReservationService.getReservationStats(selectedPeriod);
        
        setState(() {
          calendarEvents = calendarData;
          stats = statsData;
          isLoading = false;
        });
      } else {
        // Cargar reservas del día actual (solo activas: confirmadas y en_mesa)
        final today = DateTime.now();
        final allTodaysReservations = await ReservationService.getAllReservationsByDate(today);
        
        // Filtrar reservas según el estado:
        // - 'confirmada': Solo si aún no vencieron (para alertas/reloj)
        // - 'en_mesa': Siempre visible (clientes que llegaron)
        final now = DateTime.now();
        final activeReservations = allTodaysReservations
            .where((reservation) {
              final estado = reservation['estado'];
              
              if (estado == 'en_mesa') {
                // Siempre mostrar clientes que están en mesa
                return true;
              }
              
              if (estado == 'confirmada') {
                // Solo mostrar reservas confirmadas que aún no vencieron
                final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
                return timeLeft != null; // null = ya vencida
              }
              
              // No mostrar: completada, no_show, cancelada
              return false;
            })
            .toList();
        
        final todayStats = await _calculateTodayStats(allTodaysReservations);
        
        setState(() {
          reservations = activeReservations; // Solo reservas activas
          stats = todayStats; // Estadísticas completas del día
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _autoMarkNoShows() async {
    print('🔄 Ejecutando auto-marcado de no-shows...');
    await ReservationService.autoMarkNoShow();
    
    // Recargar datos para actualizar la vista
    await _loadData();
    
    print('✅ Auto-marcado completado y vista actualizada');
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
    
    // Obtener mesas únicas con estados activos
    final mesasConfirmadas = todayReservations
        .where((r) => r['estado'] == 'confirmada')
        .map((r) => r['mesa_id'])
        .toSet();
    
    final mesasEnUso = todayReservations
        .where((r) => r['estado'] == 'en_mesa')
        .map((r) => r['mesa_id'])
        .toSet();
    
    final mesasCanceladas = todayReservations
        .where((r) => r['estado'] == 'cancelada')
        .map((r) => r['mesa_id'])
        .toSet();
    
    // Contar mesas únicas por estado
    final reservedTables = mesasConfirmadas.length; // Mesas con reservas confirmadas únicas
    final activeTables = mesasEnUso.length; // Mesas actualmente ocupadas únicas
    final cancelledTables = mesasCanceladas.length; // Mesas con cancelaciones únicas
    
    // Mesas libres = total - (mesas con cualquier reserva activa)
    final mesasOcupadasHoy = mesasConfirmadas.union(mesasEnUso);
    final freeTables = totalTables - mesasOcupadasHoy.length;
    
    return {
      'total': total,
      'confirmadas': confirmadas,
      'completadas': completadas,
      'no_shows': noShows,
      'canceladas': canceladas,
      'en_mesa': enMesa,
      'total_tables': totalTables,
      'occupied_tables': activeTables, // Mesas únicas con clientes actualmente
      'reserved_tables': reservedTables, // Mesas únicas reservadas esperando
      'cancelled_tables': cancelledTables, // Mesas únicas con cancelaciones
      'free_tables': freeTables,
      'tasa_completadas': total > 0 ? (completadas / total * 100).round() : 0,
      'tasa_no_shows': total > 0 ? (noShows / total * 100).round() : 0,
      'tasa_canceladas': total > 0 ? (canceladas / total * 100).round() : 0,
    };
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
      else if (minutesLeft == 2 && !_notifiedReservations.contains('$reservationId-2min')) {
        _notifiedReservations.add('$reservationId-2min');
        _showCriticalAlert(
          '🚨 CRÍTICO: 2 MINUTOS',
          'Mesa ${mesa['numero']} - ${reservation['nombre']}\n¡Solo quedan 2 minutos!',
          Colors.red,
          reservation,
        );
      }
      
      // Alerta cuando se vence (0 minutos)
      else if (minutesLeft == 0 && !_notifiedReservations.contains('$reservationId-expired')) {
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
    
    final mesa = reservation['sodita_mesas'];
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

  Future<void> _updateReservationStatus(String reservationId, String newStatus) async {
    bool success = false;
    
    // Mostrar indicador de carga
    setState(() {
      isLoading = true;
    });
    
    switch (newStatus) {
      case 'en_mesa':
        success = await ReservationService.checkInReservation(reservationId);
        break;
      case 'completada':
        success = await ReservationService.completeReservation(reservationId);
        break;
      case 'no_show':
        success = await ReservationService.markAsNoShow(reservationId);
        break;
      case 'cancelada':
        success = await ReservationService.cancelReservation(reservationId);
        break;
    }

    if (success) {
      // Recargar datos inmediatamente
      await _loadData();
      
      // Mostrar mensaje según el estado
      String message;
      switch (newStatus) {
        case 'en_mesa':
          message = '✅ Cliente en mesa confirmado';
          break;
        case 'completada':
          message = '🎉 Reserva completada exitosamente';
          break;
        case 'no_show':
          message = '❌ Mesa liberada - Cliente no llegó';
          break;
        case 'cancelada':
          message = '🚫 Reserva cancelada';
          break;
        default:
          message = 'Estado actualizado';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus == 'no_show' || newStatus == 'cancelada' 
                ? Colors.orange 
                : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al actualizar el estado'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(l10n),
      body: isLoading
          ? _buildLoadingIndicator()
          : Column(
              children: [
                if (!showFutureView) _buildFilterTabs(l10n),
                if (!showFutureView) _buildStatsCard(l10n),
                Expanded(
                  child: showFutureView 
                      ? _buildFutureReservationsView(l10n)
                      : showCalendarView 
                          ? _buildCalendarView(l10n)
                          : _buildReservationsList(l10n),
                ),
              ],
            ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        'Panel de Administración SODITA',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFF86704),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Indicador de alertas críticas
        _buildCriticalAlertsIndicator(),
        IconButton(
          icon: Icon(showFutureView ? Icons.event_note : Icons.calendar_today_outlined),
          onPressed: () {
            setState(() {
              showFutureView = !showFutureView;
              showCalendarView = false;
            });
            _loadData();
          },
          tooltip: showFutureView ? 'Vista Hoy' : 'Reservas Futuras',
        ),
        IconButton(
          icon: Icon(showCalendarView ? Icons.list : Icons.calendar_month),
          onPressed: () {
            setState(() {
              showCalendarView = !showCalendarView;
              showFutureView = false;
            });
            _loadData();
          },
          tooltip: showCalendarView ? 'Vista Lista' : l10n.calendarView,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
        IconButton(
          icon: const Icon(Icons.schedule),
          onPressed: _autoMarkNoShows,
          tooltip: 'Marcar No-Shows',
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
        content: Container(
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
                  leading: AnimatedClock(
                    timeRemaining: timeLeft,
                    status: 'critical',
                    size: 48,
                    showNumbers: true,
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
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF86704), Color(0xFFFF8A33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF86704).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showCalendarView ? l10n.statistics : 'Resumen del Día',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        showCalendarView ? 'Últimos $selectedPeriod días' : 'Hoy',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!showCalendarView) _buildTodayStats(l10n) else _buildPeriodStats(l10n),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTodayStats(AppLocalizations l10n) {
    return Column(
      children: [
        // Estadísticas de mesas
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Mesas',
                '${stats['total_tables'] ?? 0}',
                Colors.white,
                Icons.restaurant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Reservadas',
                '${stats['reserved_tables'] ?? 0}',
                Colors.orange[300]!,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Ocupadas',
                '${stats['occupied_tables'] ?? 0}',
                Colors.red[300]!,
                Icons.people,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Canceladas',
                '${stats['cancelled_tables'] ?? 0}',
                Colors.grey[300]!,
                Icons.cancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Libres',
                '${stats['free_tables'] ?? 0}',
                Colors.green[300]!,
                Icons.event_available,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Estadísticas de reservas
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '${stats['total'] ?? 0}',
                Colors.white,
                Icons.groups,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                'Confirmadas',
                '${stats['confirmadas'] ?? 0}',
                Colors.orange[200]!,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                'En Mesa',
                '${stats['en_mesa'] ?? 0}',
                Colors.green[200]!,
                Icons.restaurant_menu,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                'Completadas',
                '${stats['completadas'] ?? 0}',
                Colors.blue[200]!,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                'Canceladas',
                '${stats['canceladas'] ?? 0}',
                Colors.red[200]!,
                Icons.cancel,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPeriodStats(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            l10n.totalReservations,
            '${stats['total'] ?? 0}',
            Colors.white,
            Icons.analytics,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            l10n.completionRate,
            '${stats['tasa_completadas'] ?? 0}%',
            Colors.green[300]!,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            l10n.noShowRate,
            '${stats['tasa_no_shows'] ?? 0}%',
            Colors.red[300]!,
            Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isToday 
                      ? const LinearGradient(
                          colors: [Color(0xFFF86704), Color(0xFFFF8A33)],
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF86704), Color(0xFFFF8A33)],
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
    final isLate = _isLate(reservation['hora']) && reservation['estado'] == 'confirmada';
    final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
    final isInCriticalPeriod = ReservationService.isInCriticalPeriod(reservation['hora']);
    final hasExpired = ReservationService.hasExpired(reservation['hora']);
    
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: _getBorderForReservation(reservation, isLate, hasExpired, isInCriticalPeriod),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                            color: const Color(0xFFF86704).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.table_restaurant,
                            color: const Color(0xFFF86704),
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
                        // Reloj animado para indicar tiempo
                        if (reservation['estado'] == 'confirmada') ...[
                          const SizedBox(width: 12),
                          _buildAnimatedTimeIndicator(reservation, timeLeft, hasExpired, isInCriticalPeriod, isLate),
                        ],
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reservation['estado'] == 'en_mesa' 
                                    ? Icons.people 
                                    : Icons.schedule,
                                color: _getStatusColor(reservation['estado']),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(reservation['estado']),
                                style: GoogleFonts.inter(
                                  color: _getStatusColor(reservation['estado']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reservation['estado'] == 'en_mesa') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '🔴 OCUPADA',
                              style: GoogleFonts.inter(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFFF86704),
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

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index], index);
        },
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final status = reservation['estado'];
    final hasExpired = ReservationService.hasExpired(reservation['hora']);
    final isInCriticalPeriod = ReservationService.isInCriticalPeriod(reservation['hora']);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'confirmada') ...[
          // Botón de check-in (llegó)
          _buildActionButton(
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: () => _updateReservationStatus(reservation['id'], 'en_mesa'),
            tooltip: 'Cliente llegó - Check-in',
          ),
          const SizedBox(width: 8),
          
          // Botón de no-show (no vino) - Siempre disponible
          _buildActionButton(
            icon: Icons.no_accounts,
            color: Colors.red,
            onPressed: () => _showNoShowConfirmation(reservation),
            tooltip: 'Cliente no vino - Marcar como no-show',
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
            icon: Icons.payments,
            color: Colors.green,
            onPressed: () => _showClientLeftDialog(reservation),
            tooltip: 'Cliente pagó y se fue - Liberar mesa',
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.event_available,
            color: Colors.blue,
            onPressed: () => _showMakeTableAvailableDialog(reservation),
            tooltip: 'Mesa disponible - Otras razones',
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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          color: color,
          onPressed: onPressed,
        ),
      ),
    );
  }
  
  Widget _buildTimeIndicator(String text, Color color, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Border? _getBorderForReservation(Map<String, dynamic> reservation, bool isLate, bool hasExpired, bool isInCriticalPeriod) {
    if (reservation['estado'] != 'confirmada') return null;
    
    if (hasExpired) {
      return Border.all(color: Colors.red, width: 3);
    } else if (isInCriticalPeriod) {
      return Border.all(color: Colors.red, width: 2);
    } else if (isLate) {
      return Border.all(color: Colors.orange, width: 2);
    }
    
    return null;
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
          AnimatedClock(
            timeRemaining: timeLeft,
            status: clockStatus,
            size: 60.0,
            showNumbers: true,
          ),
          const SizedBox(height: 4),
          if (timeLeft != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getClockStatusColor(clockStatus).withOpacity(0.1),
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
                color: Colors.red.withOpacity(0.1),
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
                  const SizedBox(height: 4),
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
  
  // Diálogo para cuando el cliente pagó y se fue
  void _showClientLeftDialog(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              'Cliente se fue',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirma que el cliente pagó y se fue de la mesa.',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍽️ Mesa ${mesa['numero']} - ${mesa['ubicacion']}'),
                  Text('👤 ${reservation['nombre']}'),
                  Text('⏰ Hora: ${reservation['hora']}'),
                  Text('👥 ${reservation['personas']} personas'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Servicios completados:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('✓ Cliente atendido correctamente'),
                  Text('✓ Pago procesado'),
                  Text('✓ Mesa lista para limpiar'),
                  Text('✓ Disponible para nuevos clientes'),
                ],
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
              _updateReservationStatus(reservation['id'], 'completada');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mesa ${mesa['numero']} liberada - Cliente se fue'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar - Liberar Mesa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Diálogo para liberar mesa (Mesa Disponible)
  void _showMakeTableAvailableDialog(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_available, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              'Mesa Disponible',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Liberar esta mesa y marcarla como disponible?',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍽️ Mesa ${mesa['numero']} - ${mesa['ubicacion']}'),
                  Text('👤 ${reservation['nombre']}'),
                  Text('⏰ Hora: ${reservation['hora']}'),
                  Text('👥 ${reservation['personas']} personas'),
                  Text('📞 ${reservation['telefono']}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 RAZONES COMUNES:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Los clientes se fueron'),
                  Text('• Mesa necesita limpieza/arreglo'),
                  Text('• Problema en la cocina/servicio'),
                  Text('• Mesa disponible para nuevos clientes'),
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
              _updateReservationStatus(reservation['id'], 'completada');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mesa ${mesa['numero']} liberada y disponible'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Liberar Mesa', style: TextStyle(color: Colors.white)),
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
                color: Colors.orange[50],
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
                color: Colors.red[50],
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

  // Vista de reservas futuras (próximos 30 días)
  Widget _buildFutureReservationsView(AppLocalizations l10n) {
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
          _buildFutureReservationsHeader(),
          Expanded(
            child: _buildFutureReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureReservationsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF86704), Color(0xFFFF8A33)],
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
            Icons.calendar_today_outlined,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Reservas Futuras (próximos 30 días)',
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
              '${futureReservations.length} días con reservas',
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

  Widget _buildFutureReservationsList() {
    if (futureReservations.isEmpty) {
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
                Icons.event_available,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay reservas futuras',
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

    final sortedDates = futureReservations.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayReservations = futureReservations[date]!;
        final isToday = _isSameDay(date, DateTime.now());
        final isTomorrow = _isSameDay(date, DateTime.now().add(const Duration(days: 1)));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFF86704).withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday ? const Color(0xFFF86704) : Colors.grey[200]!,
              width: isToday ? 2 : 1,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFFF86704) : Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday 
                            ? 'Hoy, ${_formatDate(date)}'
                            : isTomorrow
                                ? 'Mañana, ${_formatDate(date)}'
                                : _formatDateWithDay(date),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? const Color(0xFFF86704) : Colors.black87,
                        ),
                      ),
                      Text(
                        '${dayReservations.length} reserva${dayReservations.length != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildOccupancyIndicator(dayReservations),
              ],
            ),
            children: dayReservations.map((reservation) {
              return _buildFutureReservationCard(reservation);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildOccupancyIndicator(List<Map<String, dynamic>> reservations) {
    final confirmedCount = reservations.where((r) => r['estado'] == 'confirmada').length;
    final totalTables = 10; // Total de mesas
    final occupancyRate = (confirmedCount / totalTables * 100).round();
    
    Color indicatorColor;
    if (occupancyRate >= 80) {
      indicatorColor = Colors.red;
    } else if (occupancyRate >= 50) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$occupancyRate%',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureReservationCard(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(reservation['estado']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              color: _getStatusColor(reservation['estado']),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Mesa ${mesa['numero']}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(reservation['estado']).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(reservation['estado']),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(reservation['estado']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation['hora']} • ${reservation['nombre']} • ${reservation['personas']} personas',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (reservation['telefono'] != null)
                  Text(
                    '📞 ${reservation['telefono']}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  String _formatDateWithDay(DateTime date) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}