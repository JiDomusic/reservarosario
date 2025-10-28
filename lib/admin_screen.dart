import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'services/reservation_service.dart';
import 'l10n.dart';
import 'dart:async';
import 'dart:math' as math;
import 'floor_plan_view.dart';

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
                  color: _getClockColor().withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: SimpleClockPainter(
                timeRemaining: widget.timeRemaining,
                clockColor: _getClockColor(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Reloj simple de 15 minutos
class SimpleClockPainter extends CustomPainter {
  final Duration? timeRemaining;
  final Color clockColor;

  SimpleClockPainter({
    required this.timeRemaining,
    required this.clockColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    if (timeRemaining == null) return;
    
    // Calcular progreso (0 a 15 minutos)
    final totalSeconds = 15 * 60;
    final remainingSeconds = timeRemaining!.inSeconds.clamp(0, totalSeconds);
    final progress = remainingSeconds / totalSeconds;
    
    // Color según tiempo restante
    Color progressColor;
    if (progress > 0.66) {
      progressColor = Colors.green;
    } else if (progress > 0.33) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }
    
    // Fondo del círculo
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progreso del tiempo
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
    
    // Tiempo restante en el centro
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    
    textPainter.text = TextSpan(
      text: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: TextStyle(
        color: progressColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(SimpleClockPainter oldDelegate) {
    return oldDelegate.timeRemaining != timeRemaining;
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
  bool showFloorPlanView = false;
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
  final Set<String> _notifiedReservations = {}; // Para evitar duplicados

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
    // Auto-marcar no-shows cada 30 segundos para mayor precisión
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !showCalendarView && !showFutureView) {
        _autoMarkNoShows();
      }
    });
    
    // Contador optimizado - solo actualizar UI cada 10 segundos
    _countdownTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !showCalendarView && !showFutureView) {
        setState(() {
          // Solo actualizar contadores sin recargar datos
        });
      }
    });
    
    // Timer para notificaciones críticas cada 10 segundos
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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
      } else if (showFloorPlanView) {
        // Cargar datos para vista de plano
        final today = DateTime.now();
        final allTodaysReservations = await ReservationService.getAllReservationsByDate(today);
        final mesas = await ReservationService.getMesas();
        
        setState(() {
          reservations = allTodaysReservations;
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
        // Cargar reservas del día actual (solo activas)
        final today = DateTime.now();
        final allTodaysReservations = await ReservationService.getAllReservationsByDate(today);
        
        // Debug: Verificar datos cargados
        debugPrint('🔍 Admin Dashboard: Cargando reservas para ${today.toIso8601String().split('T')[0]}');
        debugPrint('📊 Total reservas encontradas: ${allTodaysReservations.length}');
        
        // Filtrar solo reservas que el admin necesita ver:
        // - 'confirmada': Esperando llegada del cliente
        // - 'en_mesa': Clientes que llegaron y están comiendo
        // NO mostrar: no_show, cancelada, completada (para no confundir)
        final activeReservations = allTodaysReservations
            .where((reservation) {
              final estado = reservation['estado'];
              return estado == 'confirmada' || estado == 'en_mesa';
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
      debugPrint('Error loading admin data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _autoMarkNoShows() async {
    debugPrint('🔄 Executing auto no-show marking...');
    await ReservationService.autoMarkNoShow();
    
    // Recargar datos para actualizar la vista
    await _loadData();
    
    debugPrint('✅ Auto no-show marking completed');
  }

  void _checkForExpiredReservations() {
    // Verificar reservas que acaban de expirar en tiempo real
    for (final reservation in reservations) {
      if (reservation['estado'] == 'confirmada') {
        final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
        if (timeLeft == null || timeLeft.inSeconds <= 0) {
          // Reserva expirada - marcar como no_show automáticamente
          debugPrint('⏰ Reservation ${reservation['codigo_confirmacion']} expired automatically');
          _updateReservationStatus(reservation['id'], 'no_show');
          
          // Mostrar notificación al admin
          _showAutoReleaseNotification(reservation);
        }
      }
    }
  }

  void _showAutoReleaseNotification(Map<String, dynamic> reservation) {
    if (mounted) {
      final mesa = reservation['sodita_mesas'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⏰ Mesa ${mesa['numero']} liberada automáticamente - Cliente no llegó',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              // Mostrar detalles de la reserva liberada
            },
          ),
        ),
      );
    }
  }

  Widget _buildManualReleaseButton(Map<String, dynamic> reservation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showManualReleaseConfirmation(reservation),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'LIBERAR',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    required String label,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 14),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProminentCountdown(Map<String, dynamic> reservation, Duration timeLeft, String urgencyLevel) {
    final mesa = reservation['sodita_mesas'];
    final minutes = timeLeft.inMinutes;
    final seconds = timeLeft.inSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    Color bgColor = Colors.green;
    Color textColor = Colors.white;
    IconData icon = Icons.schedule;
    String label = 'TIEMPO RESTANTE';
    
    switch (urgencyLevel) {
      case 'critical':
        bgColor = Colors.orange;
        icon = Icons.warning_amber;
        label = '¡CRÍTICO!';
        break;
      case 'expired':
        bgColor = Colors.red;
        icon = Icons.schedule_outlined;
        label = '¡TIEMPO AGOTADO!';
        break;
    }
    
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tiempo digital grande y prominente 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  timeString,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: bgColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'MINUTOS RESTANTES',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: bgColor.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Barra de progreso visual
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (timeLeft.inSeconds / (15 * 60)).clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mesa ${mesa['numero']}',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showManualReleaseConfirmation(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Liberar Mesa ${mesa['numero']}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Confirmar liberación manual de la mesa?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mesa ${mesa['numero']} liberada manualmente - Disponible para nuevas reservas'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Liberar Mesa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    debugPrint('🔔 Critical notification sent');
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
        return const Color(0xFF2196F3); // Azul Woki - Reservada
      case 'en_mesa':
        return const Color(0xFFFF9800); // Naranja Woki - Ocupada
      case 'completada':
        return const Color(0xFF4CAF50); // Verde Woki - Completada
      case 'no_show':
        return const Color(0xFFF44336); // Rojo Woki - No vino
      case 'cancelada':
        return const Color(0xFF9E9E9E); // Gris - Cancelada
      default:
        return const Color(0xFF4CAF50); // Verde Woki - Disponible por defecto
    }
  }


  // Gradientes elegantes para las tarjetas estilo Woki premium
  LinearGradient _getCardGradient(String status) {
    switch (status) {
      case 'confirmada':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.orange.withValues(alpha: 0.08),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      case 'en_mesa':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.green.withValues(alpha: 0.12),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.withValues(alpha: 0.05)],
        );
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
                      : showFloorPlanView
                          ? FloorPlanView(
                              reservations: reservations,
                              onReservationTap: _showReservationDetails,
                            )
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Panel de Administración SODITA',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Reloj de Argentina en tiempo real
          StreamBuilder<DateTime>(
            stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
            builder: (context, snapshot) {
              final now = DateTime.now();
              // Argentina timezone - usar hora local del sistema
              final argTime = now;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇦🇷 ARG',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${argTime.hour.toString().padLeft(2, '0')}:${argTime.minute.toString().padLeft(2, '0')}:${argTime.second.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
          icon: Icon(showFloorPlanView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              showFloorPlanView = !showFloorPlanView;
              showCalendarView = false;
              showFutureView = false;
            });
            _loadData();
          },
          tooltip: showFloorPlanView ? 'Vista Lista' : 'Plano del Restaurant',
        ),
        IconButton(
          icon: Icon(showCalendarView ? Icons.list : Icons.calendar_month),
          onPressed: () {
            setState(() {
              showCalendarView = !showCalendarView;
              showFloorPlanView = false;
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
    
    // Calcular estado visual del contador
    final isCountdownActive = reservation['estado'] == 'confirmada' && timeLeft != null;
    final urgencyLevel = hasExpired ? 'expired' : isInCriticalPeriod ? 'critical' : 'normal';
    
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
              gradient: _getCardGradient(reservation['estado']),
              borderRadius: BorderRadius.circular(16),
              border: _getBorderForReservation(reservation, isLate, hasExpired, isInCriticalPeriod),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(reservation['estado']).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _getStatusColor(reservation['estado']).withValues(alpha: 0.2),
                                _getStatusColor(reservation['estado']).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(reservation['estado']).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(reservation['estado']).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Icon(
                                reservation['estado'] == 'en_mesa' 
                                    ? Icons.people // Ícono de personas cuando está ocupada
                                    : Icons.table_restaurant, // Ícono de mesa cuando está esperando
                                color: _getStatusColor(reservation['estado']),
                                size: 20,
                              ),
                              // Indicador adicional para mesa ocupada
                              if (reservation['estado'] == 'en_mesa')
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                  ),
                                ),
                            ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStatusColor(reservation['estado']).withValues(alpha: 0.8),
                                _getStatusColor(reservation['estado']),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(reservation['estado']).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reservation['estado'] == 'en_mesa' 
                                    ? Icons.people 
                                    : Icons.schedule,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(reservation['estado']),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reservation['estado'] == 'en_mesa') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[400]!, Colors.green[600]!],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'OCUPADA',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
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
                    if (!showCalendarView) 
                      Column(
                        children: [
                          // Contador prominente de 15 minutos
                          if (isCountdownActive) _buildProminentCountdown(reservation, timeLeft, urgencyLevel),
                          const SizedBox(height: 8),
                          _buildActionButtons(reservation),
                        ],
                      ),
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
          const SizedBox(width: 6),
          
          // Botón de liberación manual - SIEMPRE visible para admin
          _buildManualReleaseButton(reservation),
          const SizedBox(width: 6),
          
          // Botón especial para reservas vencidas (liberar mesa)
          if (hasExpired) ...[
            _buildUrgentActionButton(
              icon: Icons.schedule_outlined,
              color: Colors.red[700]!,
              onPressed: () => _showExpiredReservationDialog(reservation),
              tooltip: '⏰ VENCIDA: Auto-liberación activa',
              label: 'VENCIDA',
            ),
          ]
          // Botón de advertencia para período crítico
          else if (isInCriticalPeriod) ...[
            _buildUrgentActionButton(
              icon: Icons.warning_amber,
              color: Colors.orange[700]!,
              onPressed: () => _showCriticalPeriodDialog(reservation),
              tooltip: '⚠️ CRÍTICO: ${ReservationService.formatTimeRemaining(ReservationService.getTimeUntilNoShow(reservation['hora'])!)} restante',
              label: 'CRÍTICO',
            ),
          ],
        ],
        if (status == 'en_mesa') ...[
          // Botón principal: Cliente se fue (pagó)
          _buildPrimaryActionButton(
            icon: Icons.payments,
            text: 'Pagó',
            color: Colors.green,
            onPressed: () => _showClientLeftDialog(reservation),
            tooltip: 'Cliente pagó y se fue - Liberar mesa',
          ),
          const SizedBox(width: 8),
          // Botón secundario: Liberar por otras razones
          _buildActionButton(
            icon: Icons.event_available,
            color: Colors.blue,
            onPressed: () => _showMakeTableAvailableDialog(reservation),
            tooltip: 'Liberar mesa por otras razones',
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

  // Botón principal más prominente para acciones importantes
  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: color.withValues(alpha: 0.4),
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
  
  // CONTADOR ESTILO WOKI - Tiempo restante en MM:SS
  Widget _buildAnimatedTimeIndicator(
    Map<String, dynamic> reservation,
    Duration? timeLeft,
    bool hasExpired,
    bool isInCriticalPeriod,
    bool isLate,
  ) {
    if (hasExpired) {
      return _buildReleaseButton(reservation);
    }
    
    if (timeLeft == null) return const SizedBox.shrink();
    
    final minutes = timeLeft.inMinutes;
    final seconds = timeLeft.inSeconds % 60;
    final timeDisplay = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    // Colores estilo Woki
    Color bgColor, textColor;
    if (minutes <= 2) {
      bgColor = const Color(0xFFF44336).withOpacity(0.1); // Rojo Woki
      textColor = const Color(0xFFF44336);
    } else if (minutes <= 5) {
      bgColor = const Color(0xFFFF9800).withOpacity(0.1); // Naranja Woki
      textColor = const Color(0xFFFF9800);
    } else {
      bgColor = const Color(0xFF4CAF50).withOpacity(0.1); // Verde Woki
      textColor = const Color(0xFF4CAF50);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            timeDisplay,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Botón para liberar mesa manualmente
  Widget _buildReleaseButton(Map<String, dynamic> reservation) {
    return ElevatedButton.icon(
      onPressed: () => _releaseTableManually(reservation),
      icon: const Icon(Icons.lock_open, size: 16),
      label: const Text('LIBERAR'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Liberar mesa manualmente
  Future<void> _releaseTableManually(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liberar Mesa'),
        content: Text('¿Liberar Mesa ${reservation['sodita_mesas']['numero']} de ${reservation['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ReservationService.releaseTableManually(
        reservation['id'], 
        reservation['nombre']
      );
      
      if (success) {
        _loadData(); // Recargar datos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesa ${reservation['sodita_mesas']['numero']} liberada manualmente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  // Mostrar detalles de reserva desde la vista de plano
  void _showReservationDetails(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
    final hasExpired = timeLeft == null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF86704),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.table_restaurant,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Mesa ${mesa['numero']}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.person, 'Cliente', reservation['nombre']),
            _buildDetailRow(Icons.access_time, 'Hora', reservation['hora']),
            _buildDetailRow(Icons.people, 'Personas', '${reservation['personas']}'),
            _buildDetailRow(Icons.phone, 'Teléfono', reservation['telefono'] ?? 'No disponible'),
            _buildDetailRow(Icons.info, 'Estado', _getStatusText(reservation['estado'])),
            if (timeLeft != null && !hasExpired)
              _buildDetailRow(
                Icons.timer, 
                'Tiempo restante', 
                ReservationService.formatTimeRemaining(timeLeft),
              ),
            if (hasExpired)
              _buildDetailRow(Icons.warning, 'Estado', 'RESERVA VENCIDA', color: Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          if (reservation['estado'] == 'confirmada' && !hasExpired)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateReservationStatus(reservation['id'], 'en_mesa');
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cliente confirmado en Mesa ${mesa['numero']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check-in'),
            ),
          if (reservation['estado'] == 'confirmada')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _releaseTableManually(reservation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Liberar'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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