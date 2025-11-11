import 'dart:async';
import '../supabase_config.dart';

class RealTimeRatingsService {
  static StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  static final _controller = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // Stream para escuchar cambios en tiempo real
  static Stream<List<Map<String, dynamic>>> get ratingsStream => _controller.stream;
  
  // Iniciar escucha en tiempo real
  static void startListening() {
    print('🔴 INICIANDO REALTIME RATINGS...');
    
    _subscription = supabase
        .from('sodita_reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            print('📡 ACTUALIZACIÓN REALTIME: ${data.length} reviews');
            _controller.add(data);
          },
          onError: (error) {
            print('❌ Error en realtime: $error');
          },
        );
  }
  
  // Parar escucha
  static void stopListening() {
    print('🔴 DETENIENDO REALTIME RATINGS...');
    _subscription?.cancel();
    _subscription = null;
  }
  
  // Actualización optimista para UX instantáneo
  static Future<bool> updateReviewOptimistic(String reviewId, String newComment) async {
    try {
      // 1. Mostrar cambio inmediatamente en UI (optimistic update)
      print('⚡ ACTUALIZACIÓN OPTIMISTA: $reviewId');
      
      // 2. Sincronizar con servidor - usar la columna correcta
      await supabase
          .from('sodita_reviews')
          .update({'comentario': newComment})  // Ya está usando 'comentario' que es correcto
          .eq('id', reviewId);
      
      print('✅ SYNC EXITOSO: Review actualizada');
      return true;
      
    } catch (e) {
      print('❌ SYNC FALLÓ, revirtiendo UI: $e');
      // En caso de error, el realtime automáticamente revertirá el estado
      return false;
    }
  }
  
  // Eliminación optimista
  static Future<bool> deleteReviewOptimistic(String reviewId) async {
    try {
      await supabase
          .from('sodita_reviews')
          .delete()
          .eq('id', reviewId);
      
      print('✅ REVIEW ELIMINADA: $reviewId');
      return true;
      
    } catch (e) {
      print('❌ ERROR ELIMINANDO: $e');
      return false;
    }
  }
  
  // Ocultar review optimista
  static Future<bool> hideReviewOptimistic(String reviewId) async {
    try {
      await supabase
          .from('sodita_reviews')
          .update({'is_hidden': true})
          .eq('id', reviewId);
      
      print('✅ REVIEW OCULTADA: $reviewId');
      return true;
      
    } catch (e) {
      print('❌ ERROR OCULTANDO: $e');
      return false;
    }
  }
  
  // Cleanup al cerrar la app
  static void dispose() {
    stopListening();
    _controller.close();
  }
}