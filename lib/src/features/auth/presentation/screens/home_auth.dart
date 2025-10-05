import 'package:flutter/material.dart';
import 'package:ping_go/src/global/services/auth/user_service.dart';

class HomeAuth extends StatefulWidget {
  const HomeAuth({super.key});

  @override
  State<HomeAuth> createState() => _HomeAuthState();
}

class _HomeAuthState extends State<HomeAuth> {
  String? _name;
  String? _address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    try {
      final sess = await UserService.getSavedSession();
      if (sess != null) {
        // Derivar nombre desde session/email si no hay campo explícito
        _name = _deriveNameFromSession(sess);
        // Dirección: intentar obtenerla del perfil o de la sesión
        _address = null;
        // Intentar obtener perfil completo desde backend si hay email
        try {
          final prof = await UserService.getProfile(email: sess['email'] as String?);
          // Debug: print profile response for inspection
          try { print('Profile response: $prof'); } catch (_) {}

          if (prof != null && prof['data'] != null && prof['data']['user'] != null) {
            final user = prof['data']['user'] as Map<String, dynamic>;
            if (user['name'] != null && (user['name'] as String).isNotEmpty) _name = user['name'] as String;
            // EXTRAER DIRECCIÓN de forma flexible: distintos backends pueden devolverla con nombres distintos
            String? addr = _extractAddressFromUser(user);
            // también revisar data-level locations/ubicaciones
            if ((addr == null || addr.isEmpty) && prof['data'] is Map<String, dynamic>) {
              final dataMap = prof['data'] as Map<String, dynamic>;
              addr = _extractAddressFromDataMap(dataMap);
            }
            if (addr != null && addr.isNotEmpty) {
              _address = addr;
            } else {
              // Try additional common single-location key that some backends return
              if (prof['data'] is Map<String, dynamic>) {
                final dataMap = prof['data'] as Map<String, dynamic>;
                if (dataMap.containsKey('location') && dataMap['location'] is Map<String, dynamic>) {
                  final loc = dataMap['location'] as Map<String, dynamic>;
                  final a2 = _mapToAddressString(loc);
                  if (a2.isNotEmpty) addr = a2;
                }
                // also try top-level 'location' inside user
                if ((addr == null || addr.isEmpty) && user.containsKey('location') && user['location'] is Map<String, dynamic>) {
                  final loc2 = user['location'] as Map<String, dynamic>;
                  final a3 = _mapToAddressString(loc2);
                  if (a3.isNotEmpty) addr = a3;
                }
              }

              // If still no address found, expose the raw profile JSON in _debugProfile for troubleshooting
              if (addr == null || addr.isEmpty) {
                _debugProfile = prof;
              } else {
                _address = addr;
              }
            }
          } else {
            _debugProfile = prof;
          }
        } catch (e) {
          print('Error loading profile in HomeAuth: $e');
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // For troubleshooting: store raw profile response when address not found
  Map<String, dynamic>? _debugProfile;

  String? _extractAddressFromUser(Map<String, dynamic> user) {
    // Keys to try in order
    final candidates = [
      'address',
      'direccion',
      'direccion_formateada',
      'formatted_address',
      'direccion_completa',
    ];

    for (final k in candidates) {
      if (user.containsKey(k) && user[k] != null) {
        final v = user[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }

    // Some backends return a list of locations under different keys
    final listKeys = ['locations', 'ubicaciones', 'addresses', 'direcciones'];
    for (final lk in listKeys) {
      if (user.containsKey(lk) && user[lk] is List && (user[lk] as List).isNotEmpty) {
        final first = (user[lk] as List).first;
        if (first is Map<String, dynamic>) {
          final addr = _mapToAddressString(first);
          if (addr.isNotEmpty) return addr;
        } else if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }

    return null;
  }

  String? _extractAddressFromDataMap(Map<String, dynamic> data) {
    // data may contain a 'locations' or 'ubicaciones' list
    final listKeys = ['locations', 'ubicaciones', 'user_locations', 'user_addresses'];
    for (final lk in listKeys) {
      if (data.containsKey(lk) && data[lk] is List && (data[lk] as List).isNotEmpty) {
        final first = (data[lk] as List).first;
        if (first is Map<String, dynamic>) {
          final addr = _mapToAddressString(first);
          if (addr.isNotEmpty) return addr;
        } else if (first is String && first.isNotEmpty) {
          return first;
        }
      }
    }
    return null;
  }

  String _mapToAddressString(Map<String, dynamic> m) {
    // Try common keys
    final keys = ['address','direccion','direccion_recogida','direccion_destino','direccion_formateada','formatted_address','direccion_completa'];
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null && m[k] is String && (m[k] as String).isNotEmpty) return m[k] as String;
    }

    // Fall back to composing from components
    final parts = <String>[];
    if (m['direccion'] is String && (m['direccion'] as String).isNotEmpty) parts.add(m['direccion']);
    if (m['address'] is String && (m['address'] as String).isNotEmpty) parts.add(m['address']);
    if (m['city'] is String && (m['city'] as String).isNotEmpty) parts.add(m['city']);
    if (m['state'] is String && (m['state'] as String).isNotEmpty) parts.add(m['state']);
    if (parts.isNotEmpty) return parts.join(', ');
    return '';
  }

  String? _deriveNameFromSession(Map<String, dynamic> sess) {
    if (sess.containsKey('name') && (sess['name'] as String).isNotEmpty) return sess['name'] as String;
    final email = sess['email'] as String?;
    if (email == null) return null;
    final parts = email.split('@');
    if (parts.isEmpty) return email;
    final user = parts[0];
    // Capitalize simple
    return user.split('.').map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF39FF14);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
              const Icon(Icons.motorcycle, color: Colors.white),
            const SizedBox(width: 10),
            const Text('PingGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola${_name != null ? ', $_name' : '!'}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Dirección: mostrar en una tarjeta moderna (o CTA para agregar)
                  _AddressCard(
                    address: _address,
                    onEdit: () => Navigator.pushNamed(context, '/location-picker'),
                  ),

                  // Debug panel: mostrar JSON crudo del perfil si no se encontró dirección (solo en desarrollo)
                  if (_address == null || _address!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _debugProfile != null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  _debugProfile.toString(),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.motorcycle,
                          title: 'Transporte',
                          subtitle: 'Solicita un viaje',
                          accent: accent,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.local_shipping,
                          title: 'Envíos',
                          subtitle: 'Envía paquetes',
                          accent: accent,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildQuickActions(accent),

                  const SizedBox(height: 24),

                  const Text('Historial reciente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.history, color: Colors.white24, size: 48),
                        SizedBox(height: 8),
                        Text('No hay viajes recientes', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: accent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 0,
        onTap: (i) {},
      ),
    );
  }

  Widget _buildQuickActions(Color accent) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.payment, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Métodos de pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Agrega tarjeta o efectivo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String? address;
  final VoidCallback onEdit;

  const _AddressCard({required this.address, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF39FF14);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: accent, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address != null && address!.isNotEmpty ? 'Tu dirección' : 'Sin dirección',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  address != null && address!.isNotEmpty ? address! : 'Añade una dirección para empezar a usar los servicios',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              backgroundColor: accent.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(
              address != null && address!.isNotEmpty ? 'Editar' : 'Agregar',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
