import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reservarosario/widgets/reservation_countdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'l10n.dart';
import 'services/reservation_service.dart';
import 'services/rating_service.dart';
import 'widgets/rating_widget.dart';
import 'admin_screen.dart';

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
  
  runApp(const SoditaApp());
}

class SoditaApp extends StatefulWidget {
  const SoditaApp({super.key});

  @override
  State<SoditaApp> createState() => _SoditaAppState();
}

class _SoditaAppState extends State<SoditaApp> {
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
      title: 'SODITA',
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
        // Colores exactos de Woki
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Azul
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFFD0029),
          onSurface: const Color(0xFF1C1B1F),
        ),
        // Tipografía moderna Woki
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        // Botones estilo Woki 2025
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
        // Cards estilo Woki
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shadowColor: Color(0x14000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        // AppBar estilo Woki
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
      home: SoditaHome(onLanguageChange: _changeLanguage),
    );
  }
}

class SoditaHome extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  
  const SoditaHome({super.key, required this.onLanguageChange});

  @override
  State<SoditaHome> createState() => _SoditaHomeState();
}

class _SoditaHomeState extends State<SoditaHome> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const RestaurantsPage(),
    const ReservationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
          onTap: (index) => setState(() => _currentIndex = index),
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
              icon: Icon(Icons.restaurant),
              label: 'Restaurantes',
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

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
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
  
  // Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadTables();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  // Iniciar actualización automática cada 30 segundos
  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processExpiredReservationsAndLoadTables();
    });
  }

  // Procesar reservas expiradas y actualizar mesas
  Future<void> _processExpiredReservationsAndLoadTables() async {
    if (!mounted) return;
    
    try {
      // Procesar reservas expiradas automáticamente
      final releasedTables = await ReservationService.processExpiredReservations();
      
      // Si se liberaron mesas y el restaurante está lleno, mostrar alerta
      if (releasedTables.isNotEmpty) {
        final isRestaurantFull = await ReservationService.isRestaurantFull();
        
        for (var releasedTable in releasedTables) {
          if (isRestaurantFull) {
            _showTableReleasedAlert(releasedTable);
          }
          
          print('🔄 Mesa ${releasedTable['sodita_mesas']['numero']} liberada automáticamente en frontend');
        }
      }
      
      // Recargar mesas después del procesamiento
      _loadTables();
    } catch (e) {
      print('❌ Error procesando reservas expiradas: $e');
      // Aún así recargar las mesas
      _loadTables();
    }
  }

  Future<void> _loadTables() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingTables = true;
    });
    
    try {
      // Cargar mesas, mesas ocupadas y mesas reservadas en paralelo
      final timeString = selectedTime != null 
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : null;
      
      final results = await Future.wait([
        ReservationService.getMesas().timeout(const Duration(seconds: 5)),
        ReservationService.getCurrentlyOccupiedTables(date: selectedDate).timeout(const Duration(seconds: 5)),
        // Si no hay hora seleccionada, mostrar todas las reservas del día
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
        reservedTableIds = reserved.where((id) => !occupied.contains(id)).toList(); // Excluir las que ya están ocupadas
        isLoadingTables = false;
      });
      
      print('🍽️ Mesas cargadas desde BD: ${tables.length} mesas');
      print('🚫 Mesas ocupadas: ${occupied.length} mesas');
      print('📅 Mesas reservadas: ${reservedTableIds.length} mesas');
    } catch (e) {
      print('⚠️ Error cargando mesas, usando datos locales: $e');
      
      if (!mounted) return;
      
      setState(() {
        availableTables = _getFallbackTables();
        occupiedTableIds = []; // Sin datos de ocupación en modo offline
        reservedTableIds = []; // Sin datos de reserva en modo offline
        isLoadingTables = false;
      });
      
      // Mostrar mensaje discreto al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔄 Usando datos locales - Conexión lenta'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFallbackTables() {
    return [
      {'id': '1', 'numero': 1, 'capacidad': 2, 'ubicacion': 'Ventana frontal', 'activa': true},
      {'id': '2', 'numero': 2, 'capacidad': 2, 'ubicacion': 'Ventana lateral', 'activa': true},
      {'id': '3', 'numero': 3, 'capacidad': 4, 'ubicacion': 'Centro del salon', 'activa': true},
      {'id': '4', 'numero': 4, 'capacidad': 4, 'ubicacion': 'Cerca de la ventana', 'activa': true},
      {'id': '5', 'numero': 5, 'capacidad': 6, 'ubicacion': 'Mesa grande central', 'activa': true},
      {'id': '6', 'numero': 6, 'capacidad': 8, 'ubicacion': 'Mesa familiar grande', 'activa': true},
      {'id': '7', 'numero': 7, 'capacidad': 2, 'ubicacion': 'Rincon privado', 'activa': true},
      {'id': '8', 'numero': 8, 'capacidad': 4, 'ubicacion': 'Centro-derecha', 'activa': true},
      {'id': '9', 'numero': 9, 'capacidad': 4, 'ubicacion': 'Centro-izquierda', 'activa': true},
      {'id': '10', 'numero': 10, 'capacidad': 2, 'ubicacion': 'Mesa de la esquina', 'activa': true},
    ];
  }

  String _getTableImage(int tableNumber) {
    // URLs más estables de imágenes de mesas de restaurante
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
                    l10n.tableLayoutNotice,
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
              l10n.tableLayoutDescription,
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
                '📍 ${l10n.upperFloorInfo}',
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
          // AppBar estilo Woki
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
                tooltip: AppLocalizations.of(context).languageSelector,
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
          
          // Contenido principal
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTableInfoNotice(),
                const SizedBox(height: 16),
                _buildRestaurantCard(),
                const SizedBox(height: 24),
                _buildDateTimeSelector(),
                const SizedBox(height: 24),
                _buildPartySizeSelector(),
                const SizedBox(height: 24),
                _buildTableSectionHeader(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          
          // Grid de mesas como SliverGrid
          _buildTableGrid(),
          
          // Botón de reserva
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _buildRatingsSection(),
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
          // Logo del restaurante - Extra grande
          Container(
            height: 250,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Colors.white,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logo color.png',
                  height: 500,
                  width: 500,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,

                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 48,
                          color: Color(0xB3DC0B3F),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SODITA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Info del restaurante
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SODITA',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1B1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Restaurante Gourmet • Planta Alta',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info adicional
                Row(
                  children: [
                    _buildInfoChip(Icons.access_time, '30 min'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.attach_money, '\$\$'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.people, '2-8 personas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Fecha y Hora',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Selector de fecha
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
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
                                fontSize: 16,
                                color: const Color(0xFF1C1B1F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Selector de hora
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedTime == null 
                            ? const Color(0xFF2563EB) 
                            : const Color(0xFFE5E7EB),
                        width: selectedTime == null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: selectedTime == null 
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
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
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Seleccionar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: selectedTime == null 
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF1C1B1F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (selectedTime == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecciona una hora para continuar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartySizeSelector() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👥 Cantidad de Personas',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Botón decrementar
              Container(
                decoration: BoxDecoration(
                  color: partySize <= 2 ? const Color(0xFFE5E7EB) : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: partySize <= 2 ? null : () {
                    setState(() {
                      partySize--;
                      selectedTableNumber = null;
                      selectedTableId = null;
                    });
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
              
              // Display del número
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$partySize personas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1B1F),
                    ),
                  ),
                ),
              ),
              
              // Botón incrementar
              Container(
                decoration: BoxDecoration(
                  color: partySize >= 50 ? const Color(0xFFE5E7EB) : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: partySize >= 50 ? null : () {
                    setState(() {
                      partySize++;
                      selectedTableNumber = null;
                      selectedTableId = null;
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Selector rápido de tamaños comunes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 4, 6, 8, 10, 15, 20, 30, 50].map((size) {
              final isSelected = partySize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    partySize = size;
                    selectedTableNumber = null;
                    selectedTableId = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$size',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Info sobre capacidad total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Capacidad total: 50 personas en 10 mesas • Se recomiendan mesas según tu grupo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSectionHeader() {
    String recommendationText = _getTableRecommendation();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegí tu mesa',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        if (recommendationText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendationText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Obtener recomendación de mesa según el tamaño del grupo
  String _getTableRecommendation() {
    if (partySize <= 2) {
      return 'Recomendadas: Mesas para 2 personas (1, 2, 7, 10)';
    } else if (partySize <= 4) {
      return 'Recomendadas: Mesas para 4 personas (3, 4, 8, 9)';
    } else if (partySize <= 6) {
      return 'Recomendada: Mesa para 6 personas (5)';
    } else if (partySize <= 8) {
      return 'Recomendada: Mesa para 8 personas (6)';
    } else if (partySize <= 12) {
      return 'Sugerencia: Combinar 2 mesas para 4 personas (3+4 o 8+9)';
    } else if (partySize <= 16) {
      return 'Sugerencia: Combinar mesa grande + mesa mediana (6+8 o 5+9)';
    } else {
      return 'Grupos grandes: Combinar múltiples mesas. Contacta al restaurante para grupos +20';
    }
  }

  // Verificar si una mesa es recomendada para el tamaño del grupo
  bool _isTableRecommended(Map<String, dynamic> table) {
    final tableNumber = table['numero'];
    final capacity = table['capacidad'];
    
    if (partySize <= 2) {
      return capacity == 2; // Mesas 1, 2, 7, 10
    } else if (partySize <= 4) {
      return capacity == 4; // Mesas 3, 4, 8, 9
    } else if (partySize <= 6) {
      return capacity == 6; // Mesa 5
    } else if (partySize <= 8) {
      return capacity == 8; // Mesa 6
    } else if (partySize <= 12) {
      return capacity == 4; // Mesas para combinar
    } else if (partySize <= 16) {
      return capacity >= 6; // Mesas grandes
    }
    return false;
  }

  Widget _buildTableGrid() {
    if (isLoadingTables) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final table = availableTables[index];
            final isSelected = selectedTableNumber == table['numero'];
            final isOccupied = occupiedTableIds.contains(table['id']);
            final isReserved = reservedTableIds.contains(table['id']);
            final isRecommended = _isTableRecommended(table);
            final l10n = AppLocalizations.of(context);
            
            return GestureDetector(
              onTap: (isOccupied || isReserved) ? () {
                // Mostrar mensaje flotante para mesas no disponibles
                _showTableNotAvailableDialog(table, isOccupied, isReserved);
              } : () {
                setState(() {
                  selectedTableNumber = table['numero'];
                  selectedTableId = table['id'];
                });
                
                // Analytics: Mesa seleccionada
                analytics.logEvent(
                  name: 'select_table',
                  parameters: {
                    'table_number': table['numero'],
                    'table_capacity': table['capacidad'],
                    'table_location': table['ubicacion'] ?? '',
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOccupied
                        ? Colors.red.withValues(alpha: 0.5)
                        : isReserved
                            ? Colors.orange.withValues(alpha: 0.5)
                            : isSelected 
                                ? const Color(0xB3DC0B3F)
                                : isRecommended
                                    ? Colors.blue.withValues(alpha: 0.8)
                                    : Colors.transparent,
                    width: isRecommended && !isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOccupied 
                          ? Colors.red.withValues(alpha: 0.1)
                          : isReserved
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Imagen de fondo con fallback
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.network(
                          _getTableImage(table['numero']),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2563EB),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 24,
                                    color: Color(0xFF2563EB),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Mesa',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isOccupied 
                                ? [
                                    Colors.grey.withValues(alpha: 0.8),
                                    Colors.grey.withValues(alpha: 0.9),
                                  ]
                                : isReserved
                                    ? [
                                        Colors.orange.withValues(alpha: 0.6),
                                        Colors.orange.withValues(alpha: 0.8),
                                      ]
                                    : [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                          ),
                        ),
                      ),
                      
                      // Contenido
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOccupied 
                                    ? Colors.red.withValues(alpha: 0.8)
                                    : isReserved
                                        ? Colors.orange.withValues(alpha: 0.9)
                                        : const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOccupied 
                                    ? l10n.tableNotAvailable
                                    : isReserved
                                        ? l10n.tableReserved
                                        : 'Mesa ${table['numero']}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isOccupied 
                                  ? l10n.tableOccupied
                                  : isReserved
                                      ? 'Reservada para hoy'
                                      : table['ubicacion'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isOccupied 
                                      ? Icons.block 
                                      : isReserved
                                          ? Icons.event_busy
                                          : Icons.people,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (isOccupied || isReserved)
                                      ? 'Mesa ${table['numero']}'
                                      : '${table['capacidad']} personas',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Icono seleccionado
                      if (isSelected)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      
                      // Insignia de mesa recomendada
                      if (isRecommended && !isSelected && !isOccupied && !isReserved)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.thumb_up,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Ideal',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: availableTables.length,
        ),
      ),
    );
  }


  Widget _buildReserveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: (selectedTableNumber != null && selectedTime != null)
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: (selectedTableNumber == null || selectedTime == null) ? const Color(0xFFE5E7EB) : null,
      ),
      child: ElevatedButton(
        onPressed: (selectedTableNumber != null && selectedTime != null) ? _showReservationForm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          (selectedTableNumber != null && selectedTime != null)
              ? 'Reservar Mesa $selectedTableNumber' 
              : selectedTableNumber == null
                  ? 'Seleccioná una mesa'
                  : 'Seleccioná fecha y hora',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: (selectedTableNumber != null && selectedTime != null) ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  void _showReservationForm() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final commentsController = TextEditingController();
    int selectedRating = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reservar Mesa $selectedTableNumber',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Sistema de puntuación
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo calificarías tu experiencia previa? (opcional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedRating = index + 1;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                index < selectedRating 
                                    ? Icons.star 
                                    : Icons.star_border,
                                color: const Color(0xB3DC0B3F),
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
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
            onPressed: () => _processReservation(
              nameController.text,
              phoneController.text,
              emailController.text,
              commentsController.text,
              selectedRating,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processReservation(String name, String phone, String email, String comments, int rating) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Por favor completa nombre y teléfono'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    Navigator.pop(context); // Cerrar diálogo

    // Mostrar loading con timeout visual
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xB3DC0B3F),
              ),
              SizedBox(height: 18),
              Text(
                'Creando tu reserva...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Guardar el teléfono para WhatsApp
      lastPhoneNumber = phone.trim();
      
      // Crear reserva con timeout
      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      final reservation = await ReservationService.createReservation(
        mesaId: selectedTableId!,
        date: selectedDate,
        time: timeString,
        partySize: partySize,
        customerName: name.trim(),
        customerPhone: phone.trim(),
        customerEmail: email.trim().isEmpty ? null : email.trim(),
        comments: comments.trim().isEmpty ? null : comments.trim(),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (reservation != null) {
          // Analytics: Reserva completada
          analytics.logEvent(
            name: 'reservation_completed',
            parameters: {
              'table_number': selectedTableNumber ?? 0,
              'party_size': partySize,
              'confirmation_code': reservation['codigo_confirmacion'],
              'method': 'database',
              'customer_rating': rating,
            },
          );
          
          // Actualizar estado de la mesa inmediatamente
          setState(() {
            if (selectedTableId != null) {
              reservedTableIds.add(selectedTableId!);
            }
          });
          
          // Mostrar diálogo de éxito
          _showSuccessDialog(reservation['codigo_confirmacion']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al crear la reserva. Intenta nuevamente.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en reserva: $e');
      
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        
        // Generar código de respaldo
        final fallbackCode = 'SOD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        
        // Analytics: Reserva con código de respaldo
        analytics.logEvent(
          name: 'reservation_completed',
          parameters: {
            'table_number': selectedTableNumber ?? 0,
            'party_size': partySize,
            'confirmation_code': fallbackCode,
            'method': 'fallback',
            'customer_rating': rating,
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Conexión lenta. Usando código temporal: $fallbackCode'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Mostrar diálogo con código temporal
        _showSuccessDialog(fallbackCode);
      }
    }
  }

  void _showSuccessDialog(String confirmationCode) {
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
                    confirmationCode,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.amber[800],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tolerancia de 15 minutos. Pasado ese tiempo, la mesa se libera automáticamente.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _sendWhatsAppConfirmation(confirmationCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x0025d366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.message, size: 16),
              label: const Text(
                'Enviar por WhatsApp',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Sección de valoraciones
  Widget _buildRatingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Valoraciones de SODITA',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1B1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rating promedio y estadísticas
          FutureBuilder<Map<String, dynamic>>(
            future: RatingService.getRatingStatistics(30), // Últimos 30 días
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!['total_ratings'] == 0) {
                return Column(
                  children: [
                    Text(
                      '¡Sé el primero en valorar SODITA!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(),
                      icon: const Icon(Icons.star_border),
                      label: const Text('Valorar Restaurante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              }
              
              final avgRating = snapshot.data!['average_rating'] ?? 0.0;
              final totalRatings = snapshot.data!['total_ratings'] ?? 0;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < avgRating.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber[600],
                                size: 20,
                              );
                            }),
                          ),
                          Text(
                            '$totalRatings valoraciones',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Valorar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Últimas valoraciones
          FutureBuilder<List<Map<String, dynamic>>>(
            future: RatingService.getRecentRatings(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final recentRatings = snapshot.data!.take(3).toList();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentarios recientes:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recentRatings.map((rating) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < rating['stars'] ? Icons.star : Icons.star_border,
                                    color: Colors.amber[600],
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rating['customer_name'] ?? 'Cliente',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (rating['comment'] != null && rating['comment'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              rating['comment'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de valoración para usuarios
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        reservationId: 'user_rating_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'Cliente',
        onRatingSubmitted: (ratingData) async {
          final success = await RatingService.createRating(
            reservationId: ratingData['reservation_id'],
            customerName: ratingData['customer_name'],
            stars: ratingData['stars'],
            comment: ratingData['comment'],
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ ¡Gracias por tu valoración!'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {}); // Refresh para mostrar la nueva valoración
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Error al guardar la valoración'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _sendWhatsAppConfirmation(String confirmationCode) async {
    try {
      // Usar el teléfono del formulario de reserva
      String phoneNumber = lastPhoneNumber ?? '';
      
      // Limpiar el número de teléfono
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Si no tiene código de país, agregar Argentina
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+54$phoneNumber';
      }
      
      // Mensaje de confirmación
      final selectedTimeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      final message = '''
¡Hola! Tu reserva en SODITA ha sido confirmada ✅

🏷️ Código: $confirmationCode
🍽️ Mesa: $selectedTableNumber
📅 Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}
⏰ Hora: $selectedTimeString
👥 Personas: $partySize

⚠️ IMPORTANTE: Tenés 15 minutos de tolerancia desde tu horario de reserva. Pasado ese tiempo, la mesa se libera automáticamente para otros clientes.

💡 Recomendamos llegar 5 minutos antes de tu horario.

¡Te esperamos! 🎉

SODITA - Cocina casera, ambiente familiar
📍 Rosario, Santa Fe
      ''';

      final whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Analytics: WhatsApp enviado
        analytics.logEvent(
          name: 'whatsapp_confirmation_sent',
          parameters: {
            'table_number': selectedTableNumber ?? 0,
            'confirmation_code': confirmationCode,
          },
        );
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ WhatsApp abierto. Envía el mensaje para confirmar tu reserva.'),
            backgroundColor: Color(0x0025d366),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw 'No se puede abrir WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al abrir WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFDC2626),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1B1F),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Resetear hora cuando cambia la fecha
        selectedTime = null;
      });
      // Recargar mesas para la nueva fecha
      _loadTables();
    }
  }

  Future<void> _selectTime() async {
    // Horarios disponibles del restaurante
    final List<TimeOfDay> availableTimes = [
      // Almuerzo
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 12, minute: 30),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 13, minute: 30),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 14, minute: 30),
      const TimeOfDay(hour: 15, minute: 0),
      // Cena
      const TimeOfDay(hour: 19, minute: 0),
      const TimeOfDay(hour: 19, minute: 30),
      const TimeOfDay(hour: 20, minute: 0),
      const TimeOfDay(hour: 20, minute: 30),
      const TimeOfDay(hour: 21, minute: 0),
      const TimeOfDay(hour: 21, minute: 30),
      const TimeOfDay(hour: 22, minute: 0),
      const TimeOfDay(hour: 22, minute: 30),
      const TimeOfDay(hour: 23, minute: 0),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          children: [
            Text(
              '⏰ Selecciona un horario',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth > 600) crossAxisCount = 4;
                  if (constraints.maxWidth < 400) crossAxisCount = 2;
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                itemCount: availableTimes.length,
                itemBuilder: (context, index) {
                  final time = availableTimes[index];
                  final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  final isLunchTime = time.hour >= 12 && time.hour <= 15;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = time;
                      });
                      Navigator.pop(context);
                      // Recargar mesas para la nueva hora
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
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
              l10n.languageSelector,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              '🇪🇸',
              l10n.spanish,
              const Locale('es'),
            ),
            _buildLanguageOption(
              context,
              '🇺🇸',
              l10n.english,
              const Locale('en'),
            ),
            _buildLanguageOption(
              context,
              '🇨🇳',
              l10n.chinese,
              const Locale('zh'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String flag, String name, Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          // Cambiar idioma a través del callback del widget padre
          final soditaApp = context.findAncestorStateOfType<_SoditaAppState>();
          if (soditaApp != null) {
            soditaApp.changeLanguage(locale);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showTableNotAvailableDialog(Map<String, dynamic> table, bool isOccupied, bool isReserved) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              isOccupied ? Icons.block : Icons.event_busy,
              color: isOccupied ? Colors.red : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOccupied ? l10n.tableOccupied : l10n.tableReserved,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isOccupied ? Colors.red : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isOccupied ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: isOccupied ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mesa ${table['numero']} - ${table['ubicacion']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOccupied ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOccupied 
                  ? 'Esta mesa está actualmente ocupada por otros clientes. Por favor elige otra mesa disponible.'
                  : l10n.tableReservedMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
            ),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Scroll hacia arriba para mostrar las mesas disponibles
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.chooseAnotherTable,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar alerta flotante cuando se libera una mesa
  void _showTableReleasedAlert(Map<String, dynamic> tableData) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: TableReleasedAlert(
          tableData: tableData,
          onDismiss: () {
            // Se elimina automáticamente después de 10 segundos
          },
          onReserveNow: () {
            // Navegar a reserva de esta mesa específica
            final mesa = tableData['sodita_mesas'];
            if (mesa != null) {
              setState(() {
                selectedTableId = mesa['id'];
                selectedTableNumber = mesa['numero'];
              });
            }
          },
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto-remover después de 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

// Página de Reservas
class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Mis Reservas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
      ),
      body: const Center(
        child: Text('Próximamente: Historial de reservas'),
      ),
    );
  }
}

// Página de Perfil
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
      ),
      body: const Center(
        child: Text('Próximamente: Configuración de perfil'),
      ),
    );
  }
}