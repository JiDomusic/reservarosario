import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reservarosario/widgets/reservation_countdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n.dart';
import '../services/reservation_service.dart';
import '../services/rating_service.dart';
import '../widgets/rating_widget.dart';
import '../widgets/public_reviews_section.dart';
import '../admin_screen.dart';
import 'restaurant_list_screen.dart';

class SoditaOriginalApp extends StatefulWidget {
  const SoditaOriginalApp({super.key});

  @override
  State<SoditaOriginalApp> createState() => _SoditaOriginalAppState();
}

class _SoditaOriginalAppState extends State<SoditaOriginalApp> {
  final supabase = Supabase.instance.client;
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
        fontFamily: 'Poppins',
        textTheme: const TextTheme().apply(
          fontFamily: 'Poppins',
        ),
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
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RestaurantsPage(onLanguageChange: widget.onLanguageChange),
      const ReservationsPage(),
      const ProfilePage(),
    ];
  }

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
          onTap: (index) {
            if (index == 0) {
              // Botón Restaurantes - navegar a la lista de restaurantes
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
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
  final Function(Locale)? onLanguageChange;
  
  const RestaurantsPage({super.key, this.onLanguageChange});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final supabase = Supabase.instance.client;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int partySize = 2;
  int? selectedTableNumber;
  String? selectedTableId;
  String? lastPhoneNumber;
  
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
  
  List<Map<String, dynamic>> availableTables = [];
  List<String> occupiedTableIds = [];
  List<String> reservedTableIds = [];
  List<Map<String, dynamic>> reservations = []; // Para almacenar reservas
  bool isLoadingTables = true;
  bool _userIsInteracting = false; // Flag para pausar updates durante interacción
  DateTime? _lastFullUpdate; // Cache para optimizar actualizaciones
  
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
    
    // 🛡️ RESET FLAGS DE PROTECCIÓN AL INICIALIZAR
    _isCreatingReservation = false;
    _reservationCompleted = false;
    
    _loadTables();
    _loadReservations(); // Cargar reservas
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

  // Sistema de actualización SÚPER OPTIMIZADO con frecuencias inteligentes
  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _smartUpdate(); // Actualización inteligente cada 15 segundos
    });
  }

  // Actualización inteligente que solo actualiza cuando es necesario
  Future<void> _smartUpdate() async {
    if (!mounted || _userIsInteracting) return; // SÚPER OPTIMIZACIÓN: pausar durante interacción
    
    try {
      // Solo procesar si hay cambios o cada 2 minutos como máximo
      final now = DateTime.now();
      
      if (_lastFullUpdate == null || now.difference(_lastFullUpdate!).inMinutes >= 2) {
        await _processExpiredReservationsAndLoadTables();
        _lastFullUpdate = now;
        debugPrint('🔄 Full update - mesas y reservas actualizadas');
      } else {
        // Actualización rápida solo de estados críticos
        await _quickStatusUpdate();
      }
    } catch (e) {
      debugPrint('❌ Error en smart update: $e');
    }
  }

  // Actualización rápida - usa la función existente
  Future<void> _quickStatusUpdate() async {
    // Usa la función existente que ya funciona
    await _processExpiredReservationsAndLoadTables();
    debugPrint('⚡ Quick update completado');
  }

  // Comparar listas eficientemente
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
        // Siempre verificar mesas reservadas del día completo para mostrar en naranja
        timeString != null 
            ? ReservationService.getOccupiedTables(date: selectedDate, time: timeString).timeout(const Duration(seconds: 5))
            : ReservationService.getAllReservedTablesForDay(date: selectedDate).timeout(const Duration(seconds: 5)),
      ]);
      
      final tables = results[0] as List<Map<String, dynamic>>;
      final occupied = results[1] as List<String>;
      final reserved = results[2] as List<String>;
      
      if (!mounted) return;
      
      setState(() {
        // USAR DIRECTAMENTE LOS DATOS DE LA BASE DE DATOS REAL
        availableTables = tables;
        occupiedTableIds = occupied;
        reservedTableIds = reserved.where((id) => !occupied.contains(id)).toList(); // Excluir las que ya están ocupadas
        isLoadingTables = false;
      });
      
      print('🍽️ SODITA Original - Mesas cargadas desde BD: ${tables.length} mesas');
      print('🚫 SODITA Original - Mesas ocupadas: ${occupied.length} mesas');
      print('📅 SODITA Original - Mesas reservadas: ${reservedTableIds.length} mesas');
    } catch (e) {
      print('⚠️ SODITA Original - Error cargando mesas, usando datos originales: $e');
      
      if (!mounted) return;
      
      setState(() {
        // En caso de error, usar mesas vacías para forzar reconexión
        availableTables = [];
        occupiedTableIds = [];
        reservedTableIds = [];
        isLoadingTables = false;
      });
      
      // Mostrar mensaje discreto al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔄 Usando datos originales de SODITA - Conexión lenta'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Función eliminada - ahora usamos solo datos de la base de datos real

  void _showTableReleasedAlert(Map<String, dynamic> releasedTable) {
    if (!mounted) return;
    
    final tableNumber = releasedTable['sodita_mesas']['numero'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.table_restaurant, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Mesa Liberada!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'La Mesa $tableNumber acaba de liberarse. ¡Puedes reservarla ahora!',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Cache para reserva activa
  void _loadActiveReservationCache() async {
    try {
      final activeReservation = await ReservationService.getActiveReservation();
      if (mounted) {
        setState(() {
          _cachedActiveReservation = activeReservation;
        });
      }
    } catch (e) {
      print('Error cargando reserva activa en cache: $e');
    }
  }

  void _startReservationCacheTimer() {
    _reservationCacheTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _loadActiveReservationCache(); // Optimizado: 10s → 20s para reducir carga
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(l10n),
              // 🌟 CALIFICACIONES RESPONSIVAS Y SCROLLEABLES
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), 
                height: 160, // RESPONSIVO: altura ajustada para scroll
                child: const SingleChildScrollView(
                  child: PublicReviewsSection(
                    showAddReviewButton: false,
                    compactView: true,
                  ),
                ),
              ),
              // _buildActiveReservationSection(), // Movido solo al admin
              _buildDateTimeSelector(),
              const SizedBox(height: 20),
              _buildPartySizeSelector(),
              const SizedBox(height: 20),
              _buildTableGrid(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar personalizada
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menú de idiomas
                  PopupMenuButton<Locale>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    onSelected: widget.onLanguageChange,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: Locale('es'),
                        child: Text('🇪🇸 Español'),
                      ),
                      PopupMenuItem(
                        value: Locale('en'),
                        child: Text('🇺🇸 English'),
                      ),
                      PopupMenuItem(
                        value: Locale('zh'),
                        child: Text('🇨🇳 中文'),
                      ),
                    ],
                  ),
                  
                  // Admin Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF1D4ED8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Admin',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // LOGO GRANDE COMO EN EL ULTIMO DEPLOY
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

            // INFO DEL RESTAURANTE COMO EN EL ULTIMO DEPLOY
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
                              'Restaurante Gourmet • 10 mesas / living / salón',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Laprida 1301, Rosario 2000',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '30 min',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C1B1F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '\$\$',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C1B1F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '4-50 pers',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1C1B1F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MOSTRAR RESERVA ACTIVA DEL USUARIO CON COUNTDOWN OPTIMIZADO
  Widget _buildActiveReservationSection() {
    if (_cachedActiveReservation == null) {
      return const SizedBox.shrink();
    }

    final reservation = _cachedActiveReservation!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.1),
            const Color(0xFF1D4ED8).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🎉 ¡Tienes una reserva activa!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información de la reserva
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesa ${reservation['sodita_mesas']['numero']}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C1B1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reservation['sodita_mesas']['ubicacion']} • ${reservation['cantidad_personas']} personas',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📅 ${reservation['fecha']} a las ${reservation['hora']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // COUNTDOWN OPTIMIZADO
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ReservationCountdown(
                    key: ValueKey('countdown_${reservation['id']}'),
                    reservationTime: reservation['hora'],
                    isLarge: true,
                    onExpired: () {
                      // Cuando expire, actualizar el estado
                      setState(() {});
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(),
                        icon: const Icon(Icons.message, size: 16),
                        label: Text(
                          'WhatsApp',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(),
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: Text(
                          'Valorar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN PARA CONTACTAR POR WHATSAPP
  Future<void> _launchWhatsApp() async {
    const phoneNumber = '5493411234567'; // Número del restaurante
    const message = '¡Hola! Tengo una consulta sobre mi reserva en SODITA.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
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
                  onTap: () => _showTimeSelector(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
                              : const Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(
                              'Hora',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Seleccionar',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: selectedTime != null 
                                    ? const Color(0xFF1C1B1F) 
                                    : const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          ),
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
                      'Selecciona una hora para ver las mesas disponibles',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👥 Número de Personas',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                // Botón decrementar
                GestureDetector(
                  onTap: partySize > 1 ? () {
                    setState(() {
                      partySize--;
                    });
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: partySize > 1 
                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: partySize > 1 
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ),
                
                // Contador
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '$partySize ${partySize == 1 ? 'persona' : 'personas'}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                  ),
                ),
                
                // Botón incrementar
                GestureDetector(
                  onTap: partySize < 50 ? () {
                    setState(() {
                      partySize++;
                    });
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: partySize < 50 
                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: partySize < 50 
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
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

  Widget _buildTableGrid() {
    if (isLoadingTables) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              SizedBox(height: 16),
              Text('Cargando mesas...'),
            ],
          ),
        ),
      );
    }

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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🍽️ Mesas Disponibles',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1B1F),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '10 mesas',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getResponsiveCrossAxisCount(context),
              childAspectRatio: _getResponsiveAspectRatio(context),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: availableTables.length,
            itemBuilder: (context, index) {
              final table = availableTables[index];
              return _buildTableCard(table);
            },
          ),
          
          const SizedBox(height: 32),
          
          // 💬 SECCIÓN DE COMENTARIOS PÚBLICOS
          _buildPublicReviewsSection(),
          
        ],
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final tableId = table['id'].toString();
    final tableNumber = table['numero'] ?? 0;
    final capacity = table['capacidad'] ?? 0;
    final location = table['ubicacion'] ?? '';
    final isActive = table['activa'] ?? true;
    
    final isOccupied = occupiedTableIds.contains(tableId);
    final isReserved = reservedTableIds.contains(tableId);
    final isSelected = selectedTableId == tableId;
    final isAvailable = isActive && !isOccupied && !isReserved;
    final canAccommodateParty = capacity >= partySize;

    Color cardColor;
    Color textColor;
    String statusText;
    IconData statusIcon;

    if (!isActive) {
      cardColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
      statusText = 'Inactiva';
      statusIcon = Icons.block;
    } else if (isOccupied) {
      cardColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      statusText = 'Ocupada';
      statusIcon = Icons.people;
    } else if (isReserved) {
      cardColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      statusText = 'Reservada';
      statusIcon = Icons.schedule;
    } else if (!canAccommodateParty) {
      cardColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF6B7280);
      statusText = 'Muy pequeña';
      statusIcon = Icons.group_off;
    } else if (isSelected) {
      cardColor = const Color(0xFFDCFDF7);
      textColor = const Color(0xFF065F46);
      statusText = 'Seleccionada';
      statusIcon = Icons.check_circle;
    } else {
      cardColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF059669);
      statusText = 'Disponible';
      statusIcon = Icons.check_circle_outline;
    }

    return GestureDetector(
      onTap: isAvailable && canAccommodateParty ? () {
        setState(() {
          selectedTableId = isSelected ? null : tableId;
          selectedTableNumber = isSelected ? null : tableNumber;
          
          // 🔄 RESETEAR FLAGS DE RESERVA AL CAMBIAR DE MESA
          if (selectedTableId != tableId || isSelected) {
            _reservationCompleted = false; // Permitir nueva reserva para mesa diferente o al deseleccionar
            _isCreatingReservation = false; // Resetear flag de creación
            print('>>> MESA CAMBIADA/DESELECCIONADA: Flags de reserva reseteados');
          }
        });
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF10B981)
                : textColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 🖼️ IMAGEN COMPLETA DE FONDO
              Positioned.fill(
                child: Image.network(
                  _getTableImage(tableNumber),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.restaurant, color: Colors.grey.shade600),
                    );
                  },
                ),
              ),
              
              // 🎨 GRADIENTE PARA LEGIBILIDAD
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 📝 CONTENIDO OVERLAY - DISEÑO 2025
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título y estado en una línea
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: textColor),
                              const SizedBox(width: 4),
                              Text(
                                tableNumber == 11 ? 'Salón 50p' : 'Mesa $tableNumber',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Estado y capacidad
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$capacity personas • $location',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildActionButtons() {
    final canReserve = selectedTableId != null && selectedTime != null;
    
    // 🚫 VERIFICAR SI YA HAY RESERVA PARA ESTA FECHA/HORA
    final hasActiveReservation = _hasActiveReservationForDateTime();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Botón de reservar o estado
          SizedBox(
            width: double.infinity,
            child: hasActiveReservation
                ? _buildReservationStatus() // Mostrar estado de reserva existente
                : ElevatedButton(
                    onPressed: canReserve ? () => _showReservationDialog() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canReserve 
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE5E7EB),
                      foregroundColor: canReserve 
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: canReserve ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canReserve ? Icons.check : Icons.info_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            canReserve 
                                ? 'Reservar Mesa ${selectedTableNumber ?? 0}'
                                : 'Selecciona mesa y hora',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          const SizedBox(height: 12),
          
          // Botón de valorar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showRatingDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Deja tu valoración',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de reserva
  void _showReservationDialog() {
    // 🛡️ PREVENIR REAPERTURA DESPUÉS DE RESERVA EXITOSA
    if (_reservationCompleted) {
      print('>>> BLOQUEADO: Reserva ya completada, no mostrar formulario');
      return;
    }
    
    // 🛡️ PREVENIR APERTURA SI YA SE ESTÁ CREANDO UNA RESERVA
    if (_isCreatingReservation) {
      print('>>> BLOQUEADO: Ya se está creando una reserva');
      return;
    }
    
    // 🛡️ PREVENIR APERTURA SI YA HAY UN MODAL ABIERTO
    if (ModalRoute.of(context)?.isCurrent == false) {
      print('>>> BLOQUEADO: Ya hay un modal abierto');
      return;
    }
    
    // Limpiar variables temporales
    _tempName = '';
    _tempPhone = '';
    _tempEmail = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Completar Reserva'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('reservation_name_field'),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (value) => _tempName = value,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reservation_phone_field'),
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (value) => _tempPhone = value,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('reservation_email_field'),
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (value) => _tempEmail = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('reservation_submit_button'),
            onPressed: () {
              print('🔄 Botón Reservar presionado');
              _createReservation();
            },
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
  }

  String _tempName = '';
  String _tempPhone = '';
  String _tempEmail = '';

  // Protección contra múltiples clicks Y reapertura del formulario
  bool _isCreatingReservation = false;
  bool _reservationCompleted = false;

  // Crear reserva - PROTEGIDA CONTRA DUPLICADOS
  void _createReservation() async {
    // PREVENIR MÚLTIPLES CLICKS
    if (_isCreatingReservation) {
      print('>>> BLOQUEADO: Ya se está creando una reserva');
      return;
    }
    
    _isCreatingReservation = true;
    print('>>> PASO 1: Iniciando _createReservation');
    
    final name = _tempName.trim();
    final phone = _tempPhone.trim();
    final email = _tempEmail.trim();

    print('>>> PASO 2: Datos validados - Nombre: $name, Teléfono: $phone');

    if (name.isEmpty || phone.isEmpty) {
      print('>>> ERROR: Datos vacíos');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa nombre y teléfono'),
          backgroundColor: Colors.red,
        ),
      );
      _isCreatingReservation = false; // Resetear flag
      return;
    }

    // 🚫 VALIDAR RESERVAS DUPLICADAS ANTES DE CREAR
    if (_hasActiveReservationForDateTime()) {
      print('>>> ERROR: Ya existe una reserva para esta fecha/hora/mesa');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe una reserva para esta mesa en este horario'),
          backgroundColor: Colors.red,
        ),
      );
      _isCreatingReservation = false; // Resetear flag
      return;
    }

    print('>>> PASO 3: Validación OK, creando reserva en BD...');
    
    // LLAMADA DIRECTA SIN LOADING COMPLEJO
    try {
      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      print('>>> PASO 4: TimeString creado: $timeString');
      
      final reservation = await ReservationService.createReservation(
        mesaId: selectedTableId!,
        date: selectedDate,
        time: timeString,
        partySize: partySize,
        customerName: name,
        customerPhone: phone,
        customerEmail: email.isEmpty ? null : email,
        comments: null,
      );
      
      print('>>> PASO 5: Respuesta de BD: $reservation');
      
      if (reservation != null) {
        final codigo = reservation['codigo_confirmacion'] ?? reservation['id'] ?? 'TEMP${DateTime.now().millisecond}';
        print('>>> PASO 6: Código obtenido: $codigo');
        
        // 🛡️ MARCAR COMO COMPLETADA ANTES DE CUALQUIER ACCIÓN
        _reservationCompleted = true;
        print('>>> PASO 7: Reserva marcada como completada');
        
        // 🚪 CERRAR FORMULARIO INMEDIATAMENTE
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          print('>>> PASO 7.5: Formulario cerrado inmediatamente');
          
          // Pequeño delay para asegurar que el modal se cierre completamente
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // VERIFICAR SI AÚN ESTÁ MONTADO ANTES DE MOSTRAR DIÁLOGO
        if (mounted) {
          print('>>> PASO 8: Widget montado, mostrando diálogo de éxito');
          
          // Actualizar estado solo si está montado
          setState(() {
            if (selectedTableId != null) {
              reservedTableIds.add(selectedTableId!);
            }
          });
          
          // Mostrar diálogo de confirmación CON código y WhatsApp (SIN cerrar formulario porque ya está cerrado)
          _showSuccessDialog(codigo);
          
          print('>>> PASO 9: COMPLETADO EXITOSAMENTE');
        } else {
          print('>>> PASO 8: Widget desmontado, NO mostrando diálogo');
        }
      } else {
        print('>>> ERROR: Reservation es null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear la reserva. Por favor intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('>>> ERROR: Widget desmontado, no se puede mostrar emergencia');
        }
      }
      
    } catch (e) {
      print('>>> EXCEPTION: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('>>> EXCEPTION: Widget desmontado, no se puede mostrar error');
      }
    } finally {
      // LIBERAR FLAG SIEMPRE
      _isCreatingReservation = false;
      print('>>> FLAG LIBERADO: _isCreatingReservation = false');
    }
    
    print('>>> FIN: _createReservation completado');
  }

  void _showSuccessDialog(String confirmationCode) {
    print('>>> _showSuccessDialogAndClose: INICIANDO con código: $confirmationCode');
    
    // VERIFICAR QUE EL CONTEXT ESTÉ DISPONIBLE
    if (!mounted) {
      print('>>> _showSuccessDialogAndClose: Widget no montado, abortando');
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text(
            'RESERVA CONFIRMADA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tu reserva ha sido confirmada exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CÓDIGO DE RESERVA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      confirmationCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'IMPORTANTE: Tienes 15 minutos de tolerancia. Después la mesa se libera automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                print('>>> Aceptando reserva y cerrando diálogo de éxito');
                // Solo cerrar diálogo de éxito (formulario ya cerrado antes)
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('ACEPTAR'),
            ),
            ElevatedButton(
              onPressed: () {
                print('>>> Enviando WhatsApp y cerrando diálogo de éxito');
                // Solo cerrar diálogo de éxito (formulario ya cerrado antes)
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                _sendWhatsAppConfirmation(confirmationCode);
              },
              child: const Text('WHATSAPP'),
            ),
          ],
        ),
      );
      print('>>> _showSuccessDialog: DIALOG CREADO EXITOSAMENTE');
    } catch (e) {
      print('>>> ERROR en _showSuccessDialog: $e');
      // FALLBACK DE EMERGENCIA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RESERVA CONFIRMADA - Código: $confirmationCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
  
  // 🔍 VERIFICAR SI YA HAY RESERVA ACTIVA PARA LA FECHA/HORA SELECCIONADA
  bool _hasActiveReservationForDateTime() {
    if (selectedTime == null || selectedTableId == null) return false;
    
    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month, 
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    
    // Buscar en reservas confirmadas si ya existe una para esta fecha/hora/mesa
    final existingReservation = reservations.any((reservation) {
      if (reservation['estado'] != 'confirmada') return false;
      if (reservation['mesa_id'] != selectedTableId) return false;
      
      try {
        final reservationDateTime = DateTime.parse(reservation['hora']);
        return reservationDateTime.isAtSameMomentAs(selectedDateTime);
      } catch (e) {
        return false;
      }
    });
    
    return existingReservation;
  }

  // 📋 WIDGET PARA MOSTRAR ESTADO DE RESERVA EXISTENTE
  Widget _buildReservationStatus() {
    // Buscar la reserva activa para mostrar detalles
    final activeReservation = reservations.firstWhere(
      (reservation) {
        if (reservation['estado'] != 'confirmada') return false;
        if (reservation['mesa_id'] != selectedTableId) return false;
        
        try {
          final reservationDateTime = DateTime.parse(reservation['hora']);
          final selectedDateTime = DateTime(
            selectedDate.year,
            selectedDate.month, 
            selectedDate.day,
            selectedTime!.hour,
            selectedTime!.minute,
          );
          return reservationDateTime.isAtSameMomentAs(selectedDateTime);
        } catch (e) {
          return false;
        }
      },
      orElse: () => {},
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mesa ${selectedTableNumber ?? 0} ya reservada',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (activeReservation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cliente: ${activeReservation['nombre'] ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
            ),
            Text(
              'Código: ${activeReservation['codigo_confirmacion'] ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Botón para cancelar reserva
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCancelReservationDialog(activeReservation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Cancelar Reserva',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // 🗑️ DIÁLOGO PARA CANCELAR RESERVA
  void _showCancelReservationDialog(Map<String, dynamic> reservation) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              'Cancelar Reserva',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro que deseas cancelar esta reserva?',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: ${reservation['nombre'] ?? 'N/A'}', 
                       style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text('Mesa: ${selectedTableNumber ?? 0}'),
                  Text('Fecha: ${reservation['fecha'] ?? 'N/A'}'),
                  Text('Hora: ${reservation['hora']?.toString().split(' ')[1] ?? 'N/A'}'),
                  Text('Código: ${reservation['codigo_confirmacion'] ?? 'N/A'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'No, mantener',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
              await _cancelReservation(reservation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sí, cancelar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  // 🗑️ CANCELAR RESERVA EN LA BASE DE DATOS
  Future<void> _cancelReservation(Map<String, dynamic> reservation) async {
    try {
      print('🗑️ Cancelando reserva: ${reservation['id']}');
      
      final response = await supabase
          .from('sodita_reservas')
          .update({
            'estado': 'cancelada',
            'cancelado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', reservation['id']);
      
      print('✅ Reserva cancelada exitosamente');
      
      // Recargar datos y actualizar interfaz
      _loadReservations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva cancelada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error cancelando reserva: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar reserva: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  // 📋 CARGAR RESERVAS DESDE LA BASE DE DATOS CON REINTENTOS
  Future<void> _loadReservations() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('📋 Cargando reservas... (intento ${retryCount + 1}/$maxRetries)');
        
        final response = await supabase
            .from('sodita_reservas')
            .select('*')
            .order('hora', ascending: true)
            .timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            reservations = List<Map<String, dynamic>>.from(response);
          });
        }
        
        print('✅ ${reservations.length} reservas cargadas');
        return; // Éxito, salir del bucle
        
      } catch (e) {
        retryCount++;
        print('❌ Error cargando reservas (intento $retryCount): $e');
        
        if (retryCount < maxRetries) {
          print('🔄 Reintentando en 2 segundos...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          print('💥 Falló después de $maxRetries intentos. Usando datos locales de emergencia.');
          // Cargar datos de emergencia o continuar sin reservas
          if (mounted) {
            setState(() {
              reservations = [];
            });
          }
        }
      }
    }
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

SODITA - Comida gourmet
📍 Laprida 1301, Rosario 2000
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
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        // Limpiar hora seleccionada si es una fecha diferente
        if (picked.day != DateTime.now().day) {
          selectedTime = null;
        }
      });
      _loadTables();
    }
  }

  void _showTimeSelector() {
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
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
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
                              fontSize: 18,
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
    // Horarios sin loops - Lista directa de horarios disponibles
    return [
      // Horarios de almuerzo (12:00 - 15:30)
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 12, minute: 30),
      TimeOfDay(hour: 13, minute: 0),
      TimeOfDay(hour: 13, minute: 30),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 14, minute: 30),
      TimeOfDay(hour: 15, minute: 0),
      TimeOfDay(hour: 15, minute: 15),
      TimeOfDay(hour: 15, minute: 30),
      TimeOfDay(hour: 15, minute: 45),
      
      // Horario pico ampliado (16:00 - 19:00) - Más slots por demanda
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 16, minute: 15),
      TimeOfDay(hour: 16, minute: 30),
      TimeOfDay(hour: 16, minute: 45),
      TimeOfDay(hour: 17, minute: 0),
      TimeOfDay(hour: 17, minute: 15),
      TimeOfDay(hour: 17, minute: 30),
      TimeOfDay(hour: 17, minute: 45),
      TimeOfDay(hour: 18, minute: 0),
      TimeOfDay(hour: 18, minute: 15),
      TimeOfDay(hour: 18, minute: 30),
      TimeOfDay(hour: 18, minute: 45),
      
      // Horarios de cena (19:00 - 23:20)
      TimeOfDay(hour: 19, minute: 0),
      TimeOfDay(hour: 19, minute: 30),
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 20, minute: 30),
      TimeOfDay(hour: 21, minute: 0),
      TimeOfDay(hour: 21, minute: 30),
      TimeOfDay(hour: 22, minute: 0),
      TimeOfDay(hour: 22, minute: 30),
      TimeOfDay(hour: 23, minute: 0),
      TimeOfDay(hour: 23, minute: 20), // 🕚 AMPLIADO hasta 23:20
    ];
  }

  // 💬 SECCIÓN PÚBLICA DE COMENTARIOS DE CLIENTES
  Widget _buildPublicReviewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 🌟 GLASSMORPHISM 2025 
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        // 🎨 SOMBRAS MÚLTIPLES MODERNAS
        boxShadow: [
          // Sombra principal
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          // Sombra secundaria
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
          // Resaltado interior
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(0, 1),
            spreadRadius: 0,
            blurStyle: BlurStyle.inner,
          ),
        ],
        // 🌈 GRADIENTE SUTIL
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            Colors.grey.shade50.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 Título mejorado con mejor diseño
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lo que dicen nuestros clientes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1B1F),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Experiencias reales de quienes visitaron SODITA',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 📱 Lista horizontal más alta y espaciosa
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: RatingService.getAllRatings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF2563EB),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Sé el primero en dejar una reseña',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }
                
                final reviews = snapshot.data!;
                return _buildReviewScrollableSection(reviews);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 📝 CARD INDIVIDUAL DE RESEÑA
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 5;
    final comment = review['comment'] ?? '';
    final customerName = review['customer_name'] ?? 'Cliente';
    final createdAt = review['created_at'] ?? '';
    
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // 🌟 GLASSMORPHISM 2025
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            // 🎨 SOMBRAS MÚLTIPLES ESTILO 2025
            boxShadow: [
              // Sombra principal profunda
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              // Sombra secundaria suave
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              // Sombra de resaltado interior
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: 0,
                blurStyle: BlurStyle.inner,
              ),
            ],
            // 🌈 GRADIENTE SUTIL DE FONDO
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.98),
                Colors.grey.shade50.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estrellas y "Cliente"
              Row(
                children: [
                  // ⭐ Estrellas con mejor diseño
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: index < rating ? Colors.amber.shade600 : Colors.grey.shade300,
                          size: 16,
                        );
                      }),
                    ),
                  ),
                  const Spacer(),
                  // Nombre del cliente
                  Text(
                    'Cliente',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 💬 Comentario con mejor tipografía
              Expanded(
                child: Text(
                  comment.isNotEmpty ? comment : 'Excelente experiencia en SODITA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 📅 Fecha con icono
              if (createdAt.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatReviewDate(createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 📅 FORMATEAR FECHA DE RESEÑA
  String _formatReviewDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Hoy';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  // 🎬 SCROLL ESTILO NETFLIX PARA RESEÑAS
  Widget _buildReviewScrollableSection(List<Map<String, dynamic>> reviews) {
    final ScrollController scrollController = ScrollController();

    return Stack(
      children: [
        // Lista scrolleable
        ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 50), // Espacio para los botones
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(review);
          },
        ),
        
        // 🚀 BOTÓN IZQUIERDO SÚPER PROFESIONAL
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                // 🌟 GLASSMORPHISM MODERNO
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                // 🎨 SOMBRAS PROFESIONALES
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                // 🌈 GRADIENTE SUTIL
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.98),
                    Colors.grey.shade50.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    scrollController.animateTo(
                      scrollController.offset - 300,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic, // Curva más profesional
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.chevron_left_rounded, // Icono redondeado
                      size: 28,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // 🚀 BOTÓN DERECHO SÚPER PROFESIONAL
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                // 🌟 GLASSMORPHISM MODERNO
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                // 🎨 SOMBRAS PROFESIONALES
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                // 🌈 GRADIENTE SUTIL
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.98),
                    Colors.grey.shade50.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    scrollController.animateTo(
                      scrollController.offset + 300,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic, // Curva más profesional
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.chevron_right_rounded, // Icono redondeado
                      size: 28,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 📱 RESPONSIVIDAD INTELIGENTE PARA MESAS
  // 🎨 DISEÑO PROFESIONAL 2025 - RESPONSIVE PERFECTO
  int _getResponsiveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;      // Móvil: 2 columnas SIEMPRE
    if (width < 900) return 3;      // Tablet: 3 columnas  
    if (width < 1400) return 4;     // Desktop: 4 columnas
    return 5;                       // Ultra wide: 5 columnas
  }
  
  double _getResponsiveAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // PROPORCIÓN DORADA PARA CARDS DE RESTAURANTE
    if (width < 600) return 1.2;    // Móvil: más cuadradas para mejor lectura
    if (width < 900) return 1.4;    // Tablet: equilibrio perfecto
    return 1.6;                     // Desktop: ligeramente rectangulares
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
          'Mi Perfil',
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