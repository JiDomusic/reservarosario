import 'package:flutter/material.dart';

class ExactSoditaLogo extends StatelessWidget {
  final double? width;
  final double? height;
  
  const ExactSoditaLogo({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el tamaño apropiado basado en las constraints disponibles
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : width ?? 400;
        final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : height ?? 150;
        
        // Usar el tamaño más pequeño para evitar overflow
        final effectiveWidth = width != null ? 
            (width! > availableWidth ? availableWidth : width!) : 
            availableWidth;
        final effectiveHeight = height != null ? 
            (height! > availableHeight ? availableHeight : height!) : 
            availableHeight;
        
        return SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.transparent,
              BlendMode.multiply,
            ),
            child: Image.asset(
              'assets/images/logo color.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (context, error, stackTrace) {
              // Si no encuentra la imagen, mostrar placeholder compacto
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: effectiveHeight * 0.3,
                          color: Colors.grey[400],
                        ),
                        if (effectiveHeight > 40) ...[
                          SizedBox(height: effectiveHeight * 0.1),
                          Text(
                            'SODITA',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: effectiveHeight * 0.15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
          ),
        );
      },
    );
  }
}

