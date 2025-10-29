import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> reservations = [];
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

  // Iniciar verificación automática cada 30 segundos para nuevas reservas
  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 Auto-refresh: Verificando nuevas reservas...');
      _loadData(); // Recargar datos cada 30 segundos
    });
    
    // Contador en tiempo real cada segundo para actualizar los tiempos
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !showCalendarView) {
        setState(() {
          // Forzar reconstrucción para actualizar contadores
        });
      }
    });
    
    // Timer para notificaciones críticas cada 30 segundos
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkCriticalReservations();
    });
  }

  // Sistema de liberación automática de reservas cada 60 segundos
  void _startAutoReleaseSystem() {
    _autoReleaseTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _processExpiredReservations();
    });
  }

  // Procesar reservas expiradas y mostrar alertas
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
      
      // Recargar datos si se liberaron reservas
      if (releasedTables.isNotEmpty) {
        _loadData();
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

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (showCalendarView) {
        // Cargar datos para el calendario
        final calendarData = await ReservationService.getReservationsForCalendar(selectedPeriod);
        final statsData = await ReservationService.getReservationStats(selectedPeriod);
        
        setState(() {
          calendarEvents = calendarData;
          stats = statsData;
          isLoading = false;
        });
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
        
        setState(() {
          reservations = activeReservations; // Solo reservas activas del día
          stats = todayStats; // Estadísticas de reservas activas
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
      
      // Si es del día actual, mostrar todos los estados
      if (reservationDate == todayStr) {
        return true;
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
        // Home button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.home,
              color: Color(0xFFA10319),
              size: 20,
            ),
            label: Text(
              'Home',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xB3DC0B3F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            _loadData();
          },
          tooltip: showCalendarView ? 'Vista Lista' : l10n.calendarView,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            print('🔄 Manual refresh button pressed');
            _loadData();
          },
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
                  leading: ReservationCountdown(
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
              _buildDashboardCard(
                'Reservas Hoy',
                '${stats['total'] ?? reservations.length}',
                Icons.event_note,
                const Color(0xFFE6F3FF),
                const Color(0xFF4A90E2),
              ),
              _buildDashboardCard(
                'Completadas',
                '${stats['completadas'] ?? reservations.where((r) => r['estado'] == 'completada').length}',
                Icons.people,
                const Color(0xFFE8F5E8),
                const Color(0xFF4CAF50),
              ),
              _buildDashboardCard(
                'Mesas Ocupadas',
                '${stats['occupied_tables'] ?? reservations.where((r) => r['estado'] == 'en_mesa').length}',
                Icons.table_restaurant,
                const Color(0xFFFFF3E0),
                const Color(0xFFFF9800),
              ),
              _buildDashboardCard(
                'En Mesa',
                '${stats['en_mesa'] ?? reservations.where((r) => r['estado'] == 'en_mesa').length}',
                Icons.star,
                const Color(0xFFFFF8E1),
                const Color(0xFFFFD700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
          Text(
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

    return Column(
      children: [
        for (int index = 0; index < reservations.length; index++)
          _buildReservationCard(reservations[index], index),
      ],
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
      child: Container(
        width: 26,
        height: 26,
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


  /// Contador digital EN VIVO - Cuenta desde hora de reserva hasta 15 min después
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
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
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
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
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

}
