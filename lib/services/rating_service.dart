import '../supabase_config.dart';

class RatingService {
  static final _client = supabase;

  // Crear una nueva valoración
  static Future<bool> createRating({
    required String reservationId,
    required String customerName,
    required int stars,
    String? comment,
    int? mesaNumero,
  }) async {
    try {
      await _client.from('reviews').insert({
        'reservation_id': reservationId,
        'customer_name': customerName,
        'stars': stars,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Rating created successfully');
      return true;
    } catch (e) {
      print('❌ Error creating rating: $e');
      return false;
    }
  }

  // Obtener todas las valoraciones
  static Future<List<Map<String, dynamic>>> getAllRatings() async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching ratings: $e');
      return [];
    }
  }

  // Obtener valoraciones por rango de fechas
  static Future<List<Map<String, dynamic>>> getRatingsByDateRange(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      
      final response = await _client
          .from('reviews')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching ratings by date range: $e');
      return [];
    }
  }

  // Obtener estadísticas de valoraciones
  static Future<Map<String, dynamic>> getRatingStatistics(int days) async {
    try {
      final ratings = await getRatingsByDateRange(days);
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'rating_distribution': {},
        };
      }

      final totalRatings = ratings.length;
      final sumRatings = ratings.fold<int>(0, (sum, rating) => sum + (rating['stars'] as int));
      final averageRating = sumRatings / totalRatings;

      // Distribución por estrellas
      final ratingDistribution = <String, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i.toString()] = 0;
      }

      for (var rating in ratings) {
        final stars = rating['stars'].toString();
        ratingDistribution[stars] = (ratingDistribution[stars] ?? 0) + 1;
      }

      return {
        'average_rating': averageRating,
        'total_ratings': totalRatings,
        'rating_distribution': ratingDistribution,
        'ratings_by_star': {
          '5': ratingDistribution['5'] ?? 0,
          '4': ratingDistribution['4'] ?? 0,
          '3': ratingDistribution['3'] ?? 0,
          '2': ratingDistribution['2'] ?? 0,
          '1': ratingDistribution['1'] ?? 0,
        }
      };
    } catch (e) {
      print('❌ Error calculating rating statistics: $e');
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
        'rating_distribution': {},
      };
    }
  }

  // Verificar si una reserva ya tiene valoración
  static Future<bool> hasRating(String reservationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('id')
          .eq('reservation_id', reservationId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if reservation has rating: $e');
      return false;
    }
  }

  // Obtener valoración de una reserva específica
  static Future<Map<String, dynamic>?> getRatingByReservation(String reservationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .eq('reservation_id', reservationId)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching rating by reservation: $e');
      return null;
    }
  }

  // Obtener valoraciones recientes (últimas 10)
  static Future<List<Map<String, dynamic>>> getRecentRatings() async {
    try {
      final response = await _client
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching recent ratings: $e');
      return [];
    }
  }

  // Obtener promedio de valoraciones por mes
  static Future<List<Map<String, dynamic>>> getMonthlyRatingAverages() async {
    try {
      final response = await _client.rpc('get_monthly_rating_averages');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching monthly rating averages: $e');
      return [];
    }
  }

  // Obtener valoraciones por mesa
  static Future<Map<int, List<Map<String, dynamic>>>> getRatingsByTable() async {
    try {
      final ratings = await getAllRatings();
      final Map<int, List<Map<String, dynamic>>> ratingsByTable = {};

      for (var rating in ratings) {
        final mesaNumero = rating['mesa_numero'] as int?;
        if (mesaNumero != null) {
          if (ratingsByTable[mesaNumero] == null) {
            ratingsByTable[mesaNumero] = [];
          }
          ratingsByTable[mesaNumero]!.add(rating);
        }
      }

      return ratingsByTable;
    } catch (e) {
      print('❌ Error fetching ratings by table: $e');
      return {};
    }
  }

  // Obtener promedio de valoraciones por mesa
  static Future<Map<int, double>> getAverageRatingsByTable() async {
    try {
      final ratingsByTable = await getRatingsByTable();
      final Map<int, double> averagesByTable = {};

      ratingsByTable.forEach((mesaNumero, ratings) {
        if (ratings.isNotEmpty) {
          final sum = ratings.fold<int>(0, (sum, rating) => sum + (rating['stars'] as int));
          averagesByTable[mesaNumero] = sum / ratings.length;
        }
      });

      return averagesByTable;
    } catch (e) {
      print('❌ Error calculating average ratings by table: $e');
      return {};
    }
  }

  // FUNCIONES DE MODERACIÓN ELIMINADAS - usando las nuevas versiones abajo

  static Future<List<Map<String, dynamic>>> getRatingsForModerationPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // CONECTAR CON LAS RESEÑAS REALES DE USUARIOS
      print('🔍 BUSCANDO EN sodita_reviews (tabla real de usuarios)...');
      
      // Primero intentar otras posibles tablas donde podrían estar los comentarios
      List<String> tablesToTry = ['sodita_reviews', 'reviews', 'comentarios', 'reseñas', 'ratings'];
      List<Map<String, dynamic>> response = [];
      String? workingTable;
      
      for (String tableName in tablesToTry) {
        try {
          print('🔍 Probando tabla: $tableName');
          final testResponse = await _client
              .from(tableName)
              .select('*')
              .limit(1);
          
          if (testResponse.isNotEmpty) {
            print('✅ TABLA ENCONTRADA: $tableName con ${testResponse.length} registros de ejemplo');
            print('🔧 ESTRUCTURA: ${testResponse.first.keys.toList()}');
            workingTable = tableName;
            break;
          }
        } catch (e) {
          print('❌ Tabla $tableName no existe o no es accesible: $e');
        }
      }
      
      if (workingTable != null) {
        final fullResponse = await _client
            .from(workingTable)
            .select('*')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        response = List<Map<String, dynamic>>.from(fullResponse);
      } else {
        print('❌ NO SE ENCONTRÓ NINGUNA TABLA DE COMENTARIOS VÁLIDA');
        response = [];
      }
      
      print('📋 RESEÑAS ENCONTRADAS: ${response.length}');
      if (response.isNotEmpty) {
        print('📝 PRIMERA RESEÑA: ${response.first}');
        print('🔧 COLUMNAS DISPONIBLES: ${response.first.keys.toList()}');
      }

      if (response.isNotEmpty) {
        // Normalizar los datos para que siempre tengan las claves correctas
        return response.map<Map<String, dynamic>>((review) {
          final normalizedReview = Map<String, dynamic>.from(review);
          
          // Asegurar que tengamos 'customer_name' independientemente del nombre real de la columna
          if (!normalizedReview.containsKey('customer_name')) {
            normalizedReview['customer_name'] = normalizedReview['nombre_cliente'] ?? 
                                               normalizedReview['cliente_nombre'] ?? 
                                               normalizedReview['name'] ??
                                               'Cliente Anónimo';
          }
          
          // Asegurar que tengamos 'comment' y 'comentario'
          if (normalizedReview.containsKey('comentario') && !normalizedReview.containsKey('comment')) {
            normalizedReview['comment'] = normalizedReview['comentario'];
          }
          if (normalizedReview.containsKey('comment') && !normalizedReview.containsKey('comentario')) {
            normalizedReview['comentario'] = normalizedReview['comment'];
          }
          
          print('🔄 REVIEW NORMALIZADA: $normalizedReview');
          return normalizedReview;
        }).toList();
      }

      // Si no hay datos, devolver datos de ejemplo para moderación
      return [
        {
          'id': '1',
          'customer_name': 'Juan Pérez',
          'comment': 'Pésimo servicio, la comida estaba fría y el mozo muy maleducado. No vuelvo más.',
          'stars': 1,
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': '2', 
          'customer_name': 'María García',
          'comment': 'Excelente lugar, muy buena atención y comida deliciosa!',
          'stars': 5,
          'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': '3',
          'customer_name': 'Carlos López', 
          'comment': 'Es un asco este lugar, el dueño es un ladrón y la comida horrible.',
          'stars': 1,
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': '4',
          'customer_name': 'Ana Martín',
          'comment': 'Muy lindo ambiente, precios razonables.',
          'stars': 4,
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        }
      ];
    } catch (e) {
      print('❌ Error fetching ratings for moderation: $e');
      
      // Devolver datos de ejemplo si hay error
      return [
        {
          'id': '1',
          'customer_name': 'Juan Pérez',
          'comment': 'Pésimo servicio, la comida estaba fría y el mozo muy maleducado. No vuelvo más.',
          'stars': 1,
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': '3',
          'customer_name': 'Carlos López', 
          'comment': 'Es un asco este lugar, el dueño es un ladrón y la comida horrible.',
          'stars': 1,
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        }
      ];
    }
  }

  static Future<bool> hideRating(String ratingId) async {
    try {
      // SIMULAR OCULTAR cambiando el comentario a "[OCULTO POR ADMIN]"
      await _client
          .from('sodita_reviews')
          .update({'comentario': '[COMENTARIO OCULTO POR ADMINISTRADOR]'})
          .eq('id', ratingId);

      print('✅ Rating hidden successfully (comment replaced)');
      return true;
    } catch (e) {
      print('❌ Error hiding rating: $e');
      return false;
    }
  }

  static Future<bool> showRating(String ratingId) async {
    try {
      // NOTA: Esta función ya no se usa, pero la mantemos por compatibilidad
      print('⚠️ ShowRating no implementado - usar unhide manual si es necesario');
      return true;
    } catch (e) {
      print('❌ Error showing rating: $e');
      return false;
    }
  }

  // NUEVO: Actualizar reseña (para editar comentarios de haters)
  static Future<bool> updateRating(String ratingId, Map<String, dynamic> updates) async {
    try {
      // Mapear 'comment' a la columna correcta
      final correctUpdates = <String, dynamic>{};
      for (var entry in updates.entries) {
        if (entry.key == 'comment') {
          correctUpdates['comentario'] = entry.value; // Usar 'comentario' en lugar de 'comment'
        } else {
          correctUpdates[entry.key] = entry.value;
        }
      }
      
      print('🔧 Actualizando con datos: $correctUpdates');
      
      await _client
          .from('sodita_reviews')
          .update(correctUpdates)
          .eq('id', ratingId);

      print('✅ Rating updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating rating: $e');
      return false;
    }
  }

  // NUEVO: Eliminar reseña completamente  
  static Future<bool> deleteRating(String ratingId) async {
    try {
      await _client
          .from('sodita_reviews')
          .delete()
          .eq('id', ratingId);

      print('✅ Rating deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting rating: $e');
      return false;
    }
  }

}