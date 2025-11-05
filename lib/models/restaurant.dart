import 'package:flutter/material.dart';
import '../supabase_config.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String coverImageUrl;
  final String address;
  final String phone;
  final String whatsapp;
  final String email;
  final int totalTables;
  final double rating;
  final int totalReviews;
  final String primaryColor;
  final String secondaryColor;
  final bool isActive;
  final bool isOpen;
  final int availableTables;
  final int pendingReservations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl = '',
    this.coverImageUrl = '',
    required this.address,
    required this.phone,
    this.whatsapp = '',
    required this.email,
    required this.totalTables,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.primaryColor = '#F86704',
    this.secondaryColor = '#10B981',
    this.isActive = true,
    this.isOpen = true,
    this.availableTables = 0,
    this.pendingReservations = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters para colores como objetos Color
  Color get primaryColorValue {
    try {
      return Color(int.parse(primaryColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFF86704);
    }
  }

  Color get secondaryColorValue {
    try {
      return Color(int.parse(secondaryColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF10B981);
    }
  }

  // Logo placeholder si no tiene logo
  String get logoText {
    if (name.isEmpty) return 'R';
    return name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join('').toUpperCase();
  }

  // Estados del restaurante
  String get statusText {
    if (!isActive) return 'Inactivo';
    if (!isOpen) return 'Cerrado';
    if (availableTables > 0) return 'Mesas disponibles';
    return 'Sin mesas disponibles';
  }

  Color get statusColor {
    if (!isActive) return const Color(0xFF6B7280);
    if (!isOpen) return const Color(0xFFEF4444);
    if (availableTables > 0) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  // copyWith method for updating restaurant data
  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? address,
    String? phone,
    String? whatsapp,
    String? email,
    int? totalTables,
    double? rating,
    int? totalReviews,
    String? primaryColor,
    String? secondaryColor,
    bool? isActive,
    bool? isOpen,
    int? availableTables,
    int? pendingReservations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      totalTables: totalTables ?? this.totalTables,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      availableTables: availableTables ?? this.availableTables,
      pendingReservations: pendingReservations ?? this.pendingReservations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper para parsear doubles desde diferentes tipos de datos
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    // Si es un Map u otro tipo, intentar extraer el valor
    if (value is Map) {
      // Podría ser un IdentityMap o similar, buscar valores numéricos
      for (var val in value.values) {
        if (val is double) return val;
        if (val is int) return val.toDouble();
      }
    }
    return 0.0;
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      coverImageUrl: json['cover_image_url'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      email: json['email'] ?? '',
      totalTables: json['total_tables'] ?? 0,
      rating: _parseDouble(json['average_rating']),
      totalReviews: json['total_reviews'] ?? 0,
      primaryColor: json['primary_color'] ?? '#F86704',
      secondaryColor: json['secondary_color'] ?? '#10B981',
      isActive: json['is_active'] ?? true,
      isOpen: json['is_open'] ?? true,
      availableTables: json['available_tables'] ?? 0,
      pendingReservations: json['pending_reservations'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Método para convertir a JSON para la base de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'cover_image_url': coverImageUrl,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'total_tables': totalTables,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'is_active': isActive,
      'is_open': isOpen,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Servicio para manejar restaurantes
class RestaurantData {
  // Obtener restaurantes desde Supabase
  static Future<List<Restaurant>> getRestaurantsFromDatabase() async {
    try {
      final response = await supabase
          .from('restaurant_summary')
          .select()
          .eq('is_active', true)
          .order('name');
      
      return response.map<Restaurant>((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error cargando restaurantes: $e');
      return getDemoRestaurants(); // Fallback a datos demo
    }
  }

  // Datos demo de los 10 restaurantes (fallback)
  static List<Restaurant> getDemoRestaurants() {
    final now = DateTime.now();
    
    return [
      // SODITA - El restaurante original
      Restaurant(
        id: 'sodita',
        name: 'SODITA',
        description: 'El restaurante original - Experiencia premium completa.\n\n🏢 LAYOUT FÍSICO:\n• Capacidad total: 50 personas en 10 mesas\n• 1 Living con sofás (12 personas)\n• 4 Mesas altas de barra (16 personas)\n• 5 Mesas bajas comunes (20 personas)\n• Ubicación: Solo planta alta\n• Ambiente: Interior acogedor\n\n📍 Todas las reservas son para la planta alta únicamente.',
        address: 'Laprida 1301, Rosario 2000',
        phone: '+54 341 456-7888',
        email: 'admin@sodita.com',
        totalTables: 10,
        rating: 4.9,
        totalReviews: 250,
        availableTables: 5,
        pendingReservations: 3,
        primaryColor: '#F86704',
        secondaryColor: '#10B981',
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '1',
        name: 'AMELIE PETIT CAFE',
        description: 'Café francés con ambiente íntimo y deliciosa repostería artesanal',
        address: 'Av. Pellegrini 1234, Rosario',
        phone: '+54 341 456-7890',
        email: 'admin@ameliepetitcafe.com',
        totalTables: 12,
        rating: 4.8,
        totalReviews: 124,
        availableTables: 3,
        pendingReservations: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '2',
        name: 'LA COCINA DE MAMA',
        description: 'Comida casera argentina con el sabor de la abuela',
        address: 'San Martín 567, Rosario',
        phone: '+54 341 456-7891',
        email: 'admin@lacocinademama.com',
        totalTables: 15,
        rating: 4.6,
        totalReviews: 89,
        availableTables: 5,
        pendingReservations: 1,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '3',
        name: 'PIZZA CORNER',
        description: 'Las mejores pizzas artesanales de la ciudad',
        address: 'Córdoba 890, Rosario',
        phone: '+54 341 456-7892',
        email: 'admin@pizzacorner.com',
        totalTables: 20,
        rating: 4.7,
        totalReviews: 156,
        availableTables: 8,
        pendingReservations: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '4',
        name: 'SUSHI ZEN',
        description: 'Auténtica cocina japonesa y sushi fresco',
        address: 'Montevideo 345, Rosario',
        phone: '+54 341 456-7893',
        email: 'admin@sushizen.com',
        totalTables: 18,
        rating: 4.9,
        totalReviews: 201,
        availableTables: 2,
        pendingReservations: 4,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '5',
        name: 'PARRILLA DON CARLOS',
        description: 'Carnes premium y parrilla tradicional argentina',
        address: 'Rioja 678, Rosario',
        phone: '+54 341 456-7894',
        email: 'admin@parrilladoncarlos.com',
        totalTables: 25,
        rating: 4.5,
        totalReviews: 178,
        availableTables: 12,
        pendingReservations: 1,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '6',
        name: 'VERDE NATURAL',
        description: 'Cocina vegetariana y vegana saludable',
        address: 'Entre Ríos 234, Rosario',
        phone: '+54 341 456-7895',
        email: 'admin@verdenatural.com',
        totalTables: 14,
        rating: 4.4,
        totalReviews: 67,
        availableTables: 6,
        pendingReservations: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '7',
        name: 'MARISCOS DEL PUERTO',
        description: 'Pescados y mariscos frescos del día',
        address: 'Av. Belgrano 789, Rosario',
        phone: '+54 341 456-7896',
        email: 'admin@mariscospuerto.com',
        totalTables: 16,
        rating: 4.3,
        totalReviews: 92,
        availableTables: 0,
        pendingReservations: 2,
        isOpen: false,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '8',
        name: 'TACO LOCO',
        description: 'Comida mexicana auténtica y picante',
        address: 'Mitre 456, Rosario',
        phone: '+54 341 456-7897',
        email: 'admin@tacoloco.com',
        totalTables: 22,
        rating: 4.6,
        totalReviews: 134,
        availableTables: 9,
        pendingReservations: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '9',
        name: 'PASTA BELLA',
        description: 'Pastas artesanales y cocina italiana tradicional',
        address: 'Urquiza 123, Rosario',
        phone: '+54 341 456-7898',
        email: 'admin@pastabella.com',
        totalTables: 19,
        rating: 4.7,
        totalReviews: 145,
        availableTables: 4,
        pendingReservations: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Restaurant(
        id: '10',
        name: 'BRUNCH CLUB',
        description: 'Desayunos gourmet y brunch todo el día',
        address: 'Sarmiento 321, Rosario',
        phone: '+54 341 456-7899',
        email: 'admin@brunchclub.com',
        totalTables: 13,
        rating: 4.8,
        totalReviews: 98,
        availableTables: 7,
        pendingReservations: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static Restaurant? getById(String id) {
    try {
      return getDemoRestaurants().firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}