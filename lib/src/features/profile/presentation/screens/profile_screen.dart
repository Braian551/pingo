import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';
import 'package:ping_go/src/features/map/presentation/screens/location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// A widget that renders the profile content without its own Scaffold/AppBar
/// so it can be embedded as a tab inside a parent scaffold.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final sess = await UserService.getSavedSession();
    setState(() {
      _session = sess;
    });

    if (sess != null) {
      final id = sess['id'] as int?;
      final email = sess['email'] as String?;
      final profile = await UserService.getProfile(userId: id, email: email);
      if (profile != null && profile['success'] == true) {
        setState(() {
          _profileData = profile['user'] as Map<String, dynamic>?;
        });
      }
    }

    setState(() => _loading = false);
  }

  void _logout() async {
    await UserService.clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _session?['email'] as String?;

    return _loading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14))))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.black.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF1A1A1A),
                          child: Icon(Icons.person, color: Color(0xFF39FF14), size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profileData != null ? '${_profileData!['nombre'] ?? ''} ${_profileData!['apellido'] ?? ''}' : (email ?? 'Usuario'),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email ?? 'No hay sesión',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const LocationPickerScreen()),
                    );
                    if (res != null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección actualizada')));
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Editar dirección'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final sess = await UserService.getSavedSession();
    setState(() {
      _session = sess;
    });

    if (sess != null) {
      final id = sess['id'] as int?;
      final email = sess['email'] as String?;
      final profile = await UserService.getProfile(userId: id, email: email);
      if (profile != null && profile['success'] == true) {
        setState(() {
          _profileData = profile['user'] as Map<String, dynamic>?;
        });
      }
    }

    setState(() => _loading = false);
  }

  void _logout() async {
    await UserService.clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _session?['email'] as String?;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Perfil', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14))))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.black.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF1A1A1A),
                            child: Icon(Icons.person, color: Color(0xFF39FF14), size: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profileData != null ? '${_profileData!['nombre'] ?? ''} ${_profileData!['apellido'] ?? ''}' : (email ?? 'Usuario'),
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email ?? 'No hay sesión',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Abrir LocationPicker para editar dirección
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const LocationPickerScreen()),
                      );
                      if (res != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dirección actualizada')));
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Editar dirección'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39FF14), foregroundColor: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
