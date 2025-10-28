import 'package:flutter/foundation.dart';
import '../supabase_config.dart';
import 'user_service.dart';

// SISTEMA DE COLA VIRTUAL Y MESAYA! ESTILO WOKI PARA SODITA
class QueueService {
  static final _client = supabase;
  
  // Cache para cola en tiempo real
  static List<Map<String, dynamic>> _currentQueue = [];
  static DateTime? _lastQueueUpdate;

  // MESAYA! - MESAS DISPONIBLES AHORA MISMO
  
  /// Obtener mesas disponibles para MesaYa! (inmediato)
  static Future<List<Map<String, dynamic>>> getAvailableTablesNow() async {
    try {
      debugPrint('🔍 Searching for MesaYa! tables...');
      
      // Obtener todas las mesas
      final allTables = await _client
          .from('sodita_mesas')
          .select('*')
          .eq('activa', true)
          .order('numero');

      // Obtener mesas ocupadas/reservadas HOY
      final today = DateTime.now().toIso8601String().split('T')[0];
      final occupiedTables = await _client
          .from('sodita_reservas')
          .select('mesa_id')
          .eq('fecha', today)
          .or('estado.eq.confirmada,estado.eq.en_mesa');

      final occupiedIds = occupiedTables.map((r) => r['mesa_id']).toSet();
      
      // Filtrar mesas disponibles
      final availableTables = allTables
          .where((table) => !occupiedIds.contains(table['id']))
          .toList();

      debugPrint('✅ Found ${availableTables.length} tables available for MesaYa!');
      return availableTables;
    } catch (e) {
      debugPrint('❌ Error getting MesaYa! tables: $e');
      return [];
    }
  }

  /// Reserva instantánea MesaYa! (sin cola)
  static Future<Map<String, dynamic>?> makeInstantReservation({
    required String userId,
    required String tableId,
    required int partySize,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      debugPrint('⚡ Making MesaYa! instant reservation...');
      
      // Verificar que el usuario puede hacer reservas
      if (!UserService.canUserMakeReservation()) {
        debugPrint('❌ User cannot make reservations due to low reputation');
        return null;
      }

      // Verificar que la mesa sigue disponible
      final availableTables = await getAvailableTablesNow();
      final isTableAvailable = availableTables.any((t) => t['id'] == tableId);
      
      if (!isTableAvailable) {
        debugPrint('❌ Table is no longer available');
        return null;
      }

      // Crear reserva inmediata
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      final reservation = await _client
          .from('sodita_reservas')
          .insert({
            'mesa_id': tableId,
            'usuario_id': userId,
            'fecha': now.toIso8601String().split('T')[0],
            'hora': timeString,
            'personas': partySize,
            'nombre': customerName,
            'telefono': customerPhone,
            'estado': 'confirmada',
            'tipo_reserva': 'mesaya', // Marca como MesaYa!
            'prioridad': UserService.getUserPriorityLevel(),
          })
          .select()
          .single();

      debugPrint('⚡ MesaYa! reservation created: ${reservation['codigo_confirmacion']}');
      return reservation;
    } catch (e) {
      debugPrint('❌ Error making instant reservation: $e');
      return null;
    }
  }

  // COLA VIRTUAL - CUANDO NO HAY MESAS DISPONIBLES

