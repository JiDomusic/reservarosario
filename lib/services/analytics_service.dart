import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../supabase_config.dart';

// SISTEMA DE MÉTRICAS Y ANALYTICS AVANZADOS ESTILO WOKI PARA SODITA
class AnalyticsService {
  static final _client = supabase;
  static final _analytics = FirebaseAnalytics.instance;
  
  // Cache para métricas en tiempo real
  static Map<String, dynamic> _metricsCache = {};
  static DateTime? _lastMetricsUpdate;

  // MÉTRICAS EN TIEMPO REAL

  /// Dashboard principal - métricas en tiempo real
  static Future<Map<String, dynamic>> getRealTimeMetrics() async {
    try {
      debugPrint('📊 Fetching real-time metrics...');
      
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      // Usar cache si es reciente (últimos 30 segundos)
      if (_lastMetricsUpdate != null && 
          now.difference(_lastMetricsUpdate!).inSeconds < 30) {
        return _metricsCache;
      }

      // Métricas de hoy en paralelo
      final results = await Future.wait([
        _getTableOccupancyMetrics(),
        _getReservationMetrics(today),
        _getQueueMetrics(),
        _getUserBehaviorMetrics(),
        _getRevenueMetrics(today),
      ]);

      _metricsCache = {
        'timestamp': now.toIso8601String(),
        'mesas': results[0],
        'reservas': results[1],
        'cola': results[2],
        'usuarios': results[3],
        'ingresos': results[4],
      };
      
      _lastMetricsUpdate = now;
      
      debugPrint('✅ Real-time metrics updated');
      return _metricsCache;
    } catch (e) {
      debugPrint('❌ Error getting real-time metrics: $e');
      return {};
    }
  }

  /// Métricas de ocupación de mesas
  static Future<Map<String, dynamic>> _getTableOccupancyMetrics() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Total de mesas
      final totalTables = await _client
          .from('sodita_mesas')
          .select('count')
          .eq('activa', true);

      // Mesas ocupadas ahora
      final occupiedTables = await _client
          .from('sodita_reservas')
          .select('count')
          .eq('fecha', today)
          .eq('estado', 'en_mesa');

      // Mesas reservadas (confirmadas)
      final reservedTables = await _client
          .from('sodita_reservas')
          .select('count')
          .eq('fecha', today)
          .eq('estado', 'confirmada');

      final total = totalTables[0]['count'] ?? 0;
      final occupied = occupiedTables[0]['count'] ?? 0;
      final reserved = reservedTables[0]['count'] ?? 0;
      final available = total - occupied - reserved;
      
      final occupancyRate = total > 0 ? ((occupied / total * 100).round()) : 0;

