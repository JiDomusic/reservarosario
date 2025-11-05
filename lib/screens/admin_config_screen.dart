import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final _cbuController = TextEditingController();
  final _nameController = TextEditingController();
  final _cuitController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _feeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final config = SubscriptionService.getSubscriptionInfo();
    _cbuController.text = config['cbu'];
    _nameController.text = config['holder_name'];
    _cuitController.text = config['cuit'];
    _whatsappController.text = config['whatsapp'];
    _feeController.text = config['monthly_fee'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          '🔒 Configuración del Sistema',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFFDC2626)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFDC2626)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ CONFIDENCIAL: Aquí configuras los datos bancarios donde recibirás las transferencias de los restaurantes.',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            _buildConfigCard(
              title: '🏦 Datos Bancarios',
              children: [
                _buildTextField(
                  controller: _cbuController,
                  label: 'CBU',
                  hint: '0000007900000012345678',
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Titular de la Cuenta',
                  hint: 'Tu nombre completo',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cuitController,
                  label: 'CUIT',
                  hint: '20-12345678-9',
                  icon: Icons.business,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildConfigCard(
              title: '📱 Contacto',
              children: [
                _buildTextField(
                  controller: _whatsappController,
                  label: 'WhatsApp',
                  hint: '+54 341 123-4567',
                  icon: Icons.message,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildConfigCard(
              title: '💰 Tarifa Mensual',
              children: [
                _buildTextField(
                  controller: _feeController,
                  label: 'Monto en ARS',
                  hint: '50000.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  'Guardar Configuración',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Vista Previa para Restaurantes:',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CBU: ${_cbuController.text.isEmpty ? "No configurado" : _cbuController.text}',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Text(
                    'Titular: ${_nameController.text.isEmpty ? "No configurado" : _nameController.text}',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Text(
                    'CUIT: ${_cuitController.text.isEmpty ? "No configurado" : _cuitController.text}',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Text(
                    'Monto: \$${_feeController.text.isEmpty ? "0" : _feeController.text} ARS',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  void _saveConfig() {
    // Aquí guardarías la configuración en un archivo local o base de datos
    // Por ahora, solo mostrar confirmación
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          '✅ Configuración Guardada',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Los datos bancarios han sido actualizados. Los restaurantes verán la nueva información para realizar transferencias.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: GoogleFonts.poppins(color: const Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
    
    // TODO: Implementar guardado real de la configuración
    print('💾 Configuración guardada:');
    print('CBU: ${_cbuController.text}');
    print('Titular: ${_nameController.text}');
    print('CUIT: ${_cuitController.text}');
  }

  @override
  void dispose() {
    _cbuController.dispose();
    _nameController.dispose();
    _cuitController.dispose();
    _whatsappController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}