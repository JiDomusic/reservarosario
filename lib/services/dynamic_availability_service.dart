import 'package:flutter/foundation.dart';
import '../supabase_config.dart';

// 🔄 SERVICIO DE DISPONIBILIDAD DINÁMICA PARA MESAS EN TIEMPO REAL
class DynamicAvailabilityService {
  static final _client = supabase;
  
  // Cache optimizado para actualizaciones rápidas
  static final Map<String, int> _availabilityCache = {};
  static DateTime? _lastUpdate;
  static const Duration _cacheValidTime = Duration(seconds: 10);

  /// Obtener mesas disponibles para un restaurante específico en tiempo real
  static Future<int> getAvailableTablesCount(String restaurantId) async {
    try {
      // Verificar cache
      if (_isCacheValid(restaurantId)) {
        return _availabilityCache[restaurantId] ?? 0;
      }

      debugPrint('🔄 Calculando mesas disponibles para $restaurantId...');
      
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      // Solo SODITA tiene implementación real, otros restaurantes usan valores fijos
      if (restaurantId == 'sodita' || restaurantId.toLowerCase() == 'sodita') {
        return await _getSoditaAvailableTables(today);
      }
      
      // Para otros restaurantes, devolver valores simulados sin acceder a BD
      return _getSimulatedAvailability(restaurantId);
      
    } catch (e) {
      debugPrint('❌ Error calculando disponibilidad para $restaurantId: $e');
      return 0;
    }
  }

  /// Lógica específica para SODITA (usa las mismas tablas que la app principal)
  static Future<int> _getSoditaAvailableTables(String date) async {
    try {
      // Obtener todas las mesas de SODITA
      final allTables = await _client
          .from('sodita_mesas')
          .select('id')
          .eq('activa', true);

      if (allTables.isEmpty) {
        // Si no hay mesas en BD, usar las 10 mesas originales
        return 10;
      }

      final totalTables = allTables.length;

      // Obtener mesas ocupadas/reservadas HOY
      final occupiedTables = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', date)
          .or('estado.eq.confirmada,estado.eq.en_mesa');

      final occupiedIds = occupiedTables.map((r) => r['mesa_id']).toSet();
      final availableTables = totalTables - occupiedIds.length;

      // Actualizar cache
      _availabilityCache['sodita'] = availableTables;
      _lastUpdate = DateTime.now();

      debugPrint('✅ SODITA: $availableTables mesas disponibles de $totalTables');
      return availableTables;

    } catch (e) {
      debugPrint('❌ Error calculando mesas SODITA: $e');
      return 5; // Fallback
    }
  }

  /// Valores simulados para otros restaurantes (sin acceso a BD)
  static int _getSimulatedAvailability(String restaurantId) {
    // Para restaurantes de prueba con IDs que contienen '_mesas'
    if (restaurantId.contains('_mesas')) {
      final match = RegExp(r'(\d+)_mesas').firstMatch(restaurantId);
      if (match != null) {
        final totalTables = int.parse(match.group(1)!);
        debugPrint('🔍 Restaurante de prueba: $restaurantId tiene $totalTables mesas');
        
        // Para restaurantes de prueba, asumir 20% ocupación
        final availableTables = (totalTables * 0.8).round();
        
        // Actualizar cache
        _availabilityCache[restaurantId] = availableTables;
        _lastUpdate = DateTime.now();
        
        return availableTables;
      }
    }

    // Para otros restaurantes, valores fijos simulados
    final simulatedValues = {
      'palacio-tango': 6,
      'la-estancia': 4,
      'puerto-madero': 8,
      'tango-club': 3,
    };

    final available = simulatedValues[restaurantId] ?? 5; // Default 5 mesas
    
    // Actualizar cache
    _availabilityCache[restaurantId] = available;
    _lastUpdate = DateTime.now();
    
    debugPrint('🎭 Simulación: $restaurantId tiene $available mesas disponibles');
    return available;
  }

  /// Verificar si el cache sigue siendo válido
  static bool _isCacheValid(String restaurantId) {
    if (_lastUpdate == null || !_availabilityCache.containsKey(restaurantId)) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastUpdate!).inMilliseconds < _cacheValidTime.inMilliseconds;
  }

  /// Obtener disponibilidad para múltiples restaurantes
  static Future<Map<String, int>> getMultipleAvailability(List<String> restaurantIds) async {
    final results = <String, int>{};
    
    // Procesar en paralelo para mejor rendimiento
    final futures = restaurantIds.map((id) => getAvailableTablesCount(id));
    final availability = await Future.wait(futures);
    
    for (int i = 0; i < restaurantIds.length; i++) {
      results[restaurantIds[i]] = availability[i];
    }
    
    return results;
  }

  /// Invalidar cache manualmente (útil después de crear/cancelar reservas)
  static void invalidateCache([String? restaurantId]) {
    if (restaurantId != null) {
      _availabilityCache.remove(restaurantId);
    } else {
      _availabilityCache.clear();
    }
    _lastUpdate = null;
  }

  /// Escuchar cambios en tiempo real (para widgets que necesitan actualizaciones automáticas)
  static Stream<int> getAvailabilityStream(String restaurantId) async* {
    while (true) {
      try {
        final availability = await getAvailableTablesCount(restaurantId);
        yield availability;
        
        // Esperar 30 segundos antes de la siguiente actualización
        await Future.delayed(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('❌ Error en stream de disponibilidad: $e');
        yield 0;
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  /// Actualización manual para forzar recálculo
  static Future<int> forceRefresh(String restaurantId) async {
    invalidateCache(restaurantId);
    return await getAvailableTablesCount(restaurantId);
  }
}