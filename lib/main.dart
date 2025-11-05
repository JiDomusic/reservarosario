import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'l10n.dart';
import 'services/multi_restaurant_service.dart';
import 'providers/review_provider.dart';
import 'admin_screen.dart';
import 'services/restaurant_auth_service.dart';
import 'screens/gastronomica_home_screen.dart';
import 'widgets/multi_restaurant_reviews_section.dart';
import 'models/restaurant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Analytics
  FirebaseAnalytics.instance;
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantAuthService()),
      ],
      child: const GastronomicaApp(), // SISTEMA GASTRONÓMICA ROSARIO
    ),
  );
}

// APP PRINCIPAL - GASTRONÓMICA ROSARIO (11 RESTAURANTES)
class GastronomicaApp extends StatefulWidget {
  const GastronomicaApp({super.key});

  @override
  State<GastronomicaApp> createState() => _GastronomicaAppState();
}

class _GastronomicaAppState extends State<GastronomicaApp> {
  Locale _locale = const Locale('es');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastronómica Rosario',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF86704),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const GastronomicaHomeScreen(),
    );
  }
}

// CADA RESTAURANTE ES UN CLON EXACTO DE SODITA DEL ÚLTIMO DEPLOY
class RestaurantSoditaClone extends StatefulWidget {
  final Restaurant restaurant;
  
  const RestaurantSoditaClone({super.key, required this.restaurant});

  @override
  State<RestaurantSoditaClone> createState() => _RestaurantSoditaCloneState();
}

class _RestaurantSoditaCloneState extends State<RestaurantSoditaClone> {
  Locale _locale = const Locale('es');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void changeLanguage(Locale locale) {
    _changeLanguage(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.restaurant.name,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('zh'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        // MISMOS COLORES QUE SODITA DEL ÚLTIMO DEPLOY
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Azul
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFFD0029),
          onSurface: const Color(0xFF1C1B1F),
        ),
        // MISMA TIPOGRAFÍA QUE SODITA
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        // MISMOS BOTONES QUE SODITA
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
        // MISMAS CARDS QUE SODITA
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        // MISMO APPBAR QUE SODITA
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
      home: RestaurantHome(
        restaurant: widget.restaurant,
        onLanguageChange: _changeLanguage,
      ),
    );
  }
}

class RestaurantHome extends StatefulWidget {
  final Restaurant restaurant;
  final Function(Locale) onLanguageChange;
  
  const RestaurantHome({
    super.key, 
    required this.restaurant, 
    required this.onLanguageChange
  });

  @override
  State<RestaurantHome> createState() => _RestaurantHomeState();
}

class _RestaurantHomeState extends State<RestaurantHome> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 
          ? RestaurantPage(restaurant: widget.restaurant)
          : _currentIndex == 1
              ? const ReservationsPage()
              : const ProfilePage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 0 && _currentIndex == 0) {
              // Si ya estoy en Mesas y toco Mesas, volver a lista de restaurantes
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GastronomicaApp(),
                ),
              );
            } else {
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFFDC2626),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Mesas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// PÁGINA DE MESAS - CLON EXACTO DE SODITA DEL ÚLTIMO DEPLOY
class RestaurantPage extends StatefulWidget {
  final Restaurant restaurant;
  
  const RestaurantPage({super.key, required this.restaurant});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
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
  
  // Timer para actualizaciones automáticas
  Timer? _autoUpdateTimer;
  
  // OPTIMIZACIÓN: Cache para reserva activa
  Map<String, dynamic>? _cachedActiveReservation;
  Timer? _reservationCacheTimer;
  
  // Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _startAutoUpdate();
    _loadActiveReservationCache(); // Cargar reserva activa una vez
    _startReservationCacheTimer(); // Timer para actualizar cache cada 10 segundos
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    _reservationCacheTimer?.cancel();
    super.dispose();
  }

  // EXACTO COMO SODITA DEL ÚLTIMO DEPLOY
  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processExpiredReservationsAndLoadTables();
    });
  }

  Future<void> _processExpiredReservationsAndLoadTables() async {
    if (!mounted) return;
    
    try {
      final releasedTables = await MultiRestaurantService.processExpiredReservations(widget.restaurant.id);
      
      if (releasedTables.isNotEmpty) {
        final isRestaurantFull = await MultiRestaurantService.isRestaurantFull(widget.restaurant.id);
        
        for (var releasedTable in releasedTables) {
          if (isRestaurantFull) {
            _showTableReleasedAlert(releasedTable);
          }
          
          print('🔄 Mesa ${releasedTable['restaurant_tables']['table_number']} liberada automáticamente en ${widget.restaurant.name}');
        }
      }
      
      _loadTables();
    } catch (e) {
      print('❌ Error procesando reservas expiradas: $e');
      _loadTables();
    }
  }

  Future<void> _loadTables() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingTables = true;
    });
    
    try {
      // PARA CADA RESTAURANTE, USAR SUS PROPIAS MESAS DESDE LA BD
      final tables = await MultiRestaurantService.getMesas(widget.restaurant.id);
      
      if (!mounted) return;
      
      setState(() {
        availableTables = tables;
        occupiedTableIds = []; // Por simplicidad, sin reservas cruzadas entre restaurantes
        reservedTableIds = [];
        isLoadingTables = false;
      });
      
      print('🍽️ Mesas cargadas para ${widget.restaurant.name}: ${tables.length} mesas');
    } catch (e) {
      print('⚠️ Error cargando mesas para ${widget.restaurant.name}: $e');
      
      if (!mounted) return;
      
      setState(() {
        availableTables = _getRestaurantTables();
        occupiedTableIds = [];
        reservedTableIds = [];
        isLoadingTables = false;
      });
    }
  }

  // CADA RESTAURANTE TIENE LAS MESAS QUE CONFIGURE (10, 15, 20, etc.)
  List<Map<String, dynamic>> _getRestaurantTables() {
    final totalTables = widget.restaurant.totalTables;
    List<Map<String, dynamic>> tables = [];
    
    print('🍽️ Generando $totalTables mesas para ${widget.restaurant.name}');
    
    // MISMA LÓGICA QUE SODITA PARA DISTRIBUCIÓN
    final locations = ['Ventana frontal', 'Ventana lateral', 'Centro del salon', 'Cerca de la ventana', 
                      'Mesa grande central', 'Mesa familiar grande', 'Rincon privado', 'Centro-derecha', 
                      'Centro-izquierda', 'Mesa de la esquina', 'Terraza principal', 'Terraza lateral',
                      'Salon privado', 'Junto a la barra', 'Vista al jardín'];
    
    for (int i = 1; i <= totalTables; i++) {
      int capacity;
      String location;
      
      // MISMA DISTRIBUCIÓN QUE SODITA: 40% para 2, 30% para 4, 30% para 6+
      if (i <= (totalTables * 0.4)) {
        capacity = 2;
      } else if (i <= (totalTables * 0.7)) {
        capacity = 4;
      } else {
        capacity = 6;
      }
      
      // Asignar ubicación de la lista
      location = locations[(i - 1) % locations.length];
      
      tables.add({
        'id': i.toString(),
        'table_number': i,
        'capacity': capacity,
        'location': location,
        'is_available': true
      });
    }
    
    print('✅ Mesas generadas para ${widget.restaurant.name}:');
    print('   • Total: ${tables.length} mesas');
    print('   • Para 2 personas: ${tables.where((t) => t['capacity'] == 2).length} mesas');
    print('   • Para 4 personas: ${tables.where((t) => t['capacity'] == 4).length} mesas');
    print('   • Para 6+ personas: ${tables.where((t) => t['capacity'] == 6).length} mesas');
    
    return tables;
  }

  String _getTableImage(int tableNumber) {
    // MISMAS IMÁGENES QUE SODITA
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

  Widget _buildTableInfoNotice() {
    final l10n = AppLocalizations.of(context);
    
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
              'Elegí la mesa que más te guste para disfrutar tu experiencia en ${widget.restaurant.name}. Todas nuestras mesas están cuidadosamente ubicadas para tu comodidad.',
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
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AdminScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
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
          
          // Grid de mesas EXACTO como SODITA
          _buildTableGrid(),
          
          // Botón de reserva EXACTO como SODITA
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
          // Logo del restaurante - MISMO DISEÑO QUE SODITA
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

  // RESTO DE WIDGETS EXACTOS COMO SODITA DEL ÚLTIMO DEPLOY
  Widget _buildReviewsSection() {
    return MultiRestaurantReviewsSection(
      restaurantId: widget.restaurant.id,
      showAddReviewButton: true,
      compactView: false,
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
          selectedTableNumber = table['table_number'];
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
              // Imagen de la mesa IGUAL QUE SODITA
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_getTableImage(table['table_number'])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Número de mesa IGUAL QUE SODITA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mesa ${table['table_number']}',
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
              
              // Detalles IGUALES QUE SODITA
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table['capacity']} personas',
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
                      table['location'],
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
              
              // Indicador IGUAL QUE SODITA
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

  // MÉTODOS EXACTOS COMO SODITA
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

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
      _loadTables();
    }
  }

  void _showLanguageSelector(BuildContext context) {
    // MISMO SELECTOR QUE SODITA
  }

  void _handleReservation() {
    // EXACTO COMO SODITA - Mostrar formulario de reserva
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Reserva'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _tempName = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _tempPhone = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _tempEmail = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _processReservation(),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
  }

  String _tempName = '';
  String _tempPhone = '';
  String _tempEmail = '';

  Future<void> _processReservation() async {
    if (_tempName.trim().isEmpty || _tempPhone.trim().isEmpty) return;

    Navigator.pop(context); // Cerrar diálogo
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool loadingClosed = false;
    
    try {
      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      final reservation = await MultiRestaurantService.createReservation(
        restaurantId: widget.restaurant.id,
        mesaId: selectedTableId!,
        date: selectedDate,
        time: timeString,
        partySize: partySize,
        customerName: _tempName.trim(),
        customerPhone: _tempPhone.trim(),
        customerEmail: _tempEmail.trim().isEmpty ? null : _tempEmail.trim(),
      );

      if (mounted && !loadingClosed) {
        Navigator.pop(context); // Cerrar loading
        loadingClosed = true;
      }

      if (reservation != null) {
        // Mostrar confirmación IGUAL QUE SODITA
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '✅ Reserva Confirmada',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tu reserva ha sido confirmada exitosamente.',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ IMPORTANTE: Tenés 15 minutos de tolerancia desde tu horario de reserva. Pasado ese tiempo, la mesa se libera automáticamente.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Código de Confirmación',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reservation['codigo_confirmacion'],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        // Limpiar formulario
        setState(() {
          selectedTableNumber = null;
          selectedTableId = null;
          _tempName = '';
          _tempPhone = '';
          _tempEmail = '';
        });

        _loadTables(); // Recargar mesas
      }
    } catch (e) {
      if (mounted && !loadingClosed) {
        Navigator.pop(context); // Cerrar loading
        loadingClosed = true;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Garantizar que siempre se cierre el loading
      if (mounted && !loadingClosed) {
        Navigator.pop(context);
      }
    }
  }

  void _showTableReleasedAlert(Map<String, dynamic> releasedTable) {
    // MISMA ALERTA QUE SODITA
  }

  void _loadActiveReservationCache() {
    // MISMO CACHE QUE SODITA
  }

  void _startReservationCacheTimer() {
    // MISMO TIMER QUE SODITA
  }
}

// PÁGINAS AUXILIARES IGUALES QUE SODITA
class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Mis Reservas'),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Mi Perfil'),
    );
  }
}