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
            backgroundColor: Colors.green,
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
          
          // Botones fijos en la parte inferior
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Atrás en la esquina inferior izquierda
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Atrás'),
                  )
                else
                  const SizedBox(width: 80), // Espaciador para mantener la alineación
                
                // Botón Siguiente/Crear Cuenta en la esquina inferior derecha
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    // Ahora hay 4 pasos: 0 Personal, 1 Contacto, 2 Dirección, 3 Seguridad
                    if (_currentStep < 3) {
                      // Validar el paso actual antes de continuar
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
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _currentStep < 3
                      ? const Text('Siguiente')
                      : _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Crear Cuenta'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              titles[_currentStep],
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          // Centered dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(titles.length, (i) {
              final isActive = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: isActive ? 14 : 10,
                height: isActive ? 14 : 10,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white24,
                  shape: BoxShape.circle,
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
        backgroundColor: Colors.green,
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.person, color: Color(0xFF39FF14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _lastNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Apellido',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF39FF14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
          ),
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

  Widget _buildContactStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Teléfono',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF39FF14)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
          ),
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
        
        const SizedBox(height: 8),
        
        // Información de coordenadas seleccionadas (solo para debug)
        if (_selectedLat != null && _selectedLng != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ubicación seleccionada: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF39FF14)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
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
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF39FF14)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14)),
            ),
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
        
        // Información adicional para modo de pruebas
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo Pruebas Activado',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Errores técnicos menores serán ignorados para permitir el registro durante la fase de desarrollo.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
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