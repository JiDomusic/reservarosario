import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_card.dart';
import 'restaurant_login_screen.dart';
import 'restaurant_registration_screen.dart';
import '../supabase_config.dart';
import 'sodita_original_app.dart';
import 'restaurants/universal_restaurant_screen.dart';

class GastronomicaHomeScreen extends StatefulWidget {
  const GastronomicaHomeScreen({super.key});

  @override
  State<GastronomicaHomeScreen> createState() => _GastronomicaHomeScreenState();
}

class _GastronomicaHomeScreenState extends State<GastronomicaHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  List<Restaurant> restaurants = [];
  List<Restaurant> filteredRestaurants = [];
  String searchQuery = '';
  String selectedFilter = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    ));
    
    _loadRestaurants();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() => isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // SOLO SODITA - SIN SIMULACIONES NI OTROS RESTAURANTES
    restaurants = [
      Restaurant(
        id: 'sodita',
        name: 'SODITA',
        description: 'El restaurante original - Experiencia premium completa.\n\n🏢 LAYOUT FÍSICO:\n• PLANTA ALTA únicamente\n• 10 mesas disponibles para reservas online\n• Capacidad: 2 a 50 personas\n• Mesas bajas tradicionales (2-4 personas)\n• Mesas altas de barra (2 personas)\n• Área de living con sofás (4-6 personas)\n• Distribución: Solo interior (planta alta)\n\n📍 Reservas SOLO para la planta alta del restaurante. La planta baja NO está disponible para reservas online.',
        address: 'Laprida 1301, Rosario 2000',
        phone: '+54 341 000-0000',
        email: 'admin@sodita.com',
        totalTables: 10,
        rating: 4.9,
        totalReviews: 350,
        availableTables: 5,
        pendingReservations: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    _applyFilters();
    
    setState(() => isLoading = false);
    _headerAnimationController.forward();
  }

  void _applyFilters() {
    filteredRestaurants = restaurants.where((restaurant) {
      bool matchesSearch = searchQuery.isEmpty ||
          restaurant.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          restaurant.description.toLowerCase().contains(searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      switch (selectedFilter) {
        case 'open':
          matchesFilter = restaurant.isOpen && restaurant.isActive;
          break;
        case 'available':
          matchesFilter = restaurant.isOpen && 
                         restaurant.isActive && 
                         restaurant.availableTables > 0;
          break;
        case 'all':
        default:
          matchesFilter = restaurant.isActive;
      }
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // SODITA siempre primero, resto por rating y disponibilidad
    filteredRestaurants.sort((a, b) {
      if (a.id == 'sodita') return -1;
      if (b.id == 'sodita') return 1;
      if (a.isOpen && !b.isOpen) return -1;
      if (!a.isOpen && b.isOpen) return 1;
      if (a.availableTables > 0 && b.availableTables == 0) return -1;
      if (a.availableTables == 0 && b.availableTables > 0) return 1;
      return b.rating.compareTo(a.rating);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading ? _buildLoadingScreen() : _buildMainContent(),
      floatingActionButton: _buildAdminLoginFAB(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF86704),
                  const Color(0xFFFF8A50),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF86704).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'GASTRONÓMICA ROSARIO',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de reservas y puntuación en Rosario',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF86704)),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando restaurantes...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildSliverAppBar(),
        ];
      },
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _buildRestaurantList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8FAFC),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _headerAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _headerSlideAnimation.value),
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo principal
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF86704),
                                        const Color(0xFFFF8A50),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF86704).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GASTRONÓMICA',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'ROSARIO',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF86704),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Sistema de reservas y puntuación en Rosario',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Stats container
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF86704).withValues(alpha: 0.1),
                                    const Color(0xFF10B981).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF86704).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    color: const Color(0xFFF86704),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${filteredRestaurants.length} restaurantes en la plataforma',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          '${filteredRestaurants.where((r) => r.isOpen && r.availableTables > 0).length} con mesas disponibles ahora',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar restaurantes...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filtros
          Row(
            children: [
              Expanded(child: _buildFilterChip('Todos', 'all', Icons.restaurant_menu)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Abiertos', 'open', Icons.schedule)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Disponibles', 'available', Icons.check_circle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF86704) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFF86704) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantList() {
    if (filteredRestaurants.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = filteredRestaurants[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () => _onRestaurantTap(restaurant),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF86704).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: Color(0xFFF86704),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron restaurantes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar los filtros o la búsqueda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedFilter = 'all';
                  _applyFilters();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF86704),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Mostrar todos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminLoginFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: "register",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RestaurantRegistrationScreen()),
            );
          },
          backgroundColor: const Color(0xFFF86704),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.restaurant_menu),
          label: Text(
            'Registrar Restaurante',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: "admin",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RestaurantLoginScreen()),
            );
          },
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.admin_panel_settings),
          label: Text(
            'Admin',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _onRestaurantTap(Restaurant restaurant) {
    print('🔍 Navegando a: ${restaurant.name}');
    
    if (restaurant.id == 'sodita') {
      // SODITA va a su aplicación ORIGINAL con base de datos REAL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SoditaOriginalApp(),
        ),
      );
    } else {
      // Otros restaurantes usan el clon
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniversalRestaurantScreen(restaurant: restaurant),
        ),
      );
    }
  }
}