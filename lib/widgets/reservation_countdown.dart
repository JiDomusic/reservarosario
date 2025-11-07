import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/reservation_service.dart';

class ReservationCountdown extends StatefulWidget {
  final String reservationTime;
  final VoidCallback? onExpired;
  final bool isLarge;
  
  const ReservationCountdown({
    super.key,
    required this.reservationTime,
    this.onExpired,
    this.isLarge = false,
  });

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isExpired = false;
  bool _isPending = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final status = ReservationService.getReservationStatus(widget.reservationTime);
    
    if (status == 'pending') {
      // Aún no es hora de la reserva
      final timeUntilStart = ReservationService.getTimeUntilReservationStart(widget.reservationTime);
      setState(() {
        _secondsRemaining = timeUntilStart ?? 0;
        _isExpired = false;
        _isPending = true;
      });
    } else if (status == 'active') {
      // En período de tolerancia (15 minutos)
      final seconds = ReservationService.getTimeUntilExpirationSeconds(widget.reservationTime);
      setState(() {
        _secondsRemaining = seconds ?? 0;
        _isExpired = false;
        _isPending = false;
      });
    } else if (status == 'expired') {
      // Ya expiró
      if (!_isExpired) {
        setState(() {
          _isExpired = true;
          _secondsRemaining = 0;
          _isPending = false;
        });
        widget.onExpired?.call();
      }
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      // Si hay horas, mostrar formato HH:MM:SS
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      // Si no hay horas, mostrar formato MM:SS
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Color _getCountdownColor() {
    if (_isExpired) return Colors.red;
    if (_isPending) return Colors.blue; // Esperando hora de reserva
    if (_secondsRemaining <= 300) return const Color(0xFF2563EB); // Últimos 5 minutos
    if (_secondsRemaining <= 600) return Colors.yellow.shade700; // Últimos 10 minutos
    return Colors.green;
  }

  IconData _getCountdownIcon() {
    if (_isExpired) return Icons.warning;
    if (_isPending) return Icons.schedule; // Esperando
    if (_secondsRemaining <= 300) return Icons.timer;
    return Icons.hourglass_top;
  }

  String _getStatusText() {
    if (_isExpired) return "TIEMPO AGOTADO";
    if (_isPending) return "Inicia en:";
    return "Tiempo restante:";
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCountdownColor();
    final icon = _getCountdownIcon();
    final statusText = _getStatusText();
    final timeText = _isExpired ? "EXPIRADO" : _formatTime(_secondsRemaining);
    
    if (widget.isLarge) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🕐 RELOJ CIRCULAR ANIMADO - Solo flujo visual, sin números
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: CircularClockPainter(
                  progress: _isExpired ? 1.0 : (1.0 - (_secondsRemaining / 900.0)), // Tiempo transcurrido, no restante
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Icon(
                    _isExpired ? Icons.timer_off : Icons.access_time,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
            timeText,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Painter para reloj circular animado con flujo de color
class CircularClockPainter extends CustomPainter {
  final double progress; // 0.0 a 1.0 (1.0 = 15 minutos completos)
  final Color color;
  final Color backgroundColor;

  CircularClockPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    // Fondo del círculo (gris claro)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Arco de progreso (cuarto de círculo = 15 minutos)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // El arco inicia desde las 12:00 (arriba) y va hacia las 3:00 (derecha)
      // -π/2 = empezar arriba, progress * π/2 = cuarto de círculo máximo
      final sweepAngle = progress * (math.pi / 2); // Máximo π/2 = 90 grados = cuarto de círculo

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Empezar arriba
        sweepAngle,   // Cuanto avanzar
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

// Alert flotante para mesas liberadas
class TableReleasedAlert extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback onDismiss;
  final VoidCallback? onReserveNow;

  const TableReleasedAlert({
    super.key,
    required this.tableData,
    required this.onDismiss,
    this.onReserveNow,
  });

  @override
  Widget build(BuildContext context) {
    final mesa = tableData['sodita_mesas'];
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '¡Mesa Liberada!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Mesa ${mesa?['numero'] ?? 'N/A'} está ahora disponible',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '${mesa?['ubicacion'] ?? ''} • ${mesa?['capacidad'] ?? 0} personas',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onReserveNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reservar Ahora',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

// Alert flotante para reservas expiradas
class ReservationExpiredAlert extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final VoidCallback onDismiss;

  const ReservationExpiredAlert({
    super.key,
    required this.reservationData,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final mesa = reservationData['sodita_mesas'];
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color(0xFF2563EB),
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Reserva Expirada',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2563EB),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Mesa ${mesa?['numero'] ?? 'N/A'} ha sido liberada automáticamente',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Cliente: ${reservationData['nombre'] ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Hora: ${reservationData['hora'] ?? 'N/A'} (15 min de tolerancia agotados)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}