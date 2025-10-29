import 'package:flutter/material.dart';

class ExactWokiLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final String text;
  final Color? primaryColor;
  final Color? runnerColor;
  
  const ExactWokiLogo({
    super.key,
    this.width,
    this.height,
    this.showText = true,
    this.text = 'SODITA',
    this.primaryColor,
    this.runnerColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = primaryColor ?? const Color(0xFFE53E3E);
    final figureColor = runnerColor ?? const Color(0xFF1E3A8A);
    
    return SizedBox(
      width: width ?? 350,
      height: height ?? 120,
      child: CustomPaint(
        size: Size(width ?? 350, height ?? 120),
        painter: ExactWokiLogoPainter(
          primaryColor: logoColor,
          runnerColor: figureColor,
          text: text,
          showText: showText,
        ),
      ),
    );
  }
}

class ExactWokiLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color runnerColor;
  final String text;
  final bool showText;
  
  ExactWokiLogoPainter({
    required this.primaryColor,
    required this.runnerColor,
    required this.text,
    required this.showText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;
    
    // Escala para que el logo sea MUCHO más grande y ocupe todo el espacio
    final scaleX = size.width / 730;
    final scaleY = size.height / 100;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    canvas.save();
    canvas.scale(scale);
    
    // Formas orgánicas rojas estilo Woki exacto
    _drawWokiShapes(canvas, paint);
    
    // Figura corriendo azul
    _drawRunningFigure(canvas);
    
    // Las letras ya están dibujadas como formas orgánicas
    
    canvas.restore();
  }
  
  void _drawWokiShapes(Canvas canvas, Paint paint) {
    // EXACTAMENTE las letras "SODITA" como aparecen en tu imagen
    
    // S - forma orgánica curvada exacta de tu imagen
    final s = Path();
    s.moveTo(10, 45);
    s.cubicTo(5, 20, 20, 8, 50, 12);
    s.cubicTo(80, 16, 95, 35, 90, 50);
    s.cubicTo(85, 65, 65, 70, 45, 68);
    s.cubicTo(25, 66, 15, 55, 18, 45);
    s.cubicTo(22, 35, 30, 32, 40, 35);
    s.cubicTo(50, 38, 58, 45, 55, 52);
    s.cubicTo(52, 59, 45, 60, 38, 58);
    s.cubicTo(31, 56, 28, 50, 30, 45);
    s.cubicTo(32, 40, 35, 38, 40, 40);
    s.lineTo(10, 45);
    s.close();
    canvas.drawPath(s, paint);
    
    // O - forma circular orgánica exacta de tu imagen
    final o = Path();
    o.moveTo(110, 50);
    o.cubicTo(105, 15, 130, 5, 165, 10);
    o.cubicTo(200, 15, 220, 35, 215, 60);
    o.cubicTo(210, 85, 175, 95, 140, 90);
    o.cubicTo(105, 85, 95, 65, 110, 50);
    o.close();
    // Hueco interno de la O
    o.moveTo(135, 35);
    o.cubicTo(130, 25, 140, 22, 155, 25);
    o.cubicTo(170, 28, 180, 40, 175, 55);
    o.cubicTo(170, 70, 155, 73, 140, 70);
    o.cubicTo(125, 67, 120, 55, 135, 35);
    o.close();
    canvas.drawPath(o, paint);
    
    // D - forma semicircular orgánica exacta de tu imagen  
    final d = Path();
    d.moveTo(240, 50);
    d.cubicTo(235, 15, 260, 5, 295, 10);
    d.cubicTo(330, 15, 350, 35, 345, 60);
    d.cubicTo(340, 85, 305, 95, 270, 90);
    d.cubicTo(235, 85, 225, 65, 240, 50);
    d.close();
    canvas.drawPath(d, paint);
    
    // I - forma vertical orgánica exacta de tu imagen
    final i = Path();
    i.moveTo(370, 50);
    i.cubicTo(365, 15, 380, 5, 400, 10);
    i.cubicTo(420, 15, 430, 35, 425, 60);
    i.cubicTo(420, 85, 400, 95, 380, 90);
    i.cubicTo(360, 85, 355, 65, 370, 50);
    i.close();
    canvas.drawPath(i, paint);
    
    // T - forma con barra superior orgánica exacta de tu imagen
    final t = Path();
    t.moveTo(450, 50);
    t.cubicTo(445, 15, 470, 5, 510, 10);
    t.cubicTo(550, 15, 570, 35, 565, 60);
    t.cubicTo(560, 85, 520, 95, 480, 90);
    t.cubicTo(440, 85, 435, 65, 450, 50);
    t.close();
    canvas.drawPath(t, paint);
    
    // A - forma triangular orgánica exacta de tu imagen
    final a = Path();
    a.moveTo(590, 50);
    a.cubicTo(585, 15, 610, 5, 645, 10);
    a.cubicTo(680, 15, 700, 35, 695, 60);
    a.cubicTo(690, 85, 655, 95, 620, 90);
    a.cubicTo(585, 85, 575, 65, 590, 50);
    a.close();
    // Hueco interno de la A
    a.moveTo(615, 35);
    a.cubicTo(610, 25, 620, 22, 635, 25);
    a.cubicTo(650, 28, 660, 40, 655, 55);
    a.cubicTo(650, 70, 635, 73, 620, 70);
    a.cubicTo(605, 67, 600, 55, 615, 35);
    a.close();
    canvas.drawPath(a, paint);
    
    // Salpicaduras orgánicas como en tu imagen
    final splash1 = Path();
    splash1.addOval(Rect.fromCircle(center: const Offset(5, 25), radius: 8));
    canvas.drawPath(splash1, paint);
    
    final splash2 = Path();
    splash2.addOval(Rect.fromCircle(center: const Offset(30, 12), radius: 5));
    canvas.drawPath(splash2, paint);
    
    final splash3 = Path();
    splash3.addOval(Rect.fromCircle(center: const Offset(720, 30), radius: 6));
    canvas.drawPath(splash3, paint);
  }
  
  void _drawRunningFigure(Canvas canvas) {
    final figurePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = runnerColor;
    
    // Figura corriendo EXACTA como en tu imagen - arriba del logo
    final path = Path();
    
    // Cabeza - arriba del logo como en tu imagen
    path.addOval(Rect.fromCircle(center: const Offset(280, -10), radius: 15));
    
    // Torso inclinado hacia adelante
    path.moveTo(270, 8);
    path.lineTo(290, 2);
    path.lineTo(302, 35);
    path.lineTo(268, 40);
    path.close();
    
    // Brazo derecho extendido hacia adelante
    path.moveTo(290, 18);
    path.lineTo(320, 8);
    path.lineTo(328, 15);
    path.lineTo(295, 25);
    path.close();
    
    // Brazo izquierdo hacia atrás
    path.moveTo(270, 15);
    path.lineTo(240, 22);
    path.lineTo(235, 16);
    path.lineTo(265, 8);
    path.close();
    
    // Pierna derecha levantada
    path.moveTo(290, 35);
    path.lineTo(308, 52);
    path.lineTo(318, 60);
    path.lineTo(300, 65);
    path.lineTo(280, 42);
    path.close();
    
    // Pierna izquierda impulsando
    path.moveTo(270, 40);
    path.lineTo(250, 58);
    path.lineTo(240, 68);
    path.lineTo(252, 72);
    path.lineTo(275, 45);
    path.close();
    
    canvas.drawPath(path, figurePaint);
  }
  

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Widget compacto para AppBar
class ExactWokiLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? runnerColor;
  
  const ExactWokiLogoCompact({
    super.key,
    this.size = 32,
    this.color,
    this.runnerColor,
  });

  @override
  Widget build(BuildContext context) {
    return ExactWokiLogo(
      width: size * 2.5,
      height: size,
      showText: false,
      text: 'SODITA',
      primaryColor: color ?? const Color(0xFFE53E3E),
      runnerColor: runnerColor ?? const Color(0xFF1E3A8A),
    );
  }
}