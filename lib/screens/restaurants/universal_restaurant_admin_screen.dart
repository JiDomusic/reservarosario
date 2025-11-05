import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_auth_service.dart';

// ADMIN UNIVERSAL - EXACTAMENTE IGUAL AL ADMIN DE SODITA PARA CUALQUIER RESTAURANTE
class UniversalRestaurantAdminScreen extends StatefulWidget {
  const UniversalRestaurantAdminScreen({super.key});

  @override
  State<UniversalRestaurantAdminScreen> createState() => _UniversalRestaurantAdminScreenState();
}

class _UniversalRestaurantAdminScreenState extends State<UniversalRestaurantAdminScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _logoAnimationController;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoScaleAnimation;
  
  // Estado de datos - IGUAL QUE SODITA
  List<Map<String, dynamic>> reservations = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  int totalReservations = 0;
  int pendingReservations = 0;
  int confirmedReservations = 0;
  double averageRating = 0.0;
  int totalRatings = 0;

  Restaurant? get currentRestaurant => context.read<RestaurantAuthService>().currentRestaurant;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 4, vsync: this);
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _logoRotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.bounceOut,
    ));
    
    _logoAnimationController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    await Future.wait([
      _loadReservations(),
      _loadReviews(),
    ]);
    
    setState(() => isLoading = false);
  }

  Future<void> _loadReservations() async {
    // Simular carga de reservas específicas del restaurante
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted && currentRestaurant != null) {
      setState(() {
        // Datos demo específicos del restaurante
        reservations = _getDemoReservations();
        totalReservations = reservations.length;
        pendingReservations = reservations.where((r) => r['status'] == 'pending').length;
        confirmedReservations = reservations.where((r) => r['status'] == 'confirmed').length;
      });
    }
  }

  Future<void> _loadReviews() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted && currentRestaurant != null) {
      setState(() {
        reviews = _getDemoReviews();
        totalRatings = reviews.length;
        if (reviews.isNotEmpty) {
          averageRating = reviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) / reviews.length;
        }
      });
    }
  }

  List<Map<String, dynamic>> _getDemoReservations() {
    if (currentRestaurant == null) return [];
    
    // Generar reservas demo específicas para cada restaurante
    return List.generate(5, (index) {
      return {
        'id': 'res_${currentRestaurant!.id}_$index',
        'customer_name': ['Juan Pérez', 'María García', 'Carlos López', 'Ana Martínez', 'Luis Rodríguez'][index],
        'customer_phone': '+54 341 123-${1000 + index}',
        'customer_email': 'cliente$index@email.com',
        'party_size': [2, 4, 6, 3, 5][index],
        'date': DateTime.now().add(Duration(days: index)).toString().split(' ')[0],
        'time': ['19:00', '20:00', '21:00', '19:30', '20:30'][index],
        'status': ['pending', 'confirmed', 'pending', 'confirmed', 'pending'][index],
        'notes': index == 0 ? 'Mesa cerca de la ventana' : '',
        'created_at': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
      };
    });
  }

  List<Map<String, dynamic>> _getDemoReviews() {
    if (currentRestaurant == null) return [];
    
    return List.generate(3, (index) {
      return {
        'id': 'rev_${currentRestaurant!.id}_$index',
        'customer_name': ['Pedro Gómez', 'Laura Silva', 'Diego Torres'][index],
        'rating': [5.0, 4.5, 4.8][index],
        'comment': [
          'Excelente servicio y comida deliciosa en ${currentRestaurant!.name}',
          'Muy buen ambiente, definitivamente volveré',
          'Recomiendo totalmente este lugar'
        ][index],
        'created_at': DateTime.now().subtract(Duration(days: index + 1)).toIso8601String(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentRestaurant == null) {
      return _buildNotLoggedIn();
    }

    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReservationsTab(),
            _buildReviewsTab(),
            _buildAnalyticsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomTabBar(),
    );
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: const Color(0xFFF86704),
              ),
              const SizedBox(height: 24),
              Text(
                'Acceso no autorizado',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Necesitas iniciar sesión como administrador de restaurante',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF86704),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Volver al Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _logoRotationAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: currentRestaurant!.primaryColorValue, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          currentRestaurant!.logoText,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: currentRestaurant!.primaryColorValue,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              currentRestaurant!.name,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Panel de Administración',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF86704)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      actions: [
        IconButton(
          onPressed: () {
            context.read<RestaurantAuthService>().logout();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF8FAFC),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: currentRestaurant!.primaryColorValue, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  currentRestaurant!.logoText,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: currentRestaurant!.primaryColorValue,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentRestaurant!.name,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Panel de Administración',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildQuickStats(),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildRestaurantStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.restaurant_menu,
          value: '$pendingReservations',
          label: 'Pendientes',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.star,
          value: averageRating.toStringAsFixed(1),
          label: 'Rating',
          color: currentRestaurant!.secondaryColorValue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantStatus() {
    final isOpen = currentRestaurant!.isOpen;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
            currentRestaurant!.secondaryColorValue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? currentRestaurant!.secondaryColorValue : const Color(0xFFF44336),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOpen ? currentRestaurant!.secondaryColorValue : const Color(0xFFF44336),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? '🟢 RESTAURANTE ABIERTO' : '🔴 RESTAURANTE CERRADO',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? currentRestaurant!.secondaryColorValue : const Color(0xFFF44336),
                  ),
                ),
                Text(
                  '$totalReservations reservas totales • $confirmedReservations confirmadas',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (value) {
              context.read<RestaurantAuthService>().toggleRestaurantStatus();
            },
            activeColor: currentRestaurant!.secondaryColorValue,
          ),
        ],
      ),
    );
  }

  // TABS EXACTAMENTE IGUALES AL ADMIN DE SODITA

  Widget _buildReservationsTab() {
    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentRestaurant!.primaryColorValue,
                    currentRestaurant!.primaryColorValue.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🍽️ Gestión de Reservas',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Administrá las reservas de ${currentRestaurant!.name}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (reservations.isEmpty)
              _buildEmptyReservations()
            else
              _buildReservationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReservations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: const Color(0xFF64748B)),
          const SizedBox(height: 16),
          Text(
            'No hay reservas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las nuevas reservas aparecerán aquí automáticamente.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status'] ?? 'pending';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'confirmed':
        statusColor = currentRestaurant!.secondaryColorValue;
        statusText = 'CONFIRMADA';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusText = 'CANCELADA';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'PENDIENTE';
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['customer_name'] ?? 'Cliente',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📅 ${reservation['date']}', style: GoogleFonts.inter(fontSize: 14)),
                          Text('🕐 ${reservation['time']}', style: GoogleFonts.inter(fontSize: 14)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('👥 ${reservation['party_size']} personas', style: GoogleFonts.inter(fontSize: 14)),
                          Text('📞 ${reservation['customer_phone']}', style: GoogleFonts.inter(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmReservation(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentRestaurant!.secondaryColorValue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _cancelReservation(reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  currentRestaurant!.secondaryColorValue,
                  currentRestaurant!.secondaryColorValue.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⭐ Reseñas y Calificaciones',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Promedio: ${averageRating.toStringAsFixed(1)} • $totalRatings reseñas',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (reviews.isEmpty)
            _buildEmptyReviews()
          else
            _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.star_border, size: 64, color: const Color(0xFF64748B)),
          const SizedBox(height: 16),
          Text(
            'Aún no hay reseñas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las reseñas de los clientes aparecerán aquí.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentRestaurant!.secondaryColorValue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.person, color: currentRestaurant!.secondaryColorValue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['customer_name'] ?? 'Cliente Anónimo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review['rating'].floor() ? Icons.star : Icons.star_border,
                              color: const Color(0xFFF59E0B),
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    review['rating'].toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: currentRestaurant!.secondaryColorValue,
                    ),
                  ),
                ],
              ),
              
              if (review['comment'] != null && review['comment'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review['comment'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Analytics ${currentRestaurant!.name}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Métricas y estadísticas del restaurante',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMetricCard('Total Reservas', '$totalReservations', Icons.restaurant_menu, currentRestaurant!.primaryColorValue),
              _buildMetricCard('Rating Promedio', averageRating.toStringAsFixed(1), Icons.star, currentRestaurant!.secondaryColorValue),
              _buildMetricCard('Confirmadas', '$confirmedReservations', Icons.check_circle, const Color(0xFF2196F3)),
              _buildMetricCard('Pendientes', '$pendingReservations', Icons.pending, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚙️ Configuración',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Gestión de ${currentRestaurant!.name}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingOption(
            icon: Icons.restaurant,
            title: 'Información del Restaurante',
            subtitle: currentRestaurant!.description,
            onTap: () {},
          ),
          _buildSettingOption(
            icon: Icons.table_restaurant,
            title: 'Mesas',
            subtitle: '${currentRestaurant!.totalTables} mesas configuradas',
            onTap: () {},
          ),
          _buildSettingOption(
            icon: Icons.schedule,
            title: 'Horarios',
            subtitle: 'Configurar horarios de atención',
            onTap: () {},
          ),
          _buildSettingOption(
            icon: Icons.color_lens,
            title: 'Personalización',
            subtitle: 'Logo y colores del restaurante',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: currentRestaurant!.primaryColorValue, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: const Color(0xFF64748B),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: currentRestaurant!.primaryColorValue,
        indicatorWeight: 3,
        labelColor: currentRestaurant!.primaryColorValue,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(icon: Icon(Icons.restaurant_menu), text: 'Reservas'),
          Tab(icon: Icon(Icons.star), text: 'Reseñas'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          Tab(icon: Icon(Icons.settings), text: 'Config'),
        ],
      ),
    );
  }

  void _confirmReservation(Map<String, dynamic> reservation) {
    setState(() {
      reservation['status'] = 'confirmed';
      confirmedReservations++;
      pendingReservations--;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserva confirmada para ${reservation['customer_name']}'),
        backgroundColor: currentRestaurant!.secondaryColorValue,
      ),
    );
  }

  void _cancelReservation(Map<String, dynamic> reservation) {
    setState(() {
      reservation['status'] = 'cancelled';
      pendingReservations--;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserva cancelada para ${reservation['customer_name']}'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
}