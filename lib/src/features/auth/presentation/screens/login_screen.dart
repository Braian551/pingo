// lib/src/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:ping_go/src/routes/route_names.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';

class LoginScreen extends StatefulWidget {
  final String? email;
  final bool? prefilled;

  const LoginScreen({
    super.key,
    this.email,
    this.prefilled = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Prellenar email si viene de verificación
    // If an email was provided via args, fill the controller; otherwise we'll try session when building
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Llamar al endpoint de login (email + password)
        // Resolve email: prefer controller (argument), otherwise try saved session
        String emailToUse = _emailController.text;
        if (emailToUse.isEmpty) {
          final sess = await UserService.getSavedSession();
          if (sess != null && sess['email'] != null) emailToUse = sess['email'] as String;
        }

        final resp = await UserService.login(email: emailToUse, password: _passwordController.text);
        print('Login response: $resp');

          if (resp['success'] == true) {
          _showSuccess('¡Bienvenido de nuevo!');
          await Future.delayed(const Duration(milliseconds: 500));
          // Guardar sesión localmente
          try {
            await UserService.saveSession(resp['data']?['user'] ?? {'email': emailToUse});
          } catch (_) {}

          if (mounted) {
            Navigator.pushReplacementNamed(context, RouteNames.home, arguments: {'email': emailToUse});
          }
        } else {
          _showError(resp['message'] ?? 'Credenciales inválidas');
        }
      } catch (e) {
        _showError('Error al iniciar sesión: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            
            // Título
            const Text(
              'Confirma tu contraseña',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),

            // Subtítulo
            const Text(
              'Ingresa tu contraseña para continuar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Formulario
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Mostrar el email que se usará (no editable) si está disponible
                  if (_emailController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Color(0xFF39FF14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _emailController.text,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Campo de contraseña
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
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implementar recuperación de contraseña
                        _showError('Función en desarrollo');
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: Colors.black,
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
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  
                  
                 
                  
                
                  
                  // Nota: se ha removido el prompt de verificación de email
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}