import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../models/restaurant.dart';
import '../../services/reservation_service.dart';
import '../../widgets/public_reviews_section.dart';

// PANTALLA UNIVERSAL - TODAS LAS FUNCIONES DE SODITA PARA CUALQUIER RESTAURANTE
class UniversalRestaurantScreen extends StatefulWidget {
  final Restaurant restaurant;
  
  const UniversalRestaurantScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<UniversalRestaurantScreen> createState() => _UniversalRestaurantScreenState();
}

class _UniversalRestaurantScreenState extends State<UniversalRestaurantScreen> {
  @override
  Widget build(BuildContext context) {
    return RestaurantClone(restaurant: widget.restaurant);
  }
}

// CLON EXACTO DE SODITA PERO PERSONALIZABLE
class RestaurantClone extends StatefulWidget {
  final Restaurant restaurant;
  
  const RestaurantClone({super.key, required this.restaurant});

  @override
  State<RestaurantClone> createState() => _RestaurantCloneState();
}

class _RestaurantCloneState extends State<RestaurantClone> with TickerProviderStateMixin {
  // EXACTAMENTE LAS MISMAS VARIABLES QUE SODITA
  final PageController _pageController = PageController();
  bool _showWelcomeMessage = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ocultar mensaje de bienvenida después de 3 segundos
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.restaurant.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // MISMOS COLORES QUE SODITA
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFFD0029),
          onSurface: const Color(0xFF1C1B1F),
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA10319),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1C1B1F),
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1C1B1F),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: _buildRestaurantHome(),
    );
  }

  Widget _buildRestaurantHome() {
    return Scaffold(
      body: Stack(
        children: [
          // MISMO CONTENIDO QUE SODITA PERO PERSONALIZADO
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              _buildWelcomeScreen(), // Pantalla de bienvenida personalizada
              _buildMainContent(),   // Contenido principal igual a Sodita
              _buildAdminScreen(),   // Admin del restaurante
            ],
          ),
          
          // MENSAJE DE BIENVENIDA PERSONALIZADO
          if (_showWelcomeMessage)
            _buildWelcomeMessage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // LOGO PERSONALIZADO DEL RESTAURANTE
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: widget.restaurant.primaryColorValue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.restaurant.primaryColorValue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: widget.restaurant.logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        widget.restaurant.logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.white,
                    ),
            ),
            
            const SizedBox(height: 40),
            
            // NOMBRE DEL RESTAURANTE
            Text(
              widget.restaurant.name,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1B1F),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // DESCRIPCIÓN DEL RESTAURANTE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.restaurant.description,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RestaurantReservationSystem(restaurant: widget.restaurant);
  }

  Widget _buildAdminScreen() {
    // ADMIN CLONADO DE SODITA PERO PERSONALIZADO
    return const Center(
      child: Text('Panel de administración del restaurante'),
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant,
                size: 60,
                color: widget.restaurant.primaryColorValue,
              ),
              const SizedBox(height: 20),
              Text(
                '¡Bienvenido a ${widget.restaurant.name}!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1B1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.restaurant.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Mesas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      ],
    );
  }
}

// SISTEMA DE RESERVAS - CLON EXACTO DE SODITA PARA OTROS RESTAURANTES
class RestaurantReservationSystem extends StatefulWidget {
  final Restaurant restaurant;
  
  const RestaurantReservationSystem({super.key, required this.restaurant});

  @override
  State<RestaurantReservationSystem> createState() => _RestaurantReservationSystemState();
}

