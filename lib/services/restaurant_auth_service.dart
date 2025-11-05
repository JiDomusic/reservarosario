import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant.dart';
import '../supabase_config.dart';

class RestaurantAuthService extends ChangeNotifier {
  static final RestaurantAuthService _instance = RestaurantAuthService._internal();
  factory RestaurantAuthService() => _instance;
  RestaurantAuthService._internal();

  Restaurant? _currentRestaurant;
  bool _isAuthenticated = false;
  
  Restaurant? get currentRestaurant => _currentRestaurant;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentRestaurantId => _currentRestaurant?.id;

  // Login de restaurante con Supabase Auth
  Future<bool> loginRestaurant(String email, String password) async {
    try {
      // 1. Autenticar con Supabase Auth
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciales incorrectas');
      }

      // 2. Obtener datos del restaurante desde la base de datos
      final restaurantData = await supabase
          .from('restaurants')
          .select()
          .eq('auth_user_id', response.user!.id)
          .eq('is_active', true)
          .maybeSingle();

      if (restaurantData == null) {
        // Verificar si es un super admin
        final superAdminData = await supabase
            .from('super_admins')
            .select()
            .eq('auth_user_id', response.user!.id)
            .eq('is_active', true)
            .maybeSingle();
            
        if (superAdminData != null) {
          // Es super admin, manejar diferente
          throw Exception('Super admin detectado - usar panel de administración');
        }
        
        throw Exception('Restaurante no encontrado o inactivo');
      }

      // 3. Verificar que el restaurante esté aprobado
      if (!restaurantData['is_approved']) {
        throw Exception('Tu restaurante está pendiente de aprobación. Contacta al administrador.');
      }

      // 4. Crear objeto Restaurant desde datos de la BD
      _currentRestaurant = Restaurant.fromJson(restaurantData);
      _isAuthenticated = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error en login: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      _currentRestaurant = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error en logout: $e');
      // Logout local aunque falle el remoto
      _currentRestaurant = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  // Registrar nuevo restaurante con Supabase Auth
  Future<bool> registerRestaurant({
    required String name,
    required String description,
    required String email,
    required String password,
    required String address,
    required String phone,
    required int totalTables,
    String whatsapp = '',
    String? logoUrl,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al crear la cuenta');
      }

      // 2. Crear entrada en la tabla restaurants
      final restaurantData = await supabase.from('restaurants').insert({
        'name': name.toUpperCase(),
        'description': description,
        'email': email,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp.isEmpty ? null : whatsapp,
        'total_tables': totalTables,
        'auth_user_id': response.user!.id,
        'logo_url': logoUrl,
        'is_active': true,
        'is_open': false, // Empieza cerrado hasta que configuren
      }).select().single();

      // 3. Crear mesas automáticamente
      await _createTablesForRestaurant(restaurantData['id'], totalTables);
      
      // 4. Crear horarios por defecto
      await _createDefaultSchedules(restaurantData['id']);

      // 5. Crear objeto Restaurant
      final newRestaurant = Restaurant.fromJson(restaurantData);
      
      _currentRestaurant = newRestaurant;
      _isAuthenticated = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error en registro: $e');
      rethrow;
    }
  }

  // Crear mesas automáticamente para un restaurante
  Future<void> _createTablesForRestaurant(String restaurantId, int totalTables) async {
    final tables = <Map<String, dynamic>>[];
    
    for (int i = 1; i <= totalTables; i++) {
      tables.add({
        'restaurant_id': restaurantId,
        'table_number': i,
        'capacity': i <= (totalTables * 0.4) ? 2 : 
                   i <= (totalTables * 0.7) ? 4 : 6,
        'location': i <= (totalTables * 0.5) ? 'Interior' : 'Terraza',
        'is_available': true,
      });
    }
    
    await supabase.from('restaurant_tables').insert(tables);
  }

  // Crear horarios por defecto
  Future<void> _createDefaultSchedules(String restaurantId) async {
    final schedules = <Map<String, dynamic>>[];
    
    for (int day = 0; day <= 6; day++) {
      schedules.add({
        'restaurant_id': restaurantId,
        'day_of_week': day,
        'open_time': day == 0 ? '10:00:00' : '08:00:00', // Domingo abre más tarde
        'close_time': day == 0 || day == 6 ? '00:00:00' : '23:00:00', // Fines de semana cierran más tarde
        'is_closed': false,
      });
    }
    
    await supabase.from('restaurant_schedules').insert(schedules);
  }

  // Actualizar datos del restaurante
  Future<bool> updateRestaurant({
    String? name,
    String? description,
    String? address,
    String? phone,
    String? whatsapp,
    int? totalTables,
    String? logoUrl,
  }) async {
    if (_currentRestaurant == null) return false;
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentRestaurant = _currentRestaurant!.copyWith(
        name: name ?? _currentRestaurant!.name,
        description: description ?? _currentRestaurant!.description,
        address: address ?? _currentRestaurant!.address,
        phone: phone ?? _currentRestaurant!.phone,
        whatsapp: whatsapp ?? _currentRestaurant!.whatsapp,
        totalTables: totalTables ?? _currentRestaurant!.totalTables,
        logoUrl: logoUrl ?? _currentRestaurant!.logoUrl,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verificar si el email está disponible
  Future<bool> isEmailAvailable(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final restaurants = RestaurantData.getDemoRestaurants();
    return !restaurants.any((r) => r.email == email);
  }

  // Cambiar estado del restaurante (abierto/cerrado)
  Future<void> toggleRestaurantStatus() async {
    if (_currentRestaurant == null) return;
    
    _currentRestaurant = _currentRestaurant!.copyWith(
      isOpen: !_currentRestaurant!.isOpen,
      updatedAt: DateTime.now(),
    );
    
    notifyListeners();
  }

  // Obtener estadísticas rápidas
  Map<String, dynamic> getQuickStats() {
    if (_currentRestaurant == null) {
      return {
        'totalTables': 0,
        'availableTables': 0,
        'pendingReservations': 0,
        'rating': 0.0,
        'totalReviews': 0,
      };
    }
    
    return {
      'totalTables': _currentRestaurant!.totalTables,
      'availableTables': _currentRestaurant!.availableTables,
      'pendingReservations': _currentRestaurant!.pendingReservations,
      'rating': _currentRestaurant!.rating,
      'totalReviews': _currentRestaurant!.totalReviews,
    };
  }

  // Simular datos en tiempo real
  void startRealTimeUpdates() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentRestaurant != null && _isAuthenticated) {
        // Simular cambios en disponibilidad de mesas
        final random = DateTime.now().millisecond;
        final availableTables = (random % _currentRestaurant!.totalTables) + 1;
        final pendingReservations = random % 5;
        
        _currentRestaurant = _currentRestaurant!.copyWith(
          availableTables: availableTables,
          pendingReservations: pendingReservations,
          updatedAt: DateTime.now(),
        );
        
        notifyListeners();
      }
    });
  }
}