  /// Unirse a la cola virtual
  static Future<Map<String, dynamic>?> joinQueue({
    required String userId,
    required int partySize,
    required String customerName,
    required String customerPhone,
    String? tablePreference, // 'living', 'barra', 'bajas'
  }) async {
    try {
      debugPrint('🔄 User joining virtual queue...');
      
      // Verificar que el usuario puede hacer reservas
      if (!UserService.canUserMakeReservation()) {
        debugPrint('❌ User cannot join queue due to low reputation');
        return null;
      }

      // Verificar que no está ya en cola
      final existingInQueue = await _client
          .from('sodita_cola_virtual')
          .select('id')
          .eq('usuario_id', userId)
          .eq('estado', 'esperando')
          .maybeSingle();

      if (existingInQueue != null) {
        debugPrint('⚠️ User already in queue');
        return null;
      }

      // Calcular posición en cola basada en prioridad
      final queuePosition = await _calculateQueuePosition(userId, partySize, tablePreference);
      
      // Crear entrada en cola
      final queueEntry = await _client
          .from('sodita_cola_virtual')
          .insert({
            'usuario_id': userId,
            'nombre': customerName,
            'telefono': customerPhone,
            'personas': partySize,
            'preferencia_mesa': tablePreference,
            'posicion': queuePosition,
            'prioridad': UserService.getUserPriorityLevel(),
            'tiempo_estimado': await _calculateWaitTime(queuePosition),
            'estado': 'esperando',
            'fecha_ingreso': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('🔄 User added to queue at position: $queuePosition');
      
      // Actualizar cache de cola
      await _refreshQueueCache();
      
      return queueEntry;
    } catch (e) {
      debugPrint('❌ Error joining queue: $e');
      return null;
    }
  }

  /// Calcular posición en cola basada en prioridad Woki-style
  static Future<int> _calculateQueuePosition(String userId, int partySize, String? tablePreference) async {
    try {
      final userPriority = UserService.getUserPriorityLevel();
      
      // Obtener cola actual ordenada por prioridad
      final currentQueue = await _client
          .from('sodita_cola_virtual')
          .select('*, sodita_usuarios!inner(reputacion)')
          .eq('estado', 'esperando')
          .order('fecha_ingreso');

      int position = 1;
      
      // Lógica de prioridad estilo Woki
      for (final entry in currentQueue) {
        final entryPriority = entry['prioridad'] ?? 'regular';
        final entryReputation = entry['sodita_usuarios']['reputacion'] ?? 50;
        final userReputation = UserService.getUserReputation();
        
        // VIP y Premium van primero
        if (_shouldGoFirst(userPriority, userReputation, entryPriority, entryReputation)) {
          break;
        }
        position++;
      }
      
      return position;
    } catch (e) {
      debugPrint('❌ Error calculating queue position: $e');
      return 1;
    }
  }

  /// Lógica de prioridad estilo Woki
  static bool _shouldGoFirst(String userPriority, int userReputation, String otherPriority, int otherReputation) {
    // Orden de prioridad: vip > premium > regular > bajo > nuevo
    const priorityOrder = ['vip', 'premium', 'regular', 'bajo', 'nuevo'];
    
    final userIndex = priorityOrder.indexOf(userPriority);
    final otherIndex = priorityOrder.indexOf(otherPriority);
    
    if (userIndex < otherIndex) return true;
    if (userIndex > otherIndex) return false;
    
    // Misma prioridad - decidir por reputación
    return userReputation > otherReputation;
  }

  /// Calcular tiempo estimado de espera
  static Future<int> _calculateWaitTime(int position) async {
    // Tiempo promedio por mesa: 60 minutos
    // Rotación estimada: cada 20 minutos se libera una mesa
    const avgTurnoverMinutes = 20;
    
    return (position - 1) * avgTurnoverMinutes;
  }

  /// Obtener posición actual en cola
  static Future<Map<String, dynamic>?> getUserQueueStatus(String userId) async {
    try {
      final queueEntry = await _client
          .from('sodita_cola_virtual')
          .select('*')
          .eq('usuario_id', userId)
          .eq('estado', 'esperando')
          .maybeSingle();

      if (queueEntry == null) return null;

      // Calcular posición actualizada
      final currentPosition = await _getCurrentQueuePosition(queueEntry['id']);
      final estimatedWait = await _calculateWaitTime(currentPosition);

      return {
        ...queueEntry,
        'posicion_actual': currentPosition,
        'tiempo_estimado_actual': estimatedWait,
      };
    } catch (e) {
      debugPrint('❌ Error getting queue status: $e');
      return null;
    }
  }

  /// Obtener posición actual en cola
  static Future<int> _getCurrentQueuePosition(String queueEntryId) async {
    try {
      final entry = await _client
          .from('sodita_cola_virtual')
          .select('fecha_ingreso, prioridad')
          .eq('id', queueEntryId)
          .single();

      final entriesAhead = await _client
          .from('sodita_cola_virtual')
          .select('count')
          .eq('estado', 'esperando')
          .lt('fecha_ingreso', entry['fecha_ingreso']);

      return (entriesAhead[0]['count'] ?? 0) + 1;
    } catch (e) {
      return 1;
    }
  }

  // NOTIFICACIONES Y GESTIÓN DE COLA

  /// Notificar cuando una mesa se libera
  static Future<void> processTableRelease(String tableId) async {
    try {
      debugPrint('🔓 Table released, processing queue...');
      
      // Obtener información de la mesa liberada
      final table = await _client
          .from('sodita_mesas')
          .select('*')
          .eq('id', tableId)
          .single();

      // Buscar al siguiente en cola que pueda usar esta mesa
      final nextInQueue = await _findNextInQueueForTable(table);
      
      if (nextInQueue != null) {
        // Notificar al usuario
        await _notifyUserTableReady(nextInQueue, table);
        
        // Crear reserva automática con tiempo límite (5 minutos para confirmar)
        await _createQueueReservation(nextInQueue, table);
        
        debugPrint('📨 Queue user notified: ${nextInQueue['nombre']}');
      }
    } catch (e) {
      debugPrint('❌ Error processing table release: $e');
    }
  }

  /// Encontrar siguiente usuario en cola compatible con la mesa
  static Future<Map<String, dynamic>?> _findNextInQueueForTable(Map<String, dynamic> table) async {
    try {
      final queue = await _client
          .from('sodita_cola_virtual')
          .select('*')
          .eq('estado', 'esperando')
          .lte('personas', table['capacidad']) // Que quepa en la mesa
          .order('fecha_ingreso');

      // Priorizar por nivel de usuario
      for (final entry in queue) {
        if (entry['preferencia_mesa'] == null || 
            entry['preferencia_mesa'] == table['ubicacion']) {
          return entry;
        }
      }
      
      // Si no hay preferencias específicas, tomar el primero
      return queue.isNotEmpty ? queue.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Crear reserva desde cola con tiempo límite
  static Future<void> _createQueueReservation(Map<String, dynamic> queueEntry, Map<String, dynamic> table) async {
    try {
      final now = DateTime.now();
      final expirationTime = now.add(const Duration(minutes: 5)); // 5 min para confirmar
      
      await _client
          .from('sodita_reservas')
          .insert({
            'mesa_id': table['id'],
            'usuario_id': queueEntry['usuario_id'],
            'fecha': now.toIso8601String().split('T')[0],
            'hora': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            'personas': queueEntry['personas'],
            'nombre': queueEntry['nombre'],
            'telefono': queueEntry['telefono'],
            'estado': 'pendiente_confirmacion',
            'tipo_reserva': 'cola_virtual',
            'expira_confirmacion': expirationTime.toIso8601String(),
          });

      // Marcar entrada de cola como notificada
      await _client
          .from('sodita_cola_virtual')
          .update({
            'estado': 'notificado',
            'fecha_notificacion': now.toIso8601String(),
          })
          .eq('id', queueEntry['id']);
          
    } catch (e) {
      debugPrint('❌ Error creating queue reservation: $e');
    }
  }

  /// Simular notificación push (en implementación real sería push notification)
  static Future<void> _notifyUserTableReady(Map<String, dynamic> queueEntry, Map<String, dynamic> table) async {
    // En una implementación real, aquí se enviaría push notification
    debugPrint('📨 NOTIFICATION: Mesa ${table['numero']} disponible para ${queueEntry['nombre']}');
    debugPrint('⏰ Tiene 5 minutos para confirmar');
  }

  /// Confirmar reserva desde cola
  static Future<bool> confirmQueueReservation(String userId) async {
    try {
      final pendingReservation = await _client
          .from('sodita_reservas')
          .select('*')
          .eq('usuario_id', userId)
          .eq('estado', 'pendiente_confirmacion')
          .maybeSingle();

      if (pendingReservation == null) return false;

      // Verificar que no expiró
      final expirationTime = DateTime.parse(pendingReservation['expira_confirmacion']);
      if (DateTime.now().isAfter(expirationTime)) {
        // Expiró - cancelar y volver a cola
        await _handleExpiredConfirmation(pendingReservation);
        return false;
      }

      // Confirmar reserva
      await _client
          .from('sodita_reservas')
          .update({'estado': 'confirmada'})
          .eq('id', pendingReservation['id']);

      // Remover de cola
      await _client
          .from('sodita_cola_virtual')
          .delete()
          .eq('usuario_id', userId);

      debugPrint('✅ Queue reservation confirmed');
      return true;
    } catch (e) {
      debugPrint('❌ Error confirming queue reservation: $e');
      return false;
    }
  }

  /// Manejar confirmación expirada
  static Future<void> _handleExpiredConfirmation(Map<String, dynamic> reservation) async {
    try {
      // Cancelar reserva
      await _client
          .from('sodita_reservas')
          .update({'estado': 'cancelada'})
          .eq('id', reservation['id']);

      // Volver usuario a cola
      await _client
          .from('sodita_cola_virtual')
          .update({'estado': 'esperando'})
          .eq('usuario_id', reservation['usuario_id']);

      // Procesar liberación de mesa para siguiente en cola
      await processTableRelease(reservation['mesa_id']);
      
    } catch (e) {
      debugPrint('❌ Error handling expired confirmation: $e');
    }
  }

  /// Salir de la cola
  static Future<bool> leaveQueue(String userId) async {
    try {
      await _client
          .from('sodita_cola_virtual')
          .delete()
          .eq('usuario_id', userId)
          .eq('estado', 'esperando');

      debugPrint('👋 User left queue');
      return true;
    } catch (e) {
      debugPrint('❌ Error leaving queue: $e');
      return false;
    }
  }

  /// Actualizar cache de cola
  static Future<void> _refreshQueueCache() async {
    try {
      final queue = await _client
          .from('sodita_cola_virtual')
          .select('*')
          .eq('estado', 'esperando')
          .order('fecha_ingreso');

      _currentQueue = List<Map<String, dynamic>>.from(queue);
      _lastQueueUpdate = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error refreshing queue cache: $e');
    }
  }

  /// Obtener estadísticas de cola
  static Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final queue = await _client
          .from('sodita_cola_virtual')
          .select('*')
          .eq('estado', 'esperando');

      final totalInQueue = queue.length;
      final avgWaitTime = totalInQueue > 0 ? await _calculateWaitTime(totalInQueue ~/ 2) : 0;
      
      final priorityBreakdown = <String, int>{};
      for (final entry in queue) {
        final priority = entry['prioridad'] ?? 'regular';
        priorityBreakdown[priority] = (priorityBreakdown[priority] ?? 0) + 1;
      }

      return {
        'total_en_cola': totalInQueue,
        'tiempo_promedio_espera': avgWaitTime,
        'breakdown_prioridad': priorityBreakdown,
      };
    } catch (e) {
      debugPrint('❌ Error getting queue stats: $e');
      return {};
    }
  }
}