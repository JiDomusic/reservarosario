import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoditaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final Color? primaryColor;
  final Color? shadowColor;
  
  const SoditaLogo({
    super.key,
    this.width,
    this.height,
    this.showText = true,
    this.primaryColor,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = primaryColor ?? const Color(0xFFE53E3E);
    final defaultShadow = shadowColor ?? const Color(0xFF1E3A8A);
    
    return Container(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Logo principal estilo Woki con curvas orgánicas
          CustomPaint(
            size: Size(width ?? 200, height ?? 80),
            painter: SoditaLogoPainter(
              primaryColor: logoColor,
              shadowColor: defaultShadow,
            ),
          ),
          
          // Texto si está habilitado
          if (showText)
            Positioned(
              bottom: -5,
              left: 0,
              right: 0,
              child: Text(
                'RESERVAS',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: (height ?? 80) * 0.15,
                  fontWeight: FontWeight.w600,
                  color: logoColor.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SoditaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color shadowColor;
  
  SoditaLogoPainter({
    required this.primaryColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;
    
    // Sombra del logo (offset para efecto 3D)
    paint.color = shadowColor.withValues(alpha: 0.3);
    _drawSoditaShape(canvas, size, paint, offset: const Offset(3, 3));
    
    // Logo principal con gradiente rojo Woki
    final gradient = LinearGradient(
      colors: [
        primaryColor,
        primaryColor.withBlue(primaryColor.blue + 20),
        primaryColor.withRed((primaryColor.red * 0.9).round()),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    
    _drawSoditaShape(canvas, size, paint);
    
    // Highlight blanco para efecto brillante estilo Woki
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.3);
    _drawHighlight(canvas, size, paint);
  }
  
  void _drawSoditaShape(Canvas canvas, Size size, Paint paint, {Offset? offset}) {
    final path = Path();
    final dx = offset?.dx ?? 0;
    final dy = offset?.dy ?? 0;
    
    // Forma orgánica similar al logo de Woki que mostraste
    // Letra "S" estilizada con curvas fluidas
    path.moveTo(size.width * 0.15 + dx, size.height * 0.3 + dy);
    
    // Curva superior de la S
    path.quadraticBezierTo(
      size.width * 0.05 + dx, size.height * 0.1 + dy,
      size.width * 0.25 + dx, size.height * 0.1 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.45 + dx, size.height * 0.1 + dy,
      size.width * 0.5 + dx, size.height * 0.25 + dy,
    );
    
    // Parte media con curva
    path.quadraticBezierTo(
      size.width * 0.55 + dx, size.height * 0.4 + dy,
      size.width * 0.45 + dx, size.height * 0.5 + dy,
    );
    
    // Curva inferior de la S
    path.quadraticBezierTo(
      size.width * 0.35 + dx, size.height * 0.6 + dy,
      size.width * 0.45 + dx, size.height * 0.75 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.55 + dx, size.height * 0.9 + dy,
      size.width * 0.75 + dx, size.height * 0.85 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.9 + dx, size.height * 0.8 + dy,
      size.width * 0.85 + dx, size.height * 0.65 + dy,
    );
    
    // Conectar de vuelta con curvas suaves
    path.quadraticBezierTo(
      size.width * 0.8 + dx, size.height * 0.55 + dy,
      size.width * 0.7 + dx, size.height * 0.5 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.6 + dx, size.height * 0.45 + dy,
      size.width * 0.65 + dx, size.height * 0.35 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.7 + dx, size.height * 0.25 + dy,
      size.width * 0.6 + dx, size.height * 0.2 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.4 + dx, size.height * 0.12 + dy,
      size.width * 0.25 + dx, size.height * 0.25 + dy,
    );
    path.quadraticBezierTo(
      size.width * 0.1 + dx, size.height * 0.35 + dy,
      size.width * 0.15 + dx, size.height * 0.3 + dy,
    );
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawHighlight(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    
    // Highlight en la parte superior izquierda
    path.moveTo(size.width * 0.2, size.height * 0.15);
    path.quadraticBezierTo(
      size.width * 0.35, size.height * 0.12,
      size.width * 0.4, size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.35, size.height * 0.25,
      size.width * 0.25, size.height * 0.22,
    );
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.18,
      size.width * 0.2, size.height * 0.15,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget simplificado para usar en AppBar
class SoditaLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;
  
  const SoditaLogoCompact({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SoditaLogo(
      width: size * 2,
      height: size,
      showText: false,
      primaryColor: color ?? const Color(0xFFE53E3E),
    );
  }
}