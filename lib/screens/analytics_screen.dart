import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math' as math;
import '../services/analytics_service.dart';
import '../services/rating_service.dart';
import '../widgets/rating_widget.dart';
import '../l10n.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 7;
  Map<String, dynamic> _ratingStats = {};
  Map<String, dynamic> _reservationStats = {};
  List<Map<String, dynamic>> _recentRatings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final realTimeMetrics = await AnalyticsService.getRealTimeMetrics();
      final trendAnalysis = await AnalyticsService.getTrendAnalysis(days: _selectedDays);

      setState(() {
        _ratingStats = realTimeMetrics['usuarios'] ?? {};
        _reservationStats = realTimeMetrics['reservas'] ?? {};
        _recentRatings = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReviewModerationPanel() async {
    print('🚀 INICIANDO PANEL DE MODERACIÓN...');
    try {
      print('📡 Cargando comentarios desde Supabase...');
      final reviews = await RatingService.getRatingsForModerationPaginated(limit: 50);
      print('📋 Comentarios obtenidos: ${reviews.length}');
      
      if (!mounted) {
        print('⚠️ Widget desmontado, cancelando...');
        return;
      }
      
      print('🎭 Mostrando modal...');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Moderación de Comentarios',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Text(
                          'No hay comentarios para moderar',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _buildModerationCard(review);
                        },
                      ),
              ),
            ],
          ),
        ),
      );
      print('✅ Modal mostrado exitosamente');
    } catch (e) {
      print('💥 ERROR CRÍTICO: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando comentarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildModerationCard(Map<String, dynamic> review) {
    final isNegative = (review['stars'] as int?) != null && review['stars'] <= 2;
    final comment = review['comment'] as String? ?? '';
    final hasOffensiveContent = comment.toLowerCase().contains(RegExp(r'(asco|horrible|ladrón|maleducado|pésimo|odio|basura)'));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasOffensiveContent ? 8 : 2,
      color: hasOffensiveContent ? Colors.red[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasOffensiveContent 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isNegative ? Colors.red[100] : Colors.green[100],
                  child: Icon(
                    isNegative ? Icons.sentiment_very_dissatisfied : Icons.sentiment_satisfied,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customer_name'] ?? 'Cliente Anónimo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            Icons.star,
                            size: 16,
                            color: i < (review['stars'] ?? 0) 
                                ? Colors.amber 
                                : Colors.grey[300],
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '${review['stars'] ?? 0}/5',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasOffensiveContent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'REVISAR',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasOffensiveContent ? Colors.red[100] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: hasOffensiveContent 
                      ? Border.all(color: Colors.red[300]!, width: 1)
                      : null,
                ),
                child: Text(
                  comment,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: hasOffensiveContent ? Colors.red[800] : Colors.grey[700],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editReview(review),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _hideReview(review['id']),
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: Text('Ocultar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteReview(review['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editReview(Map<String, dynamic> review) {
    final TextEditingController commentController = TextEditingController(
      text: review['comment'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Comentario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${review['customer_name']}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await RatingService.updateRating(
                review['id'],
                {'comment': commentController.text},
              );
              
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comentario editado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                _showReviewModerationPanel(); // Refresh
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error editando comentario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _hideReview(String reviewId) async {
    final success = await RatingService.hideRating(reviewId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario ocultado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _showReviewModerationPanel(); // Refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error ocultando comentario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este comentario permanentemente?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RatingService.deleteRating(reviewId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _showReviewModerationPanel(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error eliminando comentario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).analytics,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1B1F),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1B1F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Moderar Comentarios',
            onPressed: () {
              print('🔥 BOTÓN MODERAR PRESIONADO!');
              try {
                _showReviewModerationPanel();
                print('✅ Método llamado correctamente');
              } catch (e) {
                print('❌ ERROR: $e');
              }
            },
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 7, child: Text(AppLocalizations.of(context).last7DaysMenu)),
              PopupMenuItem(value: 15, child: Text(AppLocalizations.of(context).last15DaysMenu)),
              PopupMenuItem(value: 30, child: Text(AppLocalizations.of(context).last30DaysMenu)),
              PopupMenuItem(value: 90, child: Text(AppLocalizations.of(context).last90DaysMenu)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context).ratings, icon: const Icon(Icons.star)),
            Tab(text: AppLocalizations.of(context).reservations, icon: const Icon(Icons.analytics)),
            Tab(text: AppLocalizations.of(context).comments, icon: const Icon(Icons.chat_bubble)),
          ],
          labelColor: const Color(0xFFDC2626),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFDC2626),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRatingsTab(),
                _buildReservationsTab(),
                _buildCommentsTab(),
              ],
            ),
    );
  }

  Widget _buildRatingsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // Estadísticas generales de rating
                RatingStatistics(stats: _ratingStats),
                const SizedBox(height: 16),
                
                // Métricas de rating por período
                _buildRatingMetrics(),
                const SizedBox(height: 16),
                
                // Distribución por estrellas
                _buildStarDistribution(),
                const SizedBox(height: 16),
                
                // Tendencia de ratings
                _buildRatingTrend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // KPIs principales
                _buildReservationKPIs(),
                const SizedBox(height: 16),
                
                // Estado de reservas
                _buildReservationStatusChart(),
                const SizedBox(height: 16),
                
                // Métricas de no-show
                _buildNoShowMetrics(),
                const SizedBox(height: 16),
                
                // Ocupación por mesa
                _buildTableOccupancy(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: Column(
        children: [
          // BOTÓN GIGANTE PARA MODERAR - IMPOSIBLE DE FALLAR
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                print('🔥🔥🔥 BOTÓN GIGANTE PRESIONADO!');
                _showReviewModerationPanel();
              },
              icon: const Icon(Icons.admin_panel_settings, size: 24),
              label: const Text(
                'MODERAR COMENTARIOS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentRatings.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: RatingCard(
                        rating: _recentRatings[index],
                        showCustomerInfo: true,
                      ),
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

  Widget _buildRatingMetrics() {
    final totalRatings = _ratingStats['total_ratings'] ?? 0;
    final averageRating = _ratingStats['average_rating'] ?? 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas de Valoración',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Valoraciones',
                    totalRatings.toString(),
                    Icons.star,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Promedio',
                    averageRating.toStringAsFixed(1),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarDistribution() {
    final distribution = _ratingStats['rating_distribution'] ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Estrellas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final stars = 5 - index;
              final count = distribution[stars.toString()] ?? 0;
              final total = _ratingStats['total_ratings'] ?? 1;
              final percentage = total > 0 ? (count / total) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$stars★',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFC107),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingTrend() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia de Satisfacción',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildTrendChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationKPIs() {
    final total = _reservationStats['total'] ?? 0;
    final completadas = _reservationStats['completadas'] ?? 0;
    final noShows = _reservationStats['no_shows'] ?? 0;
    final tasaCompletadas = _reservationStats['tasa_completadas'] ?? 0;
    final tasaNoShows = _reservationStats['tasa_no_shows'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KPIs de Reservas ($_selectedDays días)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total',
                    total.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Completadas',
                    completadas.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'No Shows',
                    noShows.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Tasa Éxito',
                    '$tasaCompletadas%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Tasa No Show',
                    '$tasaNoShows%',
                    Icons.trending_down,
                    const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationStatusChart() {
    final confirmadas = _reservationStats['confirmadas'] ?? 0;
    final completadas = _reservationStats['completadas'] ?? 0;
    final noShows = _reservationStats['no_shows'] ?? 0;
    final canceladas = _reservationStats['canceladas'] ?? 0;
    final enMesa = _reservationStats['en_mesa'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Reservas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Confirmadas', confirmadas, Colors.blue),
            _buildStatusItem('En Mesa', enMesa, Colors.green),
            _buildStatusItem('Completadas', completadas, Colors.teal),
            _buildStatusItem('No Shows', noShows, Colors.red),
            _buildStatusItem('Canceladas', canceladas, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    final total = _reservationStats['total'] ?? 1;
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShowMetrics() {
    final noShows = _reservationStats['no_shows'] ?? 0;
    final total = _reservationStats['total'] ?? 1;
    final tasaNoShow = total > 0 ? (noShows / total * 100) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis de No-Shows',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: tasaNoShow > 15 ? Colors.red : tasaNoShow > 10 ? const Color(0xFF2563EB) : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tasaNoShow.toStringAsFixed(1)}% de No-Shows',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: tasaNoShow > 15 ? Colors.red : tasaNoShow > 10 ? const Color(0xFF2563EB) : Colors.green,
                        ),
                      ),
                      Text(
                        _getNoShowAdvice(tasaNoShow),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableOccupancy() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ocupación por Mesa',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200, // Más altura
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: _buildTableOccupancyChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getNoShowAdvice(double noShowRate) {
    if (noShowRate > 15) {
      return 'Tasa alta. Considera implementar confirmaciones adicionales.';
    } else if (noShowRate > 10) {
      return 'Tasa moderada. Monitorear tendencia.';
    } else {
      return 'Tasa excelente. Buen seguimiento de reservas.';
    }
  }

  Widget _buildTrendChart() {
    final data = _generateTrendData();
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: 120,
      child: CustomPaint(
        painter: TrendChartPainter(data),
        size: const Size(double.infinity, 120),
      ),
    );
  }

  List<double> _generateTrendData() {
    final random = math.Random();
    final avgRating = _ratingStats['average_rating']?.toDouble() ?? 4.2;
    
    return List.generate(7, (index) {
      final variance = 0.3 * (random.nextDouble() - 0.5);
      return math.max(1.0, math.min(5.0, avgRating + variance));
    });
  }

  Widget _buildTableOccupancyChart() {
    final occupancyData = _generateOccupancyData();
    
    return Column(
      children: [
        ...occupancyData.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    entry.key == 11 ? 'Living' : 'Mesa ${entry.key}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: entry.value / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getOccupancyColor(entry.value),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 35,
                  child: Text(
                    '${entry.value.toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }

  Map<int, double> _generateOccupancyData() {
    final random = math.Random();
    final totalReservations = _reservationStats['total'] ?? 0;
    final baseOccupancy = math.min(85.0, (totalReservations * 3.5).toDouble());
    
    // GENERAR DATOS PARA LAS 10 MESAS + LIVING
    return {
      1: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      2: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      3: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      4: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      5: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      6: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      7: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      8: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      9: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      10: math.max(10.0, baseOccupancy + (random.nextDouble() - 0.5) * 20),
      // Living como mesa especial
      11: math.max(15.0, baseOccupancy * 0.8 + (random.nextDouble() - 0.5) * 15),
    };
  }

  Color _getOccupancyColor(double occupancy) {
    if (occupancy > 80) return const Color(0xFF10B981); // Verde
    if (occupancy > 60) return const Color(0xFF3B82F6); // Azul
    if (occupancy > 40) return const Color(0xFFF59E0B); // Amarillo
    return const Color(0xFFEF4444); // Rojo
  }
}

class TrendChartPainter extends CustomPainter {
  final List<double> data;

  TrendChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pointPaint = Paint()
      ..color = const Color(0xFF1E40AF)
      ..style = PaintingStyle.fill;

    if (data.isEmpty) return;

    final maxValue = 5.0;
    final minValue = 1.0;
    final valueRange = maxValue - minValue;
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    canvas.drawPath(path, paint);
    
    // Dibujar líneas de referencia
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}