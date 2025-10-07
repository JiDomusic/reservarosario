import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'supabase_config.dart';
import 'l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const SoditaApp());
}

class SoditaApp extends StatefulWidget {
  const SoditaApp({super.key});

  @override
  State<SoditaApp> createState() => _SoditaAppState();
}

class _SoditaAppState extends State<SoditaApp> {
  Locale _locale = const Locale('es'); // Español por defecto

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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

class _SoditaHomeState extends State<SoditaHome>
    with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int partySize = 2;
  int? selectedTableNumber;
  bool showFloorPlan = false; // Vista de plano vs lista
  
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  
  final List<String> timeSlots = [
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', 
    '21:00', '21:30', '22:00', '22:30', '23:00'
  ];

  final List<Map<String, dynamic>> tables = [
    {'number': 1, 'capacity': 2, 'location': 'Barra ventana', 'type': 'barra'},
    {'number': 2, 'capacity': 2, 'location': 'Barra lateral', 'type': 'barra'},
    {'number': 3, 'capacity': 4, 'location': 'Mesa pared izquierda', 'type': 'mesa'},
    {'number': 4, 'capacity': 4, 'location': 'Mesa pared derecha', 'type': 'mesa'},
    {'number': 5, 'capacity': 6, 'location': 'Mesa familiar fondo', 'type': 'mesa'},
    {'number': 6, 'capacity': 8, 'location': 'Mesa grande esquina', 'type': 'mesa'},
    {'number': 7, 'capacity': 2, 'location': 'Barra rincón', 'type': 'barra'},
    {'number': 8, 'capacity': 4, 'location': 'Mesa centro-derecha', 'type': 'mesa'},
    {'number': 9, 'capacity': 4, 'location': 'Mesa centro-izquierda', 'type': 'mesa'},
    {'number': 10, 'capacity': 2, 'location': 'Barra entrada', 'type': 'barra'},
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SODITA'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          // Selector de idiomas
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLanguageChange,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Locale('es'),
                child: Row(
                  children: [
                    Text('🇪🇸'),
                    SizedBox(width: 8),
                    Text('Español'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Locale('en'),
                child: Row(
                  children: [
                    Text('🇺🇸'),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Locale('zh'),
                child: Row(
                  children: [
                    Text('🇨🇳'),
                    SizedBox(width: 8),
                    Text('中文'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _showAdminLogin,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              child: const Text(
                'Reservar Mesa',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Elige tu mesa en el piso superior',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildDateSection(),
            
            const SizedBox(height: 28),
            
            _buildTimeSection(),
            
            const SizedBox(height: 28),
            
            _buildPartySizeSection(),
            
            const SizedBox(height: 32),
            
            _buildTableSection(),
            
            const SizedBox(height: 40),
            
            _buildReserveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuándo?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = selectedDate.day == date.day && 
                                 selectedDate.month == date.month;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                      selectedTableNumber = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFFF6B35),
                              const Color(0xFFFF8A65),
                            ],
                          )
                        : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          _getMonthName(date.month),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
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
    );
  }

  Widget _buildTimeSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿A qué hora?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: timeSlots.map((time) {
              final timeOfDay = TimeOfDay(
                hour: int.parse(time.split(':')[0]),
                minute: int.parse(time.split(':')[1]),
              );
              final isSelected = selectedTime == timeOfDay;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTime = timeOfDay;
                    selectedTableNumber = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFFF6B35),
                            const Color(0xFFFF8A65),
                          ],
                        )
                      : null,
                    color: isSelected ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySizeSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuántas personas?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCounterButton(
                icon: Icons.remove,
                onTap: partySize > 1 ? () {
                  setState(() {
                    partySize--;
                    selectedTableNumber = null;
                  });
                } : null,
              ),
              
              const SizedBox(width: 20),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.1),
                      const Color(0xFFFF8A65).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  '$partySize ${partySize == 1 ? 'persona' : 'personas'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              _buildCounterButton(
                icon: Icons.add,
                onTap: partySize < 8 ? () {
                  setState(() {
                    partySize++;
                    selectedTableNumber = null;
                  });
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: onTap != null 
            ? LinearGradient(
                colors: [
                  const Color(0xFFFF6B35),
                  const Color(0xFFFF8A65),
                ],
              )
            : null,
          color: onTap == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.grey.shade600,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    if (selectedTime == null) return const SizedBox();
    
    final l10n = AppLocalizations.of(context);
    final availableTables = tables.where((table) => 
      table['capacity'] >= partySize
    ).toList();
    
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.selectTable,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Toggle vista lista/plano
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => showFloorPlan = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: !showFloorPlan 
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFFF8A65),
                                ],
                              )
                            : null,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                        child: Icon(
                          Icons.list,
                          size: 16,
                          color: !showFloorPlan ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showFloorPlan = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: showFloorPlan 
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFFF8A65),
                                ],
                              )
                            : null,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: Icon(
                          Icons.map,
                          size: 16,
                          color: showFloorPlan ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${availableTables.length} ${l10n.availableTables} $partySize ${partySize == 1 ? l10n.person : l10n.people}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          showFloorPlan ? _buildFloorPlan(availableTables) : _buildTableList(availableTables),
        ],
      ),
    );
  }

  Widget _buildTableList(List<Map<String, dynamic>> availableTables) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: availableTables.map((table) {
        final isSelected = selectedTableNumber == table['number'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTableNumber = table['number'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.1),
                      const Color(0xFFFF8A65).withOpacity(0.1),
                    ],
                  )
                : null,
              color: isSelected ? null : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                  ? const Color(0xFFFF6B35)
                  : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFFF6B35),
                            const Color(0xFFFF8A65),
                          ],
                        )
                      : null,
                    color: isSelected ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${table['number']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table['location'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFFFF6B35) : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.upTo} ${table['capacity']} ${table['capacity'] == 1 ? l10n.person : l10n.people}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFF6B35),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFloorPlan(List<Map<String, dynamic>> availableTables) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Título del plano
          Row(
            children: [
              const Icon(Icons.map, color: Color(0xFFFF6B35), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Plano SODITA - Piso Superior (8x16m)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Plano del salón 8x16 metros
          Expanded(
            child: Stack(
              children: [
                // Fondo del restaurante (proporción 8x16)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 3),
                  ),
                ),
                
                // Zona de ventanas (parte superior)
                Positioned(
                  top: 5,
                  left: 5,
                  right: 5,
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'VENTANAS - VISTA AL EXTERIOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Living/Área central
                Positioned(
                  left: 100,
                  top: 140,
                  width: 120,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.brown.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.weekend, color: Colors.brown, size: 20),
                          Text(
                            'LIVING',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // BARRAS (mesas altas)
                // Barra 1 - Ventana izquierda
                _buildTableOnPlan(1, const Offset(60, 60), availableTables, isBarra: true),
                
                // Barra 2 - Ventana derecha  
                _buildTableOnPlan(2, const Offset(260, 60), availableTables, isBarra: true),
                
                // Barra 7 - Rincón izquierdo
                _buildTableOnPlan(7, const Offset(30, 120), availableTables, isBarra: true),
                
                // Barra 10 - Cerca entrada
                _buildTableOnPlan(10, const Offset(160, 320), availableTables, isBarra: true),
                
                // MESAS BAJAS (alrededor del living)
                // Mesa 3 - Pared izquierda
                _buildTableOnPlan(3, const Offset(40, 180), availableTables),
                
                // Mesa 4 - Pared derecha
                _buildTableOnPlan(4, const Offset(280, 180), availableTables),
                
                // Mesa 5 - Fondo del salón
                _buildTableOnPlan(5, const Offset(160, 280), availableTables, isLarge: true),
                
                // Mesa 6 - Esquina derecha grande
                _buildTableOnPlan(6, const Offset(270, 250), availableTables, isLarge: true),
                
                // Mesa 8 - Centro derecha
                _buildTableOnPlan(8, const Offset(240, 140), availableTables),
                
                // Mesa 9 - Centro izquierda
                _buildTableOnPlan(9, const Offset(80, 140), availableTables),
                
                // Entrada principal
                Positioned(
                  bottom: 5,
                  left: 5,
                  right: 5,
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'ENTRADA PRINCIPAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leyenda actualizada
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Disponible', Colors.green),
                  _buildLegendItem('No disponible', Colors.grey),
                  _buildLegendItem('Seleccionada', const Color(0xFFFF6B35)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('🪑 Mesa baja', Colors.blue),
                  _buildLegendItem('🍷 Barra alta', Colors.purple),
                  _buildLegendItem('🛋️ Living', Colors.brown),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableOnPlan(int tableNumber, Offset position, List<Map<String, dynamic>> availableTables, {bool isLarge = false, bool isBarra = false}) {
    final table = tables.firstWhere((t) => t['number'] == tableNumber);
    final isAvailable = availableTables.any((t) => t['number'] == tableNumber);
    final isSelected = selectedTableNumber == tableNumber;
    
    Color tableColor;
    if (isSelected) {
      tableColor = const Color(0xFFFF6B35);
    } else if (isAvailable) {
      tableColor = Colors.green;
    } else {
      tableColor = Colors.grey;
    }
    
    final size = isLarge ? 50.0 : 40.0;
    
    return Positioned(
      left: position.dx - size/2,
      top: position.dy - size/2,
      child: GestureDetector(
        onTap: isAvailable ? () {
          setState(() {
            selectedTableNumber = tableNumber;
          });
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tableColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white : tableColor.withOpacity(0.7),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: tableColor.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$tableNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 16 : 14,
                ),
              ),
              if (isLarge)
                Text(
                  '${table['capacity']}p',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildReserveButton() {
    final canReserve = selectedTime != null && selectedTableNumber != null;
    
    return FadeInUp(
      delay: const Duration(milliseconds: 700),
      child: Column(
        children: [
          // Aviso de 15 minutos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ IMPORTANTE: Política de 15 minutos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tienes 15 minutos desde tu hora de reserva para llegar. Si no llegas a tiempo, tu mesa se liberará automáticamente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Reserva GRATIS!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Solo paga lo que consumas en el restaurante',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: canReserve ? _showReservationForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canReserve ? const Color(0xFFFF6B35) : Colors.grey.shade300,
                elevation: canReserve ? 8 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: canReserve ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    canReserve 
                      ? 'Reservar Mesa ${selectedTableNumber ?? ''}'
                      : 'Selecciona hora y mesa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: canReserve ? Colors.white : Colors.grey.shade600,
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mié';
      case 4: return 'Jue';
      case 5: return 'Vie';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }
  
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Ene';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Abr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Ago';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dic';
      default: return '';
    }
  }
  
  void _showReservationForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reserva Confirmada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Mesa ${selectedTableNumber} reservada para ${partySize} personas',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Hora: ${selectedTime!.format(context)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ RECORDATORIO: Tienes 15 minutos para llegar o se libera tu mesa.',
                style: TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAdminLogin() {
    showDialog(
      context: context,
      builder: (context) => AdminLoginDialog(),
    );
  }
}

class AdminLoginDialog extends StatefulWidget {
  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35),
                  const Color(0xFFFF8A65),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Acceso Admin'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email, color: Color(0xFFFF6B35)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B35),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF6B35)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B35),
                  width: 2,
                ),
              ),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Ingresar',
                style: TextStyle(color: Colors.white),
              ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Autenticación con Supabase
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (response.user != null) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> tablesStatus = [
    {'number': 1, 'capacity': 2, 'location': 'Ventana frontal', 'status': 'libre', 'customer': '', 'time': '', 'remaining': 0},
    {'number': 2, 'capacity': 2, 'location': 'Ventana lateral', 'status': 'libre', 'customer': '', 'time': '', 'remaining': 0},
    {'number': 3, 'capacity': 4, 'location': 'Centro del salón', 'status': 'ocupada', 'customer': 'Juan Pérez', 'time': '20:00', 'remaining': 8},
    {'number': 4, 'capacity': 4, 'location': 'Cerca de la ventana', 'status': 'libre', 'customer': '', 'time': '', 'remaining': 0},
    {'number': 5, 'capacity': 6, 'location': 'Mesa grande central', 'status': 'reservada', 'customer': 'María García', 'time': '20:30', 'remaining': 12},
    {'number': 6, 'capacity': 8, 'location': 'Mesa familiar grande', 'status': 'ocupada', 'customer': 'Familia López', 'time': '19:30', 'remaining': 3},
    {'number': 7, 'capacity': 2, 'location': 'Rincón privado', 'status': 'libre', 'customer': '', 'time': '', 'remaining': 0},
    {'number': 8, 'capacity': 4, 'location': 'Centro-derecha', 'status': 'reservada', 'customer': 'Carlos Ruiz', 'time': '21:00', 'remaining': 7},
    {'number': 9, 'capacity': 4, 'location': 'Centro-izquierda', 'status': 'libre', 'customer': '', 'time': '', 'remaining': 0},
    {'number': 10, 'capacity': 2, 'location': 'Mesa de la esquina', 'status': 'vencida', 'customer': 'Ana Torres', 'time': '19:00', 'remaining': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SODITA - Control de Mesas'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.1),
                    const Color(0xFFFF8A65).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickStat('Libres', _getTableCount('libre'), Colors.green),
                  ),
                  Expanded(
                    child: _buildQuickStat('Ocupadas', _getTableCount('ocupada'), Colors.red),
                  ),
                  Expanded(
                    child: _buildQuickStat('Reservadas', _getTableCount('reservada'), Colors.orange),
                  ),
                  Expanded(
                    child: _buildQuickStat('Vencidas', _getTableCount('vencida'), Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                _buildLegendItem('Libre', Colors.green),
                _buildLegendItem('Ocupada', Colors.red),
                _buildLegendItem('Reservada', Colors.orange),
                _buildLegendItem('Vencida', Colors.grey),
              ],
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Estado del Piso Superior',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: tablesStatus.length,
                itemBuilder: (context, index) {
                  return _buildTableCard(tablesStatus[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 12),
                  const Text('Política de 15 Minutos'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ Tiempo de gracia: 15 minutos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Si el comensal no llega en 15 minutos, la mesa se libera automáticamente'),
                  SizedBox(height: 8),
                  Text('• Las mesas vencidas aparecen en gris y pueden liberarse manualmente'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(color: Color(0xFFFF6B35)),
                  ),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFFFF6B35),
        label: const Text('Política 15 min'),
        icon: const Icon(Icons.schedule),
      ),
    );
  }
  
  Widget _buildQuickStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableCard(Map<String, dynamic> table) {
    Color statusColor;
    Color bgColor;
    IconData statusIcon;
    
    switch (table['status']) {
      case 'libre':
        statusColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        statusIcon = Icons.check_circle;
        break;
      case 'ocupada':
        statusColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        statusIcon = Icons.people;
        break;
      case 'reservada':
        statusColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        statusIcon = Icons.schedule;
        break;
      case 'vencida':
        statusColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        statusIcon = Icons.help;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${table['number']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              Icon(statusIcon, color: statusColor, size: 20),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            table['location'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          Text(
            '${table['capacity']} personas',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (table['status'] != 'libre') ...[
            Text(
              table['customer'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (table['status'] == 'reservada' || table['status'] == 'ocupada')
              Text(
                '${table['time']} (${table['remaining']} min)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
          ] else ...[
            Text(
              'Disponible',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  int _getTableCount(String status) {
    return tablesStatus.where((table) => table['status'] == status).length;
  }
}