      return {
        'total_mesas': total,
        'ocupadas_ahora': occupied,
        'reservadas': reserved,
        'disponibles': available,
        'tasa_ocupacion': occupancyRate,
        'capacidad_utilizada': occupied + reserved,
      };
    } catch (e) {
      debugPrint('❌ Error getting table occupancy metrics: $e');
      return {};
    }
  }

  /// Métricas de reservas del día
  static Future<Map<String, dynamic>> _getReservationMetrics(String date) async {
    try {
      final reservations = await _client
          .from('sodita_reservas')
          .select('estado, tipo_reserva, personas, hora')
          .eq('fecha', date);

      final total = reservations.length;
      final completed = reservations.where((r) => r['estado'] == 'completada').length;
      final noShows = reservations.where((r) => r['estado'] == 'no_show').length;
      final inProgress = reservations.where((r) => r['estado'] == 'en_mesa').length;
      final pending = reservations.where((r) => r['estado'] == 'confirmada').length;
      
      final mesaYaReservations = reservations.where((r) => r['tipo_reserva'] == 'mesaya').length;
      final queueReservations = reservations.where((r) => r['tipo_reserva'] == 'cola_virtual').length;
      
      final totalGuests = reservations.fold<int>(0, (sum, r) => sum + ((r['personas'] ?? 0) as int));
      
      final completionRate = total > 0 ? ((completed / total * 100).round()) : 0;
      final noShowRate = total > 0 ? ((noShows / total * 100).round()) : 0;

      // Análisis por horarios
      final hourlyBreakdown = <String, int>{};
      for (final reservation in reservations) {
        final hour = reservation['hora']?.toString().split(':')[0] ?? '00';
        hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + 1;
      }

      return {
        'total_reservas': total,
        'completadas': completed,
        'no_shows': noShows,
        'en_progreso': inProgress,
        'pendientes': pending,
        'mesaya_reservas': mesaYaReservations,
        'cola_reservas': queueReservations,
        'total_comensales': totalGuests,
        'tasa_completion': completionRate,
        'tasa_no_show': noShowRate,
        'promedio_personas_reserva': total > 0 ? (totalGuests ~/ total) : 0,
        'breakdown_horario': hourlyBreakdown,
      };
    } catch (e) {
      debugPrint('❌ Error getting reservation metrics: $e');
      return {};
    }
  }

  /// Métricas de cola virtual
  static Future<Map<String, dynamic>> _getQueueMetrics() async {
    try {
      final queue = await _client
          .from('sodita_cola_virtual')
          .select('prioridad, personas, fecha_ingreso')
          .eq('estado', 'esperando');

      final totalInQueue = queue.length;
      
      final priorityBreakdown = <String, int>{};
      int totalWaitingGuests = 0;
      
      for (final entry in queue) {
        final priority = entry['prioridad'] ?? 'regular';
        priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
        totalWaitingGuests += (entry['personas'] as num?)?.toInt() ?? 0;
      }

      // Calcular tiempo promedio de espera
      double avgWaitMinutes = 0;
      if (queue.isNotEmpty) {
        final now = DateTime.now();
        final totalWaitTime = queue.fold<int>(0, (sum, entry) {
          final entryTime = DateTime.parse(entry['fecha_ingreso']);
          return sum + now.difference(entryTime).inMinutes;
        });
        avgWaitMinutes = totalWaitTime / queue.length;
      }

      return {
        'total_en_cola': totalInQueue,
        'comensales_esperando': totalWaitingGuests,
        'tiempo_promedio_espera': avgWaitMinutes.round().toInt(),
        'breakdown_prioridad': priorityBreakdown,
        'cola_activa': totalInQueue > 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting queue metrics: $e');
      return {};
    }
  }

  /// Métricas de comportamiento de usuarios
  static Future<Map<String, dynamic>> _getUserBehaviorMetrics() async {
    try {
      final users = await _client
          .from('sodita_usuarios')
          .select('reputacion, total_reservas, total_no_shows, verificado');

      final totalUsers = users.length;
      final verifiedUsers = users.where((u) => u['verificado'] == true).length;
      
      final reputationSum = users.fold<int>(0, (sum, u) => sum + ((u['reputacion'] ?? 0) as int));
      final avgReputation = totalUsers > 0 ? (reputationSum ~/ totalUsers) : 0;
      
      final highRepUsers = users.where((u) => (u['reputacion'] ?? 0) >= 80).length;
      final lowRepUsers = users.where((u) => (u['reputacion'] ?? 0) < 50).length;
      
      final totalReservations = users.fold<int>(0, (sum, u) => sum + ((u['total_reservas'] as num?)?.toInt() ?? 0));
      final totalNoShows = users.fold<int>(0, (sum, u) => sum + ((u['total_no_shows'] as num?)?.toInt() ?? 0));
      
      final overallNoShowRate = totalReservations > 0 ? ((totalNoShows / totalReservations * 100).round()) : 0;

      return {
        'total_usuarios': totalUsers,
        'usuarios_verificados': verifiedUsers,
        'reputacion_promedio': avgReputation,
        'usuarios_alta_reputacion': highRepUsers,
        'usuarios_baja_reputacion': lowRepUsers,
        'tasa_verificacion': totalUsers > 0 ? ((verifiedUsers / totalUsers * 100).round()) : 0,
        'tasa_no_show_general': overallNoShowRate,
      };
    } catch (e) {
      debugPrint('❌ Error getting user behavior metrics: $e');
      return {};
    }
  }

  /// Métricas de ingresos estimados
  static Future<Map<String, dynamic>> _getRevenueMetrics(String date) async {
    try {
      final completedReservations = await _client
          .from('sodita_reservas')
          .select('personas')
          .eq('fecha', date)
          .eq('estado', 'completada');

      // Estimación de ingresos (ticket promedio por persona)
      const avgTicketPerPerson = 2500; // Pesos argentinos promedio
      
      final totalCompletedGuests = completedReservations.fold<int>(0, (sum, r) => sum + ((r['personas'] as num?)?.toInt() ?? 0));
      final estimatedRevenue = totalCompletedGuests * avgTicketPerPerson;
      
      // Comparar con días anteriores
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      final yesterdayReservations = await _client
          .from('sodita_reservas')
          .select('personas')
          .eq('fecha', yesterday)
          .eq('estado', 'completada');
      
      final yesterdayGuests = yesterdayReservations.fold<int>(0, (sum, r) => sum + ((r['personas'] as num?)?.toInt() ?? 0));
      final yesterdayRevenue = yesterdayGuests * avgTicketPerPerson;
      
      final revenueChange = yesterdayRevenue > 0 ? 
          ((estimatedRevenue - yesterdayRevenue) / yesterdayRevenue * 100).round().toInt() : 0;

      return {
        'comensales_completados_hoy': totalCompletedGuests,
        'ingresos_estimados_hoy': estimatedRevenue,
        'comensales_ayer': yesterdayGuests,
        'ingresos_ayer': yesterdayRevenue,
        'cambio_porcentual': revenueChange,
        'ticket_promedio_persona': avgTicketPerPerson,
      };
    } catch (e) {
      debugPrint('❌ Error getting revenue metrics: $e');
      return {};
    }
  }

  // ANALYTICS HISTÓRICOS

  /// Análisis de tendencias (7, 15, 30 días)
  static Future<Map<String, dynamic>> getTrendAnalysis({
    int days = 7,
  }) async {
    try {
      debugPrint('📈 Analyzing trends for last $days days...');
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final reservations = await _client
          .from('sodita_reservas')
          .select('fecha, estado, personas, tipo_reserva')
          .gte('fecha', startDate.toIso8601String().split('T')[0])
          .lte('fecha', endDate.toIso8601String().split('T')[0]);

      // Análisis día por día
      final dailyStats = <String, Map<String, int>>{};
      
      for (final reservation in reservations) {
        final date = reservation['fecha'];
        if (dailyStats[date] == null) {
          dailyStats[date] = {
            'total': 0,
            'completed': 0,
            'no_shows': 0,
            'guests': 0,
            'mesaya': 0,
          };
        }
        
        dailyStats[date]!['total'] = dailyStats[date]!['total']! + 1;
        dailyStats[date]!['guests'] = dailyStats[date]!['guests']! + ((reservation['personas'] ?? 0) as int);
        
        if (reservation['estado'] == 'completada') {
          dailyStats[date]!['completed'] = dailyStats[date]!['completed']! + 1;
        } else if (reservation['estado'] == 'no_show') {
          dailyStats[date]!['no_shows'] = dailyStats[date]!['no_shows']! + 1;
        }
        
        if (reservation['tipo_reserva'] == 'mesaya') {
          dailyStats[date]!['mesaya'] = dailyStats[date]!['mesaya']! + 1;
        }
      }

      // Calcular tendencias
      final totalReservations = reservations.length;
      final avgDailyReservations = totalReservations / days;
      final totalGuests = reservations.fold<int>(0, (sum, r) => sum + ((r['personas'] ?? 0) as int));
      final avgDailyGuests = totalGuests / days;
      
      final completedReservations = reservations.where((r) => r['estado'] == 'completada').length;
      final noShows = reservations.where((r) => r['estado'] == 'no_show').length;
      
      final completionRate = totalReservations > 0 ? (completedReservations / totalReservations * 100) : 0;
      final noShowRate = totalReservations > 0 ? (noShows / totalReservations * 100) : 0;

      return {
        'periodo_dias': days,
        'total_reservas': totalReservations,
        'promedio_diario_reservas': avgDailyReservations.round().toInt(),
        'total_comensales': totalGuests,
        'promedio_diario_comensales': avgDailyGuests.round().toInt(),
        'tasa_completion': completionRate.round().toInt(),
        'tasa_no_show': noShowRate.round().toInt(),
        'estadisticas_diarias': dailyStats,
        'mejor_dia': _findBestDay(dailyStats),
        'peor_dia': _findWorstDay(dailyStats),
      };
    } catch (e) {
      debugPrint('❌ Error getting trend analysis: $e');
      return {};
    }
  }

  /// Encontrar mejor día
  static Map<String, dynamic> _findBestDay(Map<String, Map<String, int>> dailyStats) {
    String bestDate = '';
    int maxCompleted = 0;
    
    dailyStats.forEach((date, stats) {
      if (stats['completed']! > maxCompleted) {
        maxCompleted = stats['completed']!;
        bestDate = date;
      }
    });
    
    return {
      'fecha': bestDate,
      'reservas_completadas': maxCompleted,
    };
  }

  /// Encontrar peor día
  static Map<String, dynamic> _findWorstDay(Map<String, Map<String, int>> dailyStats) {
    String worstDate = '';
    double maxNoShowRate = 0;
    
    dailyStats.forEach((date, stats) {
      final total = stats['total']!;
      final noShows = stats['no_shows']!;
      final noShowRate = total > 0 ? (noShows / total).toDouble() : 0.0;
      
      if (noShowRate > maxNoShowRate) {
        maxNoShowRate = noShowRate;
        worstDate = date;
      }
    });
    
    return {
      'fecha': worstDate,
      'tasa_no_show': (maxNoShowRate * 100).round().toInt(),
    };
  }

  // EVENTOS FIREBASE ANALYTICS

  /// Tracking de evento: Reserva creada
  static Future<void> trackReservationCreated({
    required String reservationType, // 'normal', 'mesaya', 'cola_virtual'
    required int tableNumber,
    required int partySize,
    required String userPriority,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'reservation_created',
        parameters: {
          'reservation_type': reservationType,
          'table_number': tableNumber,
          'party_size': partySize,
          'user_priority': userPriority,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('❌ Error tracking reservation created: $e');
    }
  }

  /// Tracking de evento: Usuario unido a cola
  static Future<void> trackQueueJoined({
    required int queuePosition,
    required int estimatedWaitTime,
    required String userPriority,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'queue_joined',
        parameters: {
          'queue_position': queuePosition,
          'estimated_wait_time': estimatedWaitTime,
          'user_priority': userPriority,
        },
      );
    } catch (e) {
      debugPrint('❌ Error tracking queue joined: $e');
    }
  }

  /// Tracking de evento: No-show detectado
  static Future<void> trackNoShow({
    required int tableNumber,
    required String userReputation,
    required bool wasAutomatic,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'no_show_detected',
        parameters: {
          'table_number': tableNumber,
          'user_reputation': userReputation,
          'was_automatic': wasAutomatic,
        },
      );
    } catch (e) {
      debugPrint('❌ Error tracking no show: $e');
    }
  }

  /// Tracking de evento: Review creado
  static Future<void> trackReviewCreated({
    required int rating,
    required bool hasComment,
    required bool isVerified,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'review_created',
        parameters: {
          'rating': rating,
          'has_comment': hasComment,
          'is_verified': isVerified,
        },
      );
    } catch (e) {
      debugPrint('❌ Error tracking review created: $e');
    }
  }

  // REPORTES AVANZADOS

  /// Generar reporte completo
  static Future<Map<String, dynamic>> generateFullReport({
    int days = 30,
  }) async {
    try {
      debugPrint('📊 Generating full analytics report...');
      
      final results = await Future.wait([
        getRealTimeMetrics(),
        getTrendAnalysis(days: days),
        _getHourlyPatterns(),
        _getTablePerformance(),
        _getUserSegmentation(),
      ]);

      return {
        'fecha_reporte': DateTime.now().toIso8601String(),
        'periodo_dias': days,
        'metricas_tiempo_real': results[0],
        'analisis_tendencias': results[1],
        'patrones_horarios': results[2],
        'rendimiento_mesas': results[3],
        'segmentacion_usuarios': results[4],
      };
    } catch (e) {
      debugPrint('❌ Error generating full report: $e');
      return {};
    }
  }

  /// Análisis de patrones horarios
  static Future<Map<String, dynamic>> _getHourlyPatterns() async {
    try {
      final last7Days = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
      
      final reservations = await _client
          .from('sodita_reservas')
          .select('hora, estado')
          .gte('fecha', last7Days);

      final hourlyData = <int, Map<String, int>>{};
      
      for (final reservation in reservations) {
        final hour = int.parse(reservation['hora'].split(':')[0]);
        hourlyData[hour] ??= {'total': 0, 'completed': 0, 'no_shows': 0};
        
        hourlyData[hour]!['total'] = hourlyData[hour]!['total']! + 1;
        if (reservation['estado'] == 'completada') {
          hourlyData[hour]!['completed'] = hourlyData[hour]!['completed']! + 1;
        } else if (reservation['estado'] == 'no_show') {
          hourlyData[hour]!['no_shows'] = hourlyData[hour]!['no_shows']! + 1;
        }
      }

      // Encontrar horario pico
      int peakHour = 12;
      int maxReservations = 0;
      
      hourlyData.forEach((hour, data) {
        if (data['total']! > maxReservations) {
          maxReservations = data['total']!;
          peakHour = hour;
        }
      });

      return {
        'datos_por_hora': hourlyData,
        'hora_pico': peakHour,
        'reservas_hora_pico': maxReservations,
      };
    } catch (e) {
      debugPrint('❌ Error getting hourly patterns: $e');
      return {};
    }
  }

  /// Análisis de rendimiento por mesa
  static Future<Map<String, dynamic>> _getTablePerformance() async {
    try {
      final last30Days = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
      
      final reservations = await _client
          .from('sodita_reservas')
          .select('mesa_id, estado, sodita_mesas!inner(numero, ubicacion)')
          .gte('fecha', last30Days);

      final tableStats = <String, Map<String, dynamic>>{};
      
      for (final reservation in reservations) {
        final tableId = reservation['mesa_id'];
        final tableNumber = reservation['sodita_mesas']['numero'];
        final tableLocation = reservation['sodita_mesas']['ubicacion'];
        
        tableStats[tableId] ??= {
          'numero': tableNumber,
          'ubicacion': tableLocation,
          'total_reservas': 0,
          'completadas': 0,
          'no_shows': 0,
        };
        
        tableStats[tableId]!['total_reservas'] = tableStats[tableId]!['total_reservas'] + 1;
        
        if (reservation['estado'] == 'completada') {
          tableStats[tableId]!['completadas'] = tableStats[tableId]!['completadas'] + 1;
        } else if (reservation['estado'] == 'no_show') {
          tableStats[tableId]!['no_shows'] = tableStats[tableId]!['no_shows'] + 1;
        }
      }

      // Calcular tasas de rendimiento
      tableStats.forEach((tableId, stats) {
        final total = stats['total_reservas'];
        stats['tasa_completion'] = total > 0 ? ((stats['completadas'] / total * 100).round()) : 0;
        stats['tasa_no_show'] = total > 0 ? ((stats['no_shows'] / total * 100).round()) : 0;
      });

      return tableStats;
    } catch (e) {
      debugPrint('❌ Error getting table performance: $e');
      return {};
    }
  }

  /// Segmentación de usuarios
  static Future<Map<String, dynamic>> _getUserSegmentation() async {
    try {
      final users = await _client
          .from('sodita_usuarios')
          .select('reputacion, total_reservas, total_no_shows, verificado');

      final segments = {
        'nuevos': 0,        // 0 reservas
        'ocasionales': 0,   // 1-3 reservas
        'regulares': 0,     // 4-10 reservas
        'frecuentes': 0,    // 11+ reservas
        'vip': 0,          // Alta reputación + muchas reservas
        'problematicos': 0, // Baja reputación
      };

      for (final user in users) {
        final reservas = user['total_reservas'] ?? 0;
        final reputacion = user['reputacion'] ?? 100;
        final noShows = user['total_no_shows'] ?? 0;
        
        if (reputacion < 50 || noShows > 3) {
          segments['problematicos'] = segments['problematicos']! + 1;
        } else if (reputacion >= 90 && reservas >= 10) {
          segments['vip'] = segments['vip']! + 1;
        } else if (reservas == 0) {
          segments['nuevos'] = segments['nuevos']! + 1;
        } else if (reservas <= 3) {
          segments['ocasionales'] = segments['ocasionales']! + 1;
        } else if (reservas <= 10) {
          segments['regulares'] = segments['regulares']! + 1;
        } else {
          segments['frecuentes'] = segments['frecuentes']! + 1;
        }
      }

      return segments;
    } catch (e) {
      debugPrint('❌ Error getting user segmentation: $e');
      return {};
    }
  }

  /// Limpiar cache de métricas
  static void clearMetricsCache() {
    _metricsCache.clear();
    _lastMetricsUpdate = null;
  }
}