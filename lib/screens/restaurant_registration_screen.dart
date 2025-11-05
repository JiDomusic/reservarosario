import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../services/subscription_service.dart';

class RestaurantRegistrationScreen extends StatefulWidget {
  const RestaurantRegistrationScreen({super.key});

  @override
  State<RestaurantRegistrationScreen> createState() =>
      _RestaurantRegistrationScreenState();
}

class _RestaurantRegistrationScreenState
    extends State<RestaurantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalTablesController = TextEditingController(text: '10');
  final _layoutDescriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _specialFeaturesController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _totalTablesController.dispose();
    _layoutDescriptionController.dispose();
    _capacityController.dispose();
    _specialFeaturesController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Error creando usuario');
      }

      // 2. Crear restaurante en la base de datos con layout detallado
      final layoutDescription = _buildLayoutDescription();
      final subscriptionInfo = SubscriptionService.getSubscriptionInfo();
      
      final restaurantData = {
        'name': _nameController.text.trim(),
        'description': layoutDescription,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'address': _addressController.text.trim(),
        'total_tables': int.parse(_totalTablesController.text),
        'auth_user_id': authResponse.user!.id,
        'is_active': false, // Inactivo hasta que pague
        'subscription_status': 'pending_payment',
        'monthly_fee': subscriptionInfo['monthly_fee'],
        'payment_method': subscriptionInfo['payment_method'],
      };

      final restaurantResponse = await supabase
          .from('restaurants')
          .insert(restaurantData)
          .select()
          .single();

      // 3. Crear mesas automáticamente
      await _createTablesForRestaurant(restaurantResponse['id']);

      // 4. Crear horarios por defecto
      await _createDefaultSchedules(restaurantResponse['id']);

      // 5. Mostrar pantalla de confirmación
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantPaymentScreen(
              restaurantId: restaurantResponse['id'],
              restaurantName: _nameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error registrando restaurante: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTablesForRestaurant(String restaurantId) async {
    final totalTables = int.parse(_totalTablesController.text);
    final tables = <Map<String, dynamic>>[];

    for (int i = 1; i <= totalTables; i++) {
      tables.add({
        'restaurant_id': restaurantId,
        'table_number': i,
        'capacity': i <= (totalTables * 0.4).round()
            ? 2
            : i <= (totalTables * 0.7).round()
                ? 4
                : 6,
        'location': i <= (totalTables * 0.5).round() ? 'Interior' : 'Terraza',
        'is_available': true,
      });
    }

    await supabase.from('restaurant_tables').insert(tables);
  }

  Future<void> _createDefaultSchedules(String restaurantId) async {
    final schedules = <Map<String, dynamic>>[];

    for (int dayOfWeek = 0; dayOfWeek <= 6; dayOfWeek++) {
      schedules.add({
        'restaurant_id': restaurantId,
        'day_of_week': dayOfWeek,
        'open_time': dayOfWeek == 0 ? '10:00:00' : '08:00:00',
        'close_time': dayOfWeek == 0 || dayOfWeek == 6 ? '00:00:00' : '23:00:00',
        'is_closed': false,
      });
    }

    await supabase.from('restaurant_schedules').insert(schedules);
  }

  String _buildLayoutDescription() {
    final baseDescription = _descriptionController.text.trim();
    final totalTables = int.parse(_totalTablesController.text);
    final capacity = _capacityController.text.trim();
    final layoutDetails = _layoutDescriptionController.text.trim();
    final specialFeatures = _specialFeaturesController.text.trim();

    return '''$baseDescription

🏢 LAYOUT FÍSICO:
• Mesas disponibles: $totalTables mesas para reservas online
• Capacidad total: ${capacity.isNotEmpty ? capacity : '${totalTables * 3}'} personas
${layoutDetails.isNotEmpty ? '• $layoutDetails' : '• Distribución: Interior y terraza'}
${specialFeatures.isNotEmpty ? '• Características especiales: $specialFeatures' : ''}

📍 Todas las mesas están disponibles para reservas online a través de Gastronómica Rosario.''';
  }

  void _showPaymentDetails(BuildContext context) {
    final subscriptionInfo = SubscriptionService.getSubscriptionInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Información de Pago',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF86704),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Para realizar el pago de tu suscripción:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'Monto: \$${subscriptionInfo['monthly_fee'].toStringAsFixed(0)} ${subscriptionInfo['currency']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF86704),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Te enviaremos los datos bancarios de forma segura por WhatsApp.',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '✅ Usted no hablará con un robot',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp(subscriptionInfo['whatsapp']);
            },
            icon: const Icon(Icons.message, color: Colors.white, size: 16),
            label: const Text(
              'Contactar por WhatsApp',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(String phoneNumber) {
    final message = 'Hola! Necesito los datos bancarios para realizar el pago de la suscripción mensual (\$50.000 ARS) para mi restaurante. Gracias!';
    final whatsappUrl = 'https://wa.me/${phoneNumber.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '')}?text=${Uri.encodeComponent(message)}';
    
    // En una app real usarías url_launcher
    print('Abrir WhatsApp: $whatsappUrl');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contactando por WhatsApp: $phoneNumber'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registrar Restaurante'),
        backgroundColor: const Color(0xFFF86704),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF86704), Color(0xFFFF8C42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Gastronómica Rosario',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Únete a la plataforma de reservas más exitosa de Rosario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              const Text(
                'Información del Restaurante',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Restaurante *',
                  prefixIcon: const Icon(Icons.restaurant, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre del restaurante';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp',
                  prefixIcon: const Icon(Icons.message, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _totalTablesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad de Mesas *',
                  prefixIcon: const Icon(Icons.table_restaurant, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la cantidad de mesas';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 5 || number > 50) {
                    return 'Debe ser entre 5 y 50 mesas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacidad Total de Personas',
                  hintText: 'Ej: 60 personas',
                  prefixIcon: const Icon(Icons.people, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _layoutDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción del Layout',
                  hintText: 'Ej: Mesas bajas, mesas altas de barra, sector VIP, terraza cubierta, etc.',
                  prefixIcon: const Icon(Icons.architecture, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _specialFeaturesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Características Especiales',
                  hintText: 'Ej: Parrilla a la vista, cocina abierta, barra de tragos, sala privada, etc.',
                  prefixIcon: const Icon(Icons.star, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Datos de Acceso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFFF86704)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFF86704)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFF86704)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF86704), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme la contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Color(0xFFF86704)),
                        SizedBox(width: 10),
                        Text(
                          'Información de Suscripción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF86704),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('• Costo mensual: \$50.000 ARS'),
                    Text('• Pago por transferencia bancaria'),
                    Text('• Activación manual tras confirmación de pago'),
                    Text('• Todas las funcionalidades incluidas'),
                    Text('• Sistema de tolerancia de 15 minutos'),
                    Text('• Panel administrativo completo'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF86704),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrar Restaurante',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class RestaurantPaymentScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantPaymentScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantPaymentScreen> createState() => _RestaurantPaymentScreenState();
}

class _RestaurantPaymentScreenState extends State<RestaurantPaymentScreen> {
  void _showPaymentDetailsDialog(BuildContext context) {
    final subscriptionInfo = SubscriptionService.getSubscriptionInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Información de Pago',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF86704),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Para realizar el pago de tu suscripción:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'Monto: \$${subscriptionInfo['monthly_fee'].toStringAsFixed(0)} ${subscriptionInfo['currency']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF86704),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Te enviaremos los datos bancarios de forma segura por WhatsApp.',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '✅ Usted no hablará con un robot',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsAppFromPaymentScreen(subscriptionInfo['whatsapp']);
            },
            icon: const Icon(Icons.message, color: Colors.white, size: 16),
            label: const Text(
              'Contactar por WhatsApp',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsAppFromPaymentScreen(String phoneNumber) {
    final message = 'Hola! Necesito los datos bancarios para realizar el pago de la suscripción mensual (\$50.000 ARS) para mi restaurante. Gracias!';
    final whatsappUrl = 'https://wa.me/${phoneNumber.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '')}?text=${Uri.encodeComponent(message)}';
    
    // En una app real usarías url_launcher
    print('Abrir WhatsApp desde pantalla de pago: $whatsappUrl');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contactando por WhatsApp: $phoneNumber'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Información de Pago'),
        backgroundColor: const Color(0xFFF86704),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '¡Registro Exitoso!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.restaurantName} se ha registrado correctamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Siguiente Paso: Realizar el Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de Pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF86704),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  const Text('• Suscripción mensual: \$50.000 ARS'),
                  const Text('• Pago por transferencia bancaria'),
                  const Text('• Activación en 24-48 horas'),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDetailsDialog(context),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        'Contactar para Realizar Pago',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Instrucciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('1. Contacte por WhatsApp para recibir datos bancarios'),
                  Text('2. Realice la transferencia por el monto exacto'),
                  Text('3. Envíe el comprobante por WhatsApp'),
                  Text('4. Incluya el nombre del restaurante en el mensaje'),
                  Text('5. La activación se realizará en 24-48 horas'),
                  Text('6. Recibirá confirmación por email'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Copiar CBU al portapapeles y abrir WhatsApp
                    },
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text(
                      'Enviar Comprobante',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaceholderLoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text(
                      'Ir a Login',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF86704),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    );
  }
}

// Placeholder for login screen
class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Restaurante'),
        backgroundColor: const Color(0xFFF86704),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Pantalla de Login - Por implementar'),
      ),
    );
  }
}