class _RestaurantReservationSystemState extends State<RestaurantReservationSystem> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int partySize = 2;
  int? selectedTableNumber;
  String? selectedTableId;
  String? lastPhoneNumber;
  
  List<Map<String, dynamic>> availableTables = [];
  List<String> occupiedTableIds = [];
  List<String> reservedTableIds = [];
  bool isLoadingTables = true;
  
  Timer? _autoUpdateTimer;
  Map<String, dynamic>? _cachedActiveReservation;
  Timer? _reservationCacheTimer;
  
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _startAutoUpdate();
    _loadActiveReservationCache();
    _startReservationCacheTimer();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    _reservationCacheTimer?.cancel();
    super.dispose();
  }

  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processExpiredReservationsAndLoadTables();
    });
  }

  Future<void> _processExpiredReservationsAndLoadTables() async {
    if (!mounted) return;
    
    try {
      final releasedTables = await ReservationService.processExpiredReservations();
      
      if (releasedTables.isNotEmpty) {
        final isRestaurantFull = await ReservationService.isRestaurantFull();
        
        for (var releasedTable in releasedTables) {
          if (isRestaurantFull) {
            _showTableReleasedAlert(releasedTable);
          }
        }
      }
      
      _loadTables();
    } catch (e) {
      _loadTables();
    }
  }

  Future<void> _loadTables() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingTables = true;
    });
    
    try {
      final timeString = selectedTime != null 
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;
      
      final results = await Future.wait([
        ReservationService.getMesas().timeout(const Duration(seconds: 5)),
        ReservationService.getCurrentlyOccupiedTables(date: selectedDate).timeout(const Duration(seconds: 5)),
        timeString != null 
            ? ReservationService.getOccupiedTables(date: selectedDate, time: timeString).timeout(const Duration(seconds: 5))
            : ReservationService.getAllReservedTablesForDay(date: selectedDate).timeout(const Duration(seconds: 5)),
      ]);
      
      final tables = results[0] as List<Map<String, dynamic>>;
      final occupied = results[1] as List<String>;
      final reserved = results[2] as List<String>;
      
      if (!mounted) return;
      
      setState(() {
        availableTables = tables.isNotEmpty ? tables : _getFallbackTables();
        occupiedTableIds = occupied;
        reservedTableIds = reserved.where((id) => !occupied.contains(id)).toList();
        isLoadingTables = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        availableTables = _getFallbackTables();
        occupiedTableIds = [];
        reservedTableIds = [];
        isLoadingTables = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackTables() {
    final totalTables = widget.restaurant.totalTables;
    List<Map<String, dynamic>> tables = [];
    
    for (int i = 1; i <= totalTables; i++) {
      int capacity;
      String location;
      
      if (i <= (totalTables * 0.4)) {
        capacity = 2;
      } else if (i <= (totalTables * 0.7)) {
        capacity = 4;
      } else {
        capacity = 6;
      }
      
      if (i <= (totalTables * 0.5)) {
        location = 'Interior';
      } else {
        location = 'Terraza';
      }
      
      tables.add({
        'id': i.toString(),
        'numero': i,
        'capacidad': capacity,
        'ubicacion': location,
        'activa': true
      });
    }
    
    return tables;
  }

  String _getTableImage(int tableNumber) {
    final images = {
      1: 'https://picsum.photos/400/300?random=1',
      2: 'https://picsum.photos/400/300?random=2',
      3: 'https://picsum.photos/400/300?random=3',
      4: 'https://picsum.photos/400/300?random=4',
      5: 'https://picsum.photos/400/300?random=5',
      6: 'https://picsum.photos/400/300?random=6',
      7: 'https://picsum.photos/400/300?random=7',
      8: 'https://picsum.photos/400/300?random=8',
      9: 'https://picsum.photos/400/300?random=9',
      10: 'https://picsum.photos/400/300?random=10',
    };
    
    return images[tableNumber] ?? 'https://picsum.photos/400/300?random=default';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // AppBar EXACTO como SODITA
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1C1B1F),
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Reservá tu mesa',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => _showLanguageSelector(context),
                tooltip: 'Idioma',
              ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  // TODO: Navegar al admin del restaurante
                },
                tooltip: 'Panel de Administración',
              ),
            ],
            expandedHeight: 100,
          ),
          
          // Contenido EXACTO como SODITA
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildReviewsSection(),
                const SizedBox(height: 32),
                _buildTableInfoNotice(),
                const SizedBox(height: 16),
                _buildRestaurantCard(),
                const SizedBox(height: 32),
                _buildDateTimeSelector(),
                const SizedBox(height: 24),
                _buildPartySizeSelector(),
                const SizedBox(height: 24),
                _buildTableSectionHeader(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          
          _buildTableGrid(),
          
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                const SizedBox(height: 24),
                _buildReserveButton(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo del restaurante - EXACTO como SODITA
          Container(
            height: 250,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Colors.white,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: widget.restaurant.logoUrl.isNotEmpty
                    ? Image.network(
                        widget.restaurant.logoUrl,
                        height: 500,
                        width: 500,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackLogo();
                        },
                      )
                    : _buildFallbackLogo(),
              ),
            ),
          ),
          
          // Info del restaurante
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.restaurant.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                _buildRestaurantStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: widget.restaurant.primaryColorValue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.restaurant,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.restaurant.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1B1F),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRestaurantStats() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.table_restaurant,
          label: '${widget.restaurant.totalTables} mesas',
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: Icons.star,
          label: widget.restaurant.rating.toStringAsFixed(1),
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: widget.restaurant.isOpen ? Icons.check_circle : Icons.schedule,
          label: widget.restaurant.isOpen ? 'Abierto' : 'Cerrado',
          color: widget.restaurant.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // RESTO DE WIDGETS CLONADOS EXACTAMENTE DE SODITA
  Widget _buildReviewsSection() {
    return const PublicReviewsSection();
  }

  Widget _buildTableInfoNotice() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.1),
            const Color(0xFF3B82F6).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Información de Mesas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Elegí la mesa que más te guste para disfrutar la experiencia en ${widget.restaurant.name}. Todas nuestras mesas están cuidadosamente ubicadas para tu comodidad.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📍 Ambiente cálido y acogedor',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Cuándo querés venir?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateSelector()),
              const SizedBox(width: 16),
              Expanded(child: _buildTimeSelector()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
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
                    'Fecha',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1B1F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
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
                    'Hora',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    selectedTime?.format(context) ?? 'Seleccionar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selectedTime != null ? const Color(0xFF1C1B1F) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySizeSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👥 Para cuántas personas?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildPartySizeButton(Icons.remove, () {
                if (partySize > 1) {
                  setState(() => partySize--);
                }
              }),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                ),
                child: Text(
                  partySize.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildPartySizeButton(Icons.add, () {
                if (partySize < 10) {
                  setState(() => partySize++);
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartySizeButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTableSectionHeader() {
    return Row(
      children: [
        Text(
          '🍽️ Elegí tu mesa',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        const Spacer(),
        if (isLoadingTables)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildTableGrid() {
    if (isLoadingTables) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final table = availableTables[index];
            final isOccupied = occupiedTableIds.contains(table['id'].toString());
            final isReserved = reservedTableIds.contains(table['id'].toString());
            final isSelected = selectedTableId == table['id'].toString();
            
            return _buildTableCard(table, isOccupied, isReserved, isSelected);
          },
          childCount: availableTables.length,
        ),
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table, bool isOccupied, bool isReserved, bool isSelected) {
    final isAvailable = !isOccupied && !isReserved;
    
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() {
          selectedTableId = table['id'].toString();
          selectedTableNumber = table['numero'];
        });
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2563EB)
                : isOccupied 
                    ? const Color(0xFFEF4444)
                    : isReserved 
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE5E7EB),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de la mesa
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_getTableImage(table['numero'])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Número de mesa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mesa ${table['numero']}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1B1F),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOccupied 
                          ? const Color(0xFFEF4444)
                          : isReserved 
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOccupied 
                          ? 'Ocupada'
                          : isReserved 
                              ? 'Reservada'
                              : 'Libre',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Detalles de la mesa
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table['capacidad']} personas',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      table['ubicacion'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Indicador de selección
              if (isSelected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Seleccionada',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
  }

  Widget _buildReserveButton() {
    final canReserve = selectedTableId != null && selectedTime != null;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: canReserve ? [
          BoxShadow(
            color: const Color(0xFFA10319).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: canReserve ? _handleReservation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA10319),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF9CA3AF),
        ),
        child: Text(
          canReserve 
              ? 'Reservar Mesa $selectedTableNumber para $partySize ${partySize == 1 ? "persona" : "personas"}'
              : 'Selecciona mesa y hora para continuar',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // MÉTODOS DE FUNCIONALIDAD
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _loadTables();
    }
  }

  void _selectTime() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleccionar Horario',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 20),
            
            // Grid de horarios
            SizedBox(
              height: 400,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: _getAvailableTimes().length,
                itemBuilder: (context, index) {
                  final time = _getAvailableTimes()[index];
                  final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  final isLunchTime = time.hour >= 12 && time.hour <= 15;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = time;
                      });
                      Navigator.pop(context);
                      _loadTables();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeString,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1B1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLunchTime ? '🍽️ Almuerzo' : '🌙 Cena',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TimeOfDay> _getAvailableTimes() {
    List<TimeOfDay> times = [];
    
    // Horarios de almuerzo (12:00 - 15:30)
    for (int hour = 12; hour <= 15; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 15 && minute > 30) break;
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }
    
    // Horarios de cena (19:00 - 22:30)
    for (int hour = 19; hour <= 22; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 22 && minute > 30) break;
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }
    
    return times;
  }

  void _showLanguageSelector(BuildContext context) {
    // Implementar selector de idioma
  }

  void _handleReservation() {
    // Implementar lógica de reserva
    print('Reservando mesa $selectedTableNumber para $partySize personas en ${widget.restaurant.name}');
  }

  void _showTableReleasedAlert(Map<String, dynamic> releasedTable) {
    // Implementar alerta
  }

  void _loadActiveReservationCache() {
    // Implementar cache
  }

  void _startReservationCacheTimer() {
    // Implementar timer
  }
}