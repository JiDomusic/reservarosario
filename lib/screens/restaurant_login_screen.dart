import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_auth_service.dart';
import 'restaurants/universal_restaurant_admin_screen.dart';

class RestaurantLoginScreen extends StatefulWidget {
  const RestaurantLoginScreen({super.key});

  @override
  State<RestaurantLoginScreen> createState() => _RestaurantLoginScreenState();
}

class _RestaurantLoginScreenState extends State<RestaurantLoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _logoAnimationController;
  late Animation<double> _logoAnimation;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _registerNameController = TextEditingController();
  final _registerDescriptionController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerAddressController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerWhatsappController = TextEditingController();
  final _registerTablesController = TextEditingController(text: '15');

  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _logoAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logoAnimationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerDescriptionController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerAddressController.dispose();
    _registerPhoneController.dispose();
    _registerWhatsappController.dispose();
    _registerTablesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildRegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo animado
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF86704),
                        const Color(0xFFFF8A50),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF86704).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    // Icons.admin_panel_settings,
                    Icons.restaurant,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Panel de Restaurantes',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            // 'Accede a tu panel de administración',
            'Accede a tu panel de restaurante',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFF86704),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Iniciar Sesión'),
          Tab(text: 'Registrarse'),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            Text(
              'Bienvenido de vuelta',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Ingresa tus credenciales para acceder',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Email field
            _buildTextField(
              controller: _loginEmailController,
              label: 'Email del restaurante',
              hint: 'admin@turestaurante.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El email es requerido';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Password field
            _buildTextField(
              controller: _loginPasswordController,
              label: 'Contraseña',
              hint: 'Tu contraseña segura',
              icon: Icons.lock,
              obscureText: _obscureLoginPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF64748B),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF86704),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Iniciar Sesión',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo credentials info
            _buildDemoCredentials(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            Text(
              'Nuevo Restaurante',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Crea tu cuenta para gestionar reservas',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Restaurant name
            _buildTextField(
              controller: _registerNameController,
              label: 'Nombre del restaurante',
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
            
            // Description
            _buildTextField(
              controller: _registerDescriptionController,
              label: 'Descripción',
              hint: 'Describe tu restaurante en pocas palabras',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Email
            _buildTextField(
              controller: _registerEmailController,
              label: 'Email de administración',
              hint: 'admin@turestaurante.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El email es requerido';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Password
            _buildTextField(
              controller: _registerPasswordController,
              label: 'Contraseña',
              hint: 'Mínimo 6 caracteres',
              icon: Icons.lock,
              obscureText: _obscureRegisterPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureRegisterPassword = !_obscureRegisterPassword;
                  });
                },
                icon: Icon(
                  _obscureRegisterPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF64748B),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Address
            _buildTextField(
              controller: _registerAddressController,
              label: 'Dirección',
              hint: 'Av. Pellegrini 1234, Rosario',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La dirección es requerida';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Phone
            _buildTextField(
              controller: _registerPhoneController,
              label: 'Teléfono',
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
            
            const SizedBox(height: 20),
            
            // WhatsApp (optional)
            _buildTextField(
              controller: _registerWhatsappController,
              label: 'WhatsApp (opcional)',
              hint: '+54 341 456-7890',
              icon: Icons.message,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 20),
            
            // Number of tables
            _buildTextField(
              controller: _registerTablesController,
              label: 'Cantidad de mesas',
              hint: '15',
              icon: Icons.table_restaurant,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La cantidad de mesas es requerida';
                }
                final tables = int.tryParse(value);
                if (tables == null || tables < 1 || tables > 100) {
                  return 'Ingresa entre 1 y 100 mesas';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Crear Cuenta',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
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
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
            ),
            suffixIcon: suffixIcon,
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
              borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
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

  Widget _buildDemoCredentials() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Credenciales Demo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Prueba con cualquier email de los restaurantes:\nadmin@ameliepetitcafe.com\nContraseña: 123456',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<RestaurantAuthService>();
      final success = await authService.loginRestaurant(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      if (success && mounted) {
        // Navegar a la pantalla correspondiente
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UniversalRestaurantAdminScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<RestaurantAuthService>();
      final success = await authService.registerRestaurant(
        name: _registerNameController.text.trim(),
        description: _registerDescriptionController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        address: _registerAddressController.text.trim(),
        phone: _registerPhoneController.text.trim(),
        whatsapp: _registerWhatsappController.text.trim(),
        totalTables: int.parse(_registerTablesController.text),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Restaurante registrado exitosamente!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // Navegar al admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UniversalRestaurantAdminScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}