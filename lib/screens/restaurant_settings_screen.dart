import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/restaurant.dart';
import '../services/restaurant_auth_service.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers para edición
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _tablesController;
  
  bool _isLoading = false;
  bool _hasChanges = false;
  
  Restaurant? get currentRestaurant => context.read<RestaurantAuthService>().currentRestaurant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    if (currentRestaurant != null) {
      _nameController = TextEditingController(text: currentRestaurant!.name);
      _descriptionController = TextEditingController(text: currentRestaurant!.description);
      _addressController = TextEditingController(text: currentRestaurant!.address);
      _phoneController = TextEditingController(text: currentRestaurant!.phone);
      _whatsappController = TextEditingController(text: currentRestaurant!.whatsapp);
      _tablesController = TextEditingController(text: currentRestaurant!.totalTables.toString());
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _addressController = TextEditingController();
      _phoneController = TextEditingController();
      _whatsappController = TextEditingController();
      _tablesController = TextEditingController();
    }

    // Listener para detectar cambios
    for (var controller in [_nameController, _descriptionController, _addressController, _phoneController, _whatsappController, _tablesController]) {
      controller.addListener(() {
        if (!_hasChanges) {
          setState(() {
            _hasChanges = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _tablesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentRestaurant == null) {
      return _buildNotLoggedIn();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildLogoGalleryTab(),
                _buildScheduleTab(),
                _buildAdvancedTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _hasChanges ? _buildSaveBar() : null,
    );
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 100, color: const Color(0xFF64748B)),
            const SizedBox(height: 24),
            Text(
              'Acceso restringido',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Necesitas iniciar sesión como administrador',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF86704),
                foregroundColor: Colors.white,
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            currentRestaurant!.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _resetChanges,
          icon: const Icon(Icons.refresh),
          tooltip: 'Descartar cambios',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: currentRestaurant!.primaryColorValue,
        labelColor: currentRestaurant!.primaryColorValue,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(icon: Icon(Icons.info), text: 'Info Básica'),
          Tab(icon: Icon(Icons.image), text: 'Logo y Fotos'),
          Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
          Tab(icon: Icon(Icons.tune), text: 'Avanzado'),
        ],
      ),
    );
  }

  // TAB 1: INFORMACIÓN BÁSICA
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Información del Restaurante', Icons.restaurant),
            
            const SizedBox(height: 20),
            
            // Nombre del restaurante
            _buildTextField(
              controller: _nameController,
              label: 'Nombre del Restaurante',
              hint: 'Ej: LA PARRILLA DEL PUERTO',
              icon: Icons.restaurant,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Descripción
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Describe tu restaurante, especialidades, ambiente...',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Dirección
            _buildTextField(
              controller: _addressController,
              label: 'Dirección Completa',
              hint: 'Av. Pellegrini 1234, Rosario, Santa Fe',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La dirección es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                // Teléfono
                Expanded(
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Teléfono Principal',
                    hint: '+54 341 456-7890',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El teléfono es requerido';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // WhatsApp
                Expanded(
                  child: _buildTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp (opcional)',
                    hint: '+54 341 456-7890',
                    icon: Icons.message,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Cantidad de mesas
            _buildTextField(
              controller: _tablesController,
              label: 'Cantidad de Mesas',
              hint: '15',
              icon: Icons.table_restaurant,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La cantidad de mesas es requerida';
                }
                final tables = int.tryParse(value);
                if (tables == null || tables < 1 || tables > 200) {
                  return 'Ingresa entre 1 y 200 mesas';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  // TAB 2: LOGO Y GALERÍA
  Widget _buildLogoGalleryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Logo del Restaurante', Icons.image),
          
          const SizedBox(height: 20),
          
          // Logo actual y botón para cambiar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Logo preview
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: currentRestaurant!.primaryColorValue, width: 2),
                  ),
                  child: currentRestaurant!.logoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            currentRestaurant!.logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(),
                          ),
                        )
                      : _buildLogoPlaceholder(),
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentRestaurant!.primaryColorValue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Subir Logo'),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Recomendado: imagen cuadrada, mínimo 300x300px',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader('Galería de Fotos', Icons.photo_library),
          
          const SizedBox(height: 20),
          
          // Galería de fotos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 7, // 6 fotos + 1 botón de agregar
                  itemBuilder: (context, index) {
                    if (index == 6) {
                      return _buildAddPhotoButton();
                    }
                    return _buildPhotoSlot(index);
                  },
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Sube fotos de tu restaurante, platos, ambiente, etc.\nMáximo 10 fotos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: HORARIOS
  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Horarios de Atención', Icons.schedule),
          
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildDaySchedule('Lunes', true, '08:00', '23:00'),
                const Divider(height: 1),
                _buildDaySchedule('Martes', true, '08:00', '23:00'),
                const Divider(height: 1),
                _buildDaySchedule('Miércoles', true, '08:00', '23:00'),
                const Divider(height: 1),
                _buildDaySchedule('Jueves', true, '08:00', '23:00'),
                const Divider(height: 1),
                _buildDaySchedule('Viernes', true, '08:00', '00:00'),
                const Divider(height: 1),
                _buildDaySchedule('Sábado', true, '10:00', '00:00'),
                const Divider(height: 1),
                _buildDaySchedule('Domingo', true, '10:00', '23:00'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: const Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los horarios se muestran a los clientes para saber cuándo pueden hacer reservas.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: CONFIGURACIÓN AVANZADA
  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Colores del Restaurante', Icons.color_lens),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Color primario
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentRestaurant!.primaryColorValue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color Primario',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Usado en botones principales y highlights',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Color picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selector de color en desarrollo')),
                        );
                      },
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Color secundario
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentRestaurant!.secondaryColorValue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color Secundario',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Usado en estados positivos y confirmaciones',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Color picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selector de color en desarrollo')),
                        );
                      },
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader('Configuraciones del Sistema', Icons.tune),
          
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSettingSwitch(
                  'Reservas habilitadas',
                  'Permitir que los clientes hagan reservas programadas',
                  true,
                  (value) {},
                ),
                const Divider(height: 1),
                _buildSettingSwitch(
                  'MesaYa! activo',
                  'Permitir reservas instantáneas de mesas disponibles',
                  true,
                  (value) {},
                ),
                const Divider(height: 1),
                _buildSettingSwitch(
                  'Cola virtual',
                  'Sistema de cola virtual cuando no hay mesas',
                  true,
                  (value) {},
                ),
                const Divider(height: 1),
                _buildSettingSwitch(
                  'Reseñas públicas',
                  'Mostrar reseñas de clientes en el perfil público',
                  true,
                  (value) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: currentRestaurant!.primaryColorValue, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: currentRestaurant!.primaryColorValue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            currentRestaurant!.primaryColorValue.withValues(alpha: 0.1),
            currentRestaurant!.secondaryColorValue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentRestaurant!.primaryColorValue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: currentRestaurant!.primaryColorValue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vista Previa',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: currentRestaurant!.primaryColorValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Nombre del Restaurante',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Descripción del restaurante...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          if (_addressController.text.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _addressController.text,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Text(
        currentRestaurant!.logoText,
        style: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: currentRestaurant!.primaryColorValue,
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickGalleryPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: const Color(0xFF64748B),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    // Por ahora placeholder, en el futuro mostrará fotos reales
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: const Color(0xFF64748B),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day, bool isOpen, String openTime, String closeTime) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          
          Switch(
            value: isOpen,
            onChanged: (value) {
              setState(() {
                _hasChanges = true;
              });
            },
            activeColor: currentRestaurant!.primaryColorValue,
          ),
          
          const SizedBox(width: 16),
          
          if (isOpen) ...[
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(openTime),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          openTime,
                          style: GoogleFonts.inter(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  Text('a', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(closeTime),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          closeTime,
                          style: GoogleFonts.inter(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                'Cerrado',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: currentRestaurant!.primaryColorValue,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Descartar'),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentRestaurant!.primaryColorValue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODOS DE FUNCIONALIDAD

  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // TODO: Subir imagen al servidor
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo seleccionado - Funcionalidad de upload en desarrollo'),
            backgroundColor: currentRestaurant!.primaryColorValue,
          ),
        );
        
        setState(() {
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _pickGalleryPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (image != null) {
        // TODO: Subir imagen a la galería
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto agregada a la galería - Upload en desarrollo'),
            backgroundColor: currentRestaurant!.primaryColorValue,
          ),
        );
        
        setState(() {
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar foto: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _selectTime(String currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: currentRestaurant!.primaryColorValue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<RestaurantAuthService>();
      final success = await authService.updateRestaurant(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        totalTables: int.parse(_tablesController.text),
      );

      if (success && mounted) {
        setState(() {
          _hasChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Configuración guardada exitosamente!'),
            backgroundColor: currentRestaurant!.secondaryColorValue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetChanges() {
    _initializeControllers();
    setState(() {
      _hasChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios descartados'),
        backgroundColor: Color(0xFF64748B),
      ),
    );
  }
}