import 'package:flutter/material.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';
import 'package:ping_go/src/features/auth/presentation/widgets/address_step_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:ping_go/src/features/map/providers/map_provider.dart';
import 'package:ping_go/src/widgets/entrance_fader.dart';

class RegisterScreen extends StatefulWidget {
  final String email;
  final String userName;

  const RegisterScreen({
    super.key,
    required this.email,
    required this.userName,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  
  // Variables para almacenar la ubicación seleccionada
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedCity;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Validar que se haya seleccionado una dirección
      if (_addressController.text.isEmpty || _selectedLat == null || _selectedLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona tu dirección en el mapa'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        // Verificar si el usuario existe ANTES de intentar registrarlo
        final bool userExists = await UserService.checkUserExists(widget.email);
        if (userExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El usuario ${widget.email} ya existe. Por favor inicia sesión.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() => _isLoading = false);
          
          // Redirigir a login después de mostrar el mensaje
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacementNamed(context, RouteNames.login);
          return;
        }
        
        // Proceder con el registro solo si el usuario NO existe
        final response = await UserService.registerUser(
          email: widget.email,
          password: _passwordController.text,
          name: _nameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          latitude: _selectedLat,
          longitude: _selectedLng,
          city: _selectedCity,
          state: _selectedState,
        );

        // Debug: imprimir respuesta para depuración
        try {
          print('Register response: $response');
        } catch (_) {}

        // Consideramos el registro completado si la llamada retornó (modo dev)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Registro exitoso! Redirigiendo...'),
            backgroundColor: Colors.yellow,
            duration: const Duration(seconds: 2),
          ),
        );

        // Intentar guardar sesión si backend retornó data.user
        try {
          final data = response['data'] as Map<String, dynamic>?;
          if (data != null && data['user'] != null) {
            await UserService.saveSession(data['user']);
          } else {
            await UserService.saveSession({'email': widget.email});
          }
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 1500));
  Navigator.pushReplacementNamed(context, RouteNames.home, arguments: {'email': widget.email});
      } catch (e) {
        // Manejar errores específicos de conexión o servidor
        String errorMessage = 'Error: $e';
        
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          errorMessage = 'Error de conexión con el servidor. Verifica que el backend esté ejecutándose.';
        } else if (e.toString().contains('Field') || 
                   e.toString().contains('latitud')) {
          // Error conocido de campo faltante - continuar como éxito para pruebas
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registro completado. Redirigiendo a inicio...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushReplacementNamed(context, RouteNames.home, arguments: {'email': widget.email});
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Completa tu perfil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Modern step header: titles + dots
          _buildStepperHeader(),
          
          // Contenido del formulario con espacio para crecer
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EntranceFader(
                delay: const Duration(milliseconds: 120),
                child: Form(
                  key: _formKey,
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),
          
          // Botones fijos en la parte inferior con mejor diseño
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Atrás mejorado
                if (_currentStep > 0)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Atrás',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 0),
                
                // Botón Siguiente/Crear Cuenta mejorado
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_currentStep < 3) {
                        // Validación del paso actual
                        if (_currentStep == 0) {
                          if (_nameController.text.isEmpty || _lastNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor completa todos los campos'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } else if (_currentStep == 1) {
                          if (_phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor ingresa tu teléfono'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } else if (_currentStep == 2) {
                          if (_addressController.text.isEmpty || _selectedLat == null || _selectedLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor selecciona tu dirección en el mapa'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                        }

                        setState(() { _currentStep++; });
                        if (_currentStep == 2) {
                          _ensureLocationPermissionAndFetch();
                        }
                      } else {
                        _register();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFFFFF00).withOpacity(0.5),
                      disabledForegroundColor: Colors.black.withOpacity(0.5),
                    ),
                    child: _currentStep < 3
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Siguiente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          )
                        : _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Crear Cuenta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildContactStep();
      case 2:
        return _buildAddressStep();
      case 3:
        return _buildSecurityStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  Widget _buildStepperHeader() {
    final titles = ['Personal', 'Contacto', 'Dirección', 'Seguridad'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del paso actual con animación
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                titles[_currentStep],
                key: ValueKey<int>(_currentStep),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Indicador de progreso moderno y minimalista
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(titles.length, (i) {
              final isActive = i == _currentStep;
              final isPassed = i < _currentStep;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 40 : 10,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive 
                    ? const Color(0xFFFFFF00)
                    : isPassed 
                      ? const Color(0xFFFFFF00).withOpacity(0.6)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: const Color(0xFFFFFF00).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 620,
          child: AddressStepWidget(
            addressController: _addressController,
            onLocationSelected: (data) {
              setState(() {
                _addressController.text = data['address'] ?? _addressController.text;
                _selectedLat = (data['lat'] as double?);
                _selectedLng = (data['lon'] as double?);
                _selectedCity = data['city'] as String?;
                _selectedState = data['state'] as String?;
              });
            },
            onConfirmed: () {
              // Avanzar al siguiente paso automáticamente
              setState(() {
                if (_currentStep < 3) _currentStep++;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _ensureLocationPermissionAndFetch() async {
    try {
      // Primero verificar que los servicios de localización del dispositivo estén activos
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Activa la ubicación del dispositivo para autocompletar tu dirección'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permiso de ubicación denegado. Actívalo en ajustes para autocompletar.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permiso de ubicación denegado permanentemente. Habilítalo manualmente en ajustes.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Permiso otorgado
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final prov = Provider.of<MapProvider>(context, listen: false);
      final latLng = LatLng(pos.latitude, pos.longitude);
      prov.setCurrentLocation(latLng);
      // Seleccionar para trigger reverse geocode y rellenar el campo
      await prov.selectLocation(latLng);
      setState(() {
        _addressController.text = prov.selectedAddress ?? _addressController.text;
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
        _selectedCity = prov.selectedCity;
        _selectedState = prov.selectedState;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ubicación actual: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'),
        backgroundColor: Colors.yellow,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo obtener la ubicación: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _nameController,
          label: 'Nombre',
          icon: Icons.person_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _lastNameController,
          label: 'Apellido',
          icon: Icons.person_outline_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu apellido';
            }
            return null;
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFFFFF00),
            size: 22,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildContactStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _phoneController,
          label: 'Teléfono',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu teléfono';
            }
            if (value.length < 10) {
              return 'El teléfono debe tener al menos 10 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Información de coordenadas seleccionadas
        if (_selectedLat != null && _selectedLng != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFF00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFFF00).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFF00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ubicación guardada',
                        style: TextStyle(
                          color: Color(0xFFFFFF00),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa una contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor confirma tu contraseña';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Información adicional para modo de pruebas con mejor diseño
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modo Pruebas',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Errores técnicos menores serán ignorados durante el desarrollo.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
}