import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/reservation_service.dart';

// VISTA DE PLANO ESTILO WOKI PARA SODITA
class FloorPlanView extends StatefulWidget {
  final List<Map<String, dynamic>> reservations;
  final Function(Map<String, dynamic>) onReservationTap;

  const FloorPlanView({
    super.key,
    required this.reservations,
    required this.onReservationTap,
  });

  @override
  State<FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<FloorPlanView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel lateral izquierdo con reservas (estilo Woki)
        Container(
          width: MediaQuery.of(context).size.width > 600 ? 350 : 300,
          color: Colors.white,
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Reservas del Día',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'System',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF86704),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.reservations.length}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de reservas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.reservations.length,
                  itemBuilder: (context, index) {
                    return _buildSideReservationCard(widget.reservations[index]);
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Línea divisoria
        Container(width: 1, color: Colors.grey[200]),
        
        // Vista principal del plano del restaurant
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: Column(
              children: [
                // Header del plano
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, color: const Color(0xFFF86704)),
                      const SizedBox(width: 8),
                      Text(
                        'Restaurant SODITA - Mesas Superiores',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildLegend(),
                    ],
                  ),
                ),
                
                // Grid de mesas estilo Woki
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildTablesGrid(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Tarjeta lateral de reserva (más compacta estilo Woki)
  Widget _buildSideReservationCard(Map<String, dynamic> reservation) {
    final mesa = reservation['sodita_mesas'];
    final timeLeft = ReservationService.getTimeUntilNoShow(reservation['hora']);
    final hasExpired = timeLeft == null;
    final isInCriticalPeriod = timeLeft != null && timeLeft.inMinutes <= 5;
    
    return GestureDetector(
      onTap: () => widget.onReservationTap(reservation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasExpired 
                ? Colors.red[300]! 
                : isInCriticalPeriod 
                    ? Colors.orange[300]! 
                    : Colors.green[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTableStatusColor(reservation['estado']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mesa['numero'] == 11 ? 'Salón completo' : 'Mesa ${mesa['numero']}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (timeLeft != null && !hasExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isInCriticalPeriod 
                          ? Colors.red[100] 
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isInCriticalPeriod 
                            ? Colors.red[300]! 
                            : Colors.green[300]!,
                      ),
                    ),
                    child: Text(
                      ReservationService.formatTimeRemaining(timeLeft),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isInCriticalPeriod 
                            ? Colors.red[700] 
                            : Colors.green[700],
                      ),
                    ),
                  ),
                if (hasExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      'VENCIDA',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reservation['nombre'],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${reservation['hora']} • ${reservation['personas']} personas',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Leyenda de colores estilo Woki
  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Disponible', const Color(0xFF4CAF50)), // Verde Woki
        const SizedBox(width: 16),
        _buildLegendItem('Reservada', const Color(0xFF2196F3)), // Azul Woki
        const SizedBox(width: 16),
        _buildLegendItem('Ocupada', const Color(0xFFFF9800)), // Naranja Woki
        const SizedBox(width: 16),
        _buildLegendItem('Crítica', const Color(0xFFF44336)), // Rojo Woki
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // Grid de mesas estilo Woki
  Widget _buildTablesGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ReservationService.getMesas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF86704),
            ),
          );
        }
        
        final mesas = snapshot.data!;
        
        return Column(
          children: [
            // Living (1 mesa grande)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.weekend, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVING (12 personas)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: _buildTableWidget(mesas.firstWhere((m) => m['ubicacion'] == 'Living')),
                  ),
                ],
              ),
            ),
            
            // Mesas Barra (4 mesas)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.table_bar, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'MESAS BARRA (16 personas)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: mesas
                          .where((m) => m['ubicacion'] == 'Mesas Barra')
                          .map((mesa) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildTableWidget(mesa),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Mesas Bajas (5 mesas)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.table_restaurant, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'MESAS BAJAS (22 personas)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: mesas.where((m) => m['ubicacion'] == 'Mesas Bajas').length,
                        itemBuilder: (context, index) {
                          final mesasBajas = mesas.where((m) => m['ubicacion'] == 'Mesas Bajas').toList();
                          return _buildTableWidget(mesasBajas[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Total de capacidad
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF86704),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'CAPACIDAD TOTAL: 50 PERSONAS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Widget individual de mesa estilo Woki
  Widget _buildTableWidget(Map<String, dynamic> mesa) {
    // Buscar si la mesa tiene reserva hoy
    final reservation = widget.reservations.firstWhere(
      (r) => r['mesa_id'] == mesa['id'],
      orElse: () => <String, dynamic>{},
    );
    
    final hasReservation = reservation.isNotEmpty;
    final estado = hasReservation ? reservation['estado'] : 'disponible';
    final timeLeft = hasReservation ? ReservationService.getTimeUntilNoShow(reservation['hora']) : null;
    final isExpired = hasReservation && timeLeft == null;
    final isCritical = hasReservation && timeLeft != null && timeLeft.inMinutes <= 5;
    
    Color tableColor;
    String statusText;
    
    if (!hasReservation) {
      tableColor = const Color(0xFF4CAF50); // Verde Woki
      statusText = 'Disponible';
    } else if (isExpired) {
      tableColor = const Color(0xFFF44336); // Rojo Woki
      statusText = 'VENCIDA';
    } else if (isCritical) {
      tableColor = const Color(0xFFF44336); // Rojo Woki
      statusText = ReservationService.formatTimeRemaining(timeLeft);
    } else if (estado == 'en_mesa') {
      tableColor = const Color(0xFFFF9800); // Naranja Woki
      statusText = 'OCUPADA';
    } else {
      tableColor = const Color(0xFF2196F3); // Azul Woki
      statusText = timeLeft != null ? ReservationService.formatTimeRemaining(timeLeft) : 'Reservada';
    }
    
    return GestureDetector(
      onTap: () {
        if (hasReservation) {
          widget.onReservationTap(reservation);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: tableColor.withValues(alpha: 0.1),
          border: Border.all(color: tableColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: tableColor.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tableColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Mesa ${mesa['numero']}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tableColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasReservation) ...[
              const SizedBox(height: 4),
              Text(
                reservation['nombre'],
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getTableStatusColor(String estado) {
    switch (estado) {
      case 'confirmada':
        return const Color(0xFF2196F3); // Azul Woki
      case 'en_mesa':
        return const Color(0xFFFF9800); // Naranja Woki
      case 'no_show':
      case 'cancelada':
        return const Color(0xFFF44336); // Rojo Woki
      default:
        return const Color(0xFF4CAF50); // Verde Woki
    }
  }
}