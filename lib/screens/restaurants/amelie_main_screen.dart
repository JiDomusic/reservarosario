import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/queue_service.dart';
import '../../services/analytics_service.dart';

// PANTALLA PRINCIPAL AMELIE PETIT CAFE - FUNCIONALIDADES EXACTAS A SODITA
class AmelieMainScreen extends StatefulWidget {
  const AmelieMainScreen({super.key});

  @override
  State<AmelieMainScreen> createState() => _AmelieMainScreenState();
}

class _AmelieMainScreenState extends State<AmelieMainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Estado de usuario
  Map<String, dynamic>? currentUser;
  bool isUserInQueue = false;
  Map<String, dynamic>? queueStatus;
  List<Map<String, dynamic>> availableTablesNow = [];
  
  // Métricas en tiempo real
  Map<String, dynamic> realTimeMetrics = {};
  
  // Notificaciones
  List<Map<String, dynamic>> notifications = [];
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAvailableTablesNow(),
      _loadRealTimeMetrics(),
    ]);
  }

  void _startRealTimeUpdates() {
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        _loadRealTimeMetrics();
        _loadAvailableTablesNow();
      }
    });
  }

  Future<void> _loadAvailableTablesNow() async {
    try {
      final tables = await QueueService.getAvailableTablesNow();
      if (mounted) {
        setState(() {
          availableTablesNow = tables;
        });
      }
    } catch (e) {
      debugPrint('Error loading available tables: $e');
    }
  }

  Future<void> _loadRealTimeMetrics() async {
    try {
      final metrics = await AnalyticsService.getRealTimeMetrics();
      if (mounted) {
        setState(() {
          realTimeMetrics = metrics;
        });
      }
    } catch (e) {
      debugPrint('Error loading metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _buildMesaYaTab(),
            _buildReservasTab(),
            _buildColaTab(),
            _buildMetricasTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomTabBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
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
                      _buildAmelieLogo(),
                      const Spacer(),
                      _buildQuickMetrics(),
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

  Widget _buildAmelieLogo() {
    return Container(
      width: 120,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF86704).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF86704), width: 2),
      ),
      child: Center(
        child: Text(
          'AMELIE PETIT CAFE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF86704),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetrics() {
    final mesas = realTimeMetrics['mesas'] ?? {};
    final reservas = realTimeMetrics['reservas'] ?? {};
    
    return Row(
      children: [
        _buildMetricCard(
          icon: Icons.restaurant,
          value: '${mesas['ocupadas_ahora'] ?? 0}/${mesas['total_mesas'] ?? 12}',
          label: 'Ocupadas',
          color: const Color(0xFFF86704),
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          icon: Icons.people,
          value: '${reservas['total_comensales'] ?? 0}',
          label: 'Comensales',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
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
    final availableCount = availableTablesNow.length;
    final isOpen = true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF86704).withValues(alpha: 0.1),
            const Color(0xFF10B981).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF44336),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF44336),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? '🟢 AMELIE PETIT CAFE ABIERTO' : '🔴 AMELIE PETIT CAFE CERRADO',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF44336),
                  ),
                ),
                Text(
                  availableCount > 0 
                      ? '$availableCount mesas disponibles para MesaYa!'
                      : 'Sin mesas disponibles - Podés unirte a la cola virtual',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // EL RESTO DE LOS MÉTODOS SON EXACTAMENTE IGUALES A SODITA
  Widget _buildMesaYaTab() {
    return RefreshIndicator(
      onRefresh: _loadAvailableTablesNow,
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
                    const Color(0xFFF86704),
                    const Color(0xFFFF8A50),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF86704).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚡ MesaYa!',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Mesas disponibles AHORA MISMO',
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
            if (availableTablesNow.isEmpty)
              _buildNoTablesAvailable()
            else
              _buildAvailableTablesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTablesAvailable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            'Sin mesas disponibles ahora',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las mesas están ocupadas o reservadas. Podés unirte a nuestra cola virtual.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF86704),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.queue),
            label: const Text('Unirme a la Cola Virtual'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTablesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🍽️ Mesas Disponibles (${availableTablesNow.length})',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableTablesNow.length,
          itemBuilder: (context, index) {
            final table = availableTablesNow[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.restaurant, color: const Color(0xFF10B981), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mesa ${table['numero']}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'DISPONIBLE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          table['ubicacion'] ?? '',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Hasta ${table['capacidad']} personas',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showMesaYaConfirmation(table),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF86704),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, size: 16),
                        Text('MesaYa!', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReservasTab() {
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
                Icon(Icons.event, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Reservas Programadas', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Reservá con anticipación', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva Reserva', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(height: 16),
                Text('Para usar esta función, necesitás validar tu usuario primero.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función en desarrollo - Usar MesaYa! mientras tanto')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
                  child: const Text('Hacer Reserva Programada'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColaTab() {
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
                Icon(Icons.queue, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔄 Cola Virtual', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Esperá tu turno sin estar físicamente', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: const Color(0xFF9C27B0)),
                const SizedBox(height: 16),
                Text('Cola Virtual Disponible', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Cuando no haya mesas disponibles, podrás unirte a nuestra cola virtual inteligente.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: availableTablesNow.isNotEmpty ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cola virtual en desarrollo')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), foregroundColor: Colors.white),
                  child: const Text('Unirme a la Cola'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasTab() {
    return RefreshIndicator(
      onRefresh: _loadRealTimeMetrics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF00BCD4), const Color(0xFF4DD0E1)]),
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
                        Text('📊 Analytics AMELIE', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Métricas en tiempo real', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Métricas en desarrollo', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFF86704),
        indicatorWeight: 3,
        labelColor: const Color(0xFFF86704),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: [
          Tab(icon: Icon(Icons.flash_on), text: 'MesaYa!'),
          Tab(icon: Icon(Icons.event), text: 'Reservas'),
          Tab(icon: Icon(Icons.queue), text: 'Cola'),
          Tab(icon: Icon(Icons.analytics), text: 'Métricas'),
        ],
      ),
    );
  }

  void _showMesaYaConfirmation(Map<String, dynamic> table) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ MesaYa! para Mesa ${table['numero']} en AMELIE PETIT CAFE'),
        backgroundColor: const Color(0xFFF86704),
      ),
    );
  }
}