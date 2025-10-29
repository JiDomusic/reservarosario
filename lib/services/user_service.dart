import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

// SISTEMA DE USUARIOS ESTILO WOKI PARA SODITA
class UserService {
  static final _client = supabase;
  
  // Cache de usuario actual
  static Map<String, dynamic>? _currentUser;
  static String? _currentUserId;

  // VALIDACIÓN DE USUARIOS - FUNCIONALIDAD WOKI
  
  /// Crear o validar usuario en primera visita
  static Future<Map<String, dynamic>?> validateOrCreateUser({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      debugPrint('🔐 Validating user: $name - $phone');
      
      // Buscar usuario existente por teléfono
      final existingUser = await _client
          .from('sodita_usuarios')
          .select('*')
          .eq('telefono', phone)
          .maybeSingle();

      if (existingUser != null) {
        // Usuario existe - validar y actualizar info si es necesario
        _currentUser = existingUser;
        _currentUserId = existingUser['id'];
        
        // Actualizar nombre si cambió
        if (existingUser['nombre'] != name) {
          await _client
              .from('sodita_usuarios')
              .update({'nombre': name, 'ultima_actividad': DateTime.now().toIso8601String()})
              .eq('id', existingUser['id']);
        }
        
        debugPrint('✅ User validated: ${existingUser['nombre']} - Reputation: ${existingUser['reputacion']}');
        return existingUser;
      } else {
        // Nuevo usuario - crear con reputación inicial
        final newUser = await _client
            .from('sodita_usuarios')
            .insert({
              'nombre': name,
              'telefono': phone,
              'email': email,
              'reputacion': 100, // Reputación inicial Woki-style
              'total_reservas': 0,
              'total_no_shows': 0,
              'verificado': false, // Se verifica después de primera reserva exitosa
              'fecha_registro': DateTime.now().toIso8601String(),
              'ultima_actividad': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        _currentUser = newUser;
        _currentUserId = newUser['id'];
        
        debugPrint('🆕 New user created: ${newUser['nombre']} - Initial reputation: 100');
        return newUser;
      }
    } catch (e) {
      debugPrint('❌ Error validating user: $e');
      return null;
    }
  }

  /// Obtener usuario actual
  static Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  /// Obtener reputación del usuario
  static int getUserReputation() {
    return _currentUser?['reputacion'] ?? 100;
  }

  /// Verificar si el usuario está verificado
  static bool isUserVerified() {
    return _currentUser?['verificado'] ?? false;
  }

  /// Obtener historial de no-shows
  static int getUserNoShows() {
    return _currentUser?['total_no_shows'] ?? 0;
  }

  /// SISTEMA DE REPUTACIÓN WOKI
  
  /// Actualizar reputación después de una reserva
  static Future<bool> updateUserReputation({
    required String userId,
    required String reservationResult, // 'completed', 'no_show', 'cancelled'
  }) async {
    try {
      final user = await _client
          .from('sodita_usuarios')
          .select('*')
          .eq('id', userId)
          .single();

      int currentReputation = user['reputacion'] ?? 100;
      int totalReservations = user['total_reservas'] ?? 0;
      int totalNoShows = user['total_no_shows'] ?? 0;
      
      // Lógica de reputación estilo Woki
      switch (reservationResult) {
        case 'completed':
          // Completó la reserva exitosamente
          currentReputation = (currentReputation + 5).clamp(0, 100);
          totalReservations++;
          
          // Verificar usuario después de primera reserva exitosa
          if (totalReservations == 1) {
            await _client
                .from('sodita_usuarios')
                .update({'verificado': true})
                .eq('id', userId);
          }
          break;
          
        case 'no_show':
          // No se presentó - penalización fuerte estilo Woki
          currentReputation = (currentReputation - 20).clamp(0, 100);
          totalNoShows++;
          totalReservations++;
          break;
          
        case 'cancelled':
          // Canceló (con tiempo) - penalización menor
          currentReputation = (currentReputation - 2).clamp(0, 100);
          totalReservations++;
          break;
      }

      // Actualizar en base de datos
      await _client
          .from('sodita_usuarios')
          .update({
            'reputacion': currentReputation,
            'total_reservas': totalReservations,
            'total_no_shows': totalNoShows,
            'ultima_actividad': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Actualizar cache local
      if (_currentUserId == userId && _currentUser != null) {
        _currentUser!['reputacion'] = currentReputation;
        _currentUser!['total_reservas'] = totalReservations;
        _currentUser!['total_no_shows'] = totalNoShows;
      }

      debugPrint('📊 User reputation updated: $currentReputation ($reservationResult)');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user reputation: $e');
      return false;
    }
  }

  /// Verificar si el usuario puede hacer una reserva
  static bool canUserMakeReservation() {
    final reputation = getUserReputation();
    final noShows = getUserNoShows();
    
    // Lógica estilo Woki: usuarios con reputación muy baja tienen restricciones
    if (reputation < 30 || noShows > 3) {
      return false;
    }
    
    return true;
  }

  /// Obtener nivel de prioridad del usuario (para cola virtual)
  static String getUserPriorityLevel() {
    final reputation = getUserReputation();
    final isVerified = isUserVerified();
    
    if (!isVerified) return 'nuevo';
    if (reputation >= 90) return 'vip';
    if (reputation >= 70) return 'premium';
    if (reputation >= 50) return 'regular';
    return 'bajo';
  }

  /// HISTORIAL Y ESTADÍSTICAS
  
  /// Obtener historial de reservas del usuario
  static Future<List<Map<String, dynamic>>> getUserReservationHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final reservations = await _client
          .from('sodita_reservas')
          .select('''
            *,
            sodita_mesas!inner(numero, capacidad, ubicacion)
          ''')
          .eq('usuario_id', userId)
          .order('fecha', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(reservations);
    } catch (e) {
      debugPrint('❌ Error fetching user reservation history: $e');
      return [];
    }
  }

  /// Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final user = await _client
          .from('sodita_usuarios')
          .select('*')
          .eq('id', userId)
          .single();

      final reservations = await getUserReservationHistory(userId: userId, limit: 100);
      
      final completed = reservations.where((r) => r['estado'] == 'completada').length;
      final noShows = reservations.where((r) => r['estado'] == 'no_show').length;
      final cancelled = reservations.where((r) => r['estado'] == 'cancelada').length;
      
      final completionRate = reservations.isNotEmpty ? (completed / reservations.length * 100).round() : 0;
      
      return {
        'total_reservas': user['total_reservas'] ?? 0,
        'reputacion': user['reputacion'] ?? 100,
        'completadas': completed,
        'no_shows': noShows,
        'canceladas': cancelled,
        'tasa_completion': completionRate,
        'verificado': user['verificado'] ?? false,
        'nivel_prioridad': getUserPriorityLevel(),
        'miembro_desde': user['fecha_registro'],
      };
    } catch (e) {
      debugPrint('❌ Error getting user stats: $e');
      return {};
    }
  }

  /// REVIEWS VERIFICADOS ESTILO WOKI
  
  /// Verificar si el usuario puede dejar un review
  static Future<bool> canUserReview({
    required String userId,
    required String reservationId,
  }) async {
    try {
      // Solo usuarios verificados que completaron la reserva pueden reviewar
      final reservation = await _client
          .from('sodita_reservas')
          .select('estado, usuario_id')
          .eq('id', reservationId)
          .eq('usuario_id', userId)
          .eq('estado', 'completada')
          .maybeSingle();

      return reservation != null && isUserVerified();
    } catch (e) {
      debugPrint('❌ Error checking review permissions: $e');
      return false;
    }
  }

  /// Crear review verificado
  static Future<bool> createVerifiedReview({
    required String userId,
    required String reservationId,
    required int rating,
    String? comment,
  }) async {
    try {
      // Verificar permisos primero
      final canReview = await canUserReview(userId: userId, reservationId: reservationId);
      if (!canReview) {
        debugPrint('❌ User cannot review this reservation');
        return false;
      }

      // Crear review verificado
      await _client
          .from('sodita_reviews')
          .insert({
            'usuario_id': userId,
            'reserva_id': reservationId,
            'rating': rating,
            'comentario': comment,
            'verificado': true,
            'fecha': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ Verified review created: $rating stars');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating verified review: $e');
      return false;
    }
  }

  /// Limpiar cache del usuario
  static void clearUserCache() {
    _currentUser = null;
    _currentUserId = null;
  }
}