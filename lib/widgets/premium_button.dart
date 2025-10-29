import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool showShimmer;
  
  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.showShimmer = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isEnabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!widget.isEnabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isEnabled && widget.onPressed != null;
    final bgColor = widget.backgroundColor ?? const Color(0xFFE53E3E);
    final txtColor = widget.textColor ?? Colors.white;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isActive ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _shimmerController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height ?? 56,
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            bgColor,
                            bgColor.withRed((bgColor.red * 1.1).clamp(0, 255).round()),
                            bgColor.withBlue((bgColor.blue * 1.1).clamp(0, 255).round()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : const Color(0xFFE5E7EB),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.3),
                      blurRadius: _isPressed ? 8 : 16,
                      offset: Offset(0, _isPressed ? 2 : 4),
                      spreadRadius: _isPressed ? 0 : 1,
                    ),
                    if (_isPressed)
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    // Shimmer effect
                    if (widget.showShimmer && isActive)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CustomPaint(
                            painter: ShimmerPainter(_shimmerAnimation.value),
                          ),
                        ),
                      ),
                    
                    // Button content
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: isActive ? txtColor : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isActive ? txtColor : const Color(0xFF9CA3AF),
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
        },
      ),
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double animationValue;
  
  ShimmerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        transform: GradientRotation(0.3),
      ).createShader(
        Rect.fromLTWH(
          size.width * animationValue - size.width * 0.5,
          0,
          size.width,
          size.height,
        ),
      );
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  
  const PulseButton({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}