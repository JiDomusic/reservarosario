import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/restaurant.dart';
import '../services/dynamic_availability_service.dart';

class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  int? _dynamicAvailableTables;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final availability = await DynamicAvailabilityService.getAvailableTablesCount(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _dynamicAvailableTables = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dynamicAvailableTables = widget.restaurant.availableTables; // Fallback
          _isLoading = false;
        });
      }
    }
  }

  int get effectiveAvailableTables {
    return _dynamicAvailableTables ?? widget.restaurant.availableTables;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con logo y status
                Row(
                  children: [
                    // Logo del restaurante
                    _buildRestaurantLogo(),
                    
                    const SizedBox(width: 16),
                    
                    // Info principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.restaurant.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    _buildStatusBadge(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Rating y dirección
                Row(
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.restaurant.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.restaurant.totalReviews})',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Dirección
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF64748B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.restaurant.address,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Footer con mesas disponibles y botón
                Row(
                  children: [
                    // Info de mesas
                    Expanded(
                      child: _buildTableInfo(),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Botón de acción
                    _buildActionButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.restaurant.primaryColorValue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.restaurant.primaryColorValue.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: widget.restaurant.logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.restaurant.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildLogoPlaceholder();
                },
              ),
            )
          : _buildLogoPlaceholder(),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Text(
        widget.restaurant.logoText,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: widget.restaurant.primaryColorValue,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.restaurant.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.restaurant.statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.restaurant.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.restaurant.statusText,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: widget.restaurant.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableInfo() {
    if (!widget.restaurant.isOpen) {
      return Row(
        children: [
          Icon(
            Icons.schedule,
            color: const Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Cerrado',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      );
    }

    if (effectiveAvailableTables > 0) {
      return Row(
        children: [
          Icon(
            Icons.restaurant,
            color: const Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${effectiveAvailableTables} mesas disponibles',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.queue,
          color: const Color(0xFFF59E0B),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'Cola virtual disponible',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (!widget.restaurant.isOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Cerrado',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.restaurant.primaryColorValue,
            widget.restaurant.primaryColorValue.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.restaurant.primaryColorValue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            effectiveAvailableTables > 0 ? Icons.flash_on : Icons.queue,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            effectiveAvailableTables > 0 ? 'MesaYa!' : 'Cola Virtual',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}