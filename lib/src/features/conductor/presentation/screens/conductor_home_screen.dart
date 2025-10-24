import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/conductor_provider.dart';
import '../widgets/conductor_stats_card.dart';
import '../widgets/viaje_activo_card.dart';

class ConductorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> conductorUser;

  const ConductorHomeScreen({
    super.key,
    required this.conductorUser,
  });

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  int? _conductorId;

  @override
  void initState() {
    super.initState();
    // Defer the loading to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConductorData();
    });
  }

  Future<void> _loadConductorData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Extract conductor ID with better error handling
      _conductorId = int.tryParse(widget.conductorUser['id']?.toString() ?? '0');
      
      print('Loading conductor data for ID: $_conductorId');
      print('Conductor user data: ${widget.conductorUser}');

      if (_conductorId == null || _conductorId! <= 0) {
        print('Error: Invalid conductor ID: $_conductorId');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (!mounted) return;
      
      final provider = Provider.of<ConductorProvider>(context, listen: false);
      
      // Load data sequentially with error handling for each call
      await provider.loadConductorInfo(_conductorId!);
      if (!mounted) return;
      
      await provider.loadEstadisticas(_conductorId!);
      if (!mounted) return;
      
      await provider.loadViajesActivos(_conductorId!);
      
    } catch (e, stackTrace) {
      print('Error cargando datos del conductor: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFFF00).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color(0xFFFFFF00), Color(0xFFFFFF00)],
                ).createShader(bounds);
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Conductor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<ConductorProvider>(
          builder: (context, provider, child) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Switch(
                value: provider.disponible,
                activeColor: const Color(0xFFFFFF00),
                activeTrackColor: const Color(0xFFFFFF00).withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (value) async {
                  if (_conductorId != null) {
                    await provider.toggleDisponibilidad(
                      conductorId: _conductorId!,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Ahora estás disponible' : 'Ahora estás no disponible',
                        ),
                        backgroundColor: value ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFFFFF00),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildTripsTab();
      case 2:
        return _buildEarningsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildDisponibilityCard(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildViajesActivosSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final nombre = provider.conductor?.nombre ?? widget.conductorUser['nombre'] ?? 'Conductor';
        final hora = DateTime.now().hour;
        String saludo = 'Buenos días';
        if (hora >= 12 && hora < 18) {
          saludo = 'Buenas tardes';
        } else if (hora >= 18) {
          saludo = 'Buenas noches';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saludo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDisponibilityCard() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final disponible = provider.disponible;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: disponible
                    ? const Color(0xFFFFFF00).withOpacity(0.1)
                    : const Color(0xFF1A1A1A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: disponible
                      ? const Color(0xFFFFFF00).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: disponible
                          ? const Color(0xFFFFFF00)
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      disponible ? Icons.check_circle : Icons.cancel,
                      color: disponible ? Colors.black : Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disponible ? 'Disponible' : 'No disponible',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          disponible
                              ? 'Buscando solicitudes cercanas...'
                              : 'Activa tu disponibilidad para recibir viajes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;
        final conductor = provider.conductor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de hoy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ConductorStatsCard(
                    icon: Icons.route,
                    title: 'Viajes',
                    value: stats['viajes_hoy']?.toString() ?? '0',
                    color: const Color(0xFFFFFF00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConductorStatsCard(
                    icon: Icons.attach_money,
                    title: 'Ganancias',
                    value: '\$${stats['ganancias_hoy']?.toString() ?? '0'}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ConductorStatsCard(
                    icon: Icons.star,
                    title: 'Calificación',
                    value: conductor?.calificacionPromedio.toStringAsFixed(1) ?? '0.0',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConductorStatsCard(
                    icon: Icons.access_time,
                    title: 'Horas',
                    value: stats['horas_hoy']?.toString() ?? '0',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildViajesActivosSection() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final viajesActivos = provider.viajesActivos;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Viajes activos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (viajesActivos.isEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          color: Colors.white.withOpacity(0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes viajes activos',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Activa tu disponibilidad para recibir solicitudes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viajesActivos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return ViajeActivoCard(viaje: viajesActivos[index]);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildTripsTab() {
    return const Center(
      child: Text(
        'Historial de viajes',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildEarningsTab() {
    return const Center(
      child: Text(
        'Ganancias',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text(
        'Perfil',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Inicio'),
                  _buildNavItem(1, Icons.route_rounded, 'Viajes'),
                  _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Ganancias'),
                  _buildNavItem(3, Icons.person_rounded, 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFFF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
