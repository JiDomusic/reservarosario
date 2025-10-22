import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'l10n.dart';
import 'services/reservation_service.dart';
import 'admin_screen.dart';
import 'widgets/sodita_logo.dart';
import 'widgets/animated_card.dart';

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
          seedColor: const Color(0xFFE53E3E), // Rojo Woki mejorado
          brightness: Brightness.light,
          primary: const Color(0xFFE53E3E),
          surface: const Color(0xFFFFFBFF),
          onSurface: const Color(0xFF1C1B1F),
        ),
        // Tipografía moderna Woki
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
        // Botones estilo Woki 2025
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53E3E),
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
            animationDuration: const Duration(milliseconds: 200),
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
          selectedItemColor: const Color(0xFFE53E3E),
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
  
  // Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    super.dispose();
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
          : '20:00'; // Hora por defecto para mostrar disponibilidad general
      
      final results = await Future.wait([
        ReservationService.getMesas().timeout(const Duration(seconds: 5)),
        ReservationService.getCurrentlyOccupiedTables(date: selectedDate).timeout(const Duration(seconds: 5)),
        ReservationService.getOccupiedTables(date: selectedDate, time: timeString).timeout(const Duration(seconds: 5)),
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
            const Color(0xFFE53E3E).withValues(alpha: 0.1),
            const Color(0xFFFF6B6B).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE53E3E).withValues(alpha: 0.2),
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
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF6B35),
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
                      color: const Color(0xFFFF6B35),
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
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📍 ${l10n.upperFloorInfo}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B35),
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
            title: Row(
              children: [
                const SoditaLogoCompact(
                  size: 36,
                  color: Color(0xFFE53E3E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                _buildTableSection(),
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
          // Imagen del restaurante
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: const NetworkImage('https://picsum.photos/800/400?random=restaurant'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  print('Error cargando imagen del restaurante: $exception');
                },
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
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
                          Row(
                            children: [
                              const SoditaLogo(
                                width: 80,
                                height: 32,
                                showText: false,
                                primaryColor: Color(0xFFE53E3E),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SODITA',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1B1F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cocina casera • Ambiente familiar',
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
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B35),
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
                          color: Color(0xFFFF6B35),
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
                            ? const Color(0xFFFF6B35) 
                            : const Color(0xFFE5E7EB),
                        width: selectedTime == null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: selectedTime == null 
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFFFF6B35),
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
                                    ? const Color(0xFFFF6B35)
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
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF6B35),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecciona una hora para continuar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFFF6B35),
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

  Widget _buildTableSection() {
    if (isLoadingTables) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título sección
        Text(
          'Elegí tu mesa',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 16),
        
        // Grid de mesas estilo Woki
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: availableTables.length,
          itemBuilder: (context, index) {
            final table = availableTables[index];
            final isSelected = selectedTableNumber == table['numero'];
            final isOccupied = occupiedTableIds.contains(table['id']);
            final isReserved = reservedTableIds.contains(table['id']);
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
                                ? const Color(0xFFFF6B35)
                                : Colors.transparent,
                    width: 2,
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
                      Container(
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
                                  color: Color(0xFFFF6B35),
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
                                    color: Color(0xFFFF6B35),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Mesa',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B35),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Overlay estilo Woki
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isOccupied 
                                ? [
                                    const Color(0xFFE53E3E).withValues(alpha: 0.9),
                                    const Color(0xFFE53E3E).withValues(alpha: 0.95),
                                  ]
                                : isReserved
                                    ? [
                                        const Color(0xFFDD6B20).withValues(alpha: 0.85),
                                        const Color(0xFFDD6B20).withValues(alpha: 0.95),
                                      ]
                                    : [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                          ),
                        ),
                      ),
                      
                      // Badge de estado estilo Woki (esquina superior derecha)
                      if (isOccupied || isReserved)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOccupied 
                                  ? const Color(0xFFE53E3E) 
                                  : const Color(0xFFDD6B20),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOccupied ? Icons.people : Icons.schedule,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOccupied ? 'OCUPADA' : 'RESERVADA',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      // Icono central grande estilo Woki para mesas ocupadas
                      if (isOccupied)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.people,
                                color: const Color(0xFFE53E3E),
                                size: 32,
                              ),
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
                                        : const Color(0xFFFF6B35),
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
                              color: Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
                colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
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
              // Sistema de puntuación mejorado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rate,
                          color: const Color(0xFFFF6B35),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '¿Cómo calificarías tu experiencia previa?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Opcional - Ayúdanos a mejorar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final isSelected = index < selectedRating;
                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  selectedRating = index + 1;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: isSelected 
                                      ? const Color(0xFFFF6B35)
                                      : Colors.grey[400],
                                  size: isSelected ? 36 : 32,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRatingText(selectedRating),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
                color: Color(0xFFFF6B35),
              ),
              SizedBox(height: 16),
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
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
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
            
            // ⚠️ ADVERTENCIA IMPORTANTE DE 15 MINUTOS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IMPORTANTE - Tiempo de tolerancia',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tenés 15 minutos de tolerancia desde tu horario de reserva. Pasado ese tiempo, la mesa se libera automáticamente para otros clientes.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 Recomendamos llegar 5 minutos antes',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
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
              primary: Color(0xFFFF6B35),
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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '😞 Malo';
      case 2:
        return '😐 Regular';
      case 3:
        return '😊 Bueno';
      case 4:
        return '😄 Muy Bueno';
      case 5:
        return '🤩 Excelente';
      default:
        return '';
    }
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
              backgroundColor: const Color(0xFFFF6B35),
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