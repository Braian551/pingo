import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/conductor_provider.dart';
import '../../providers/conductor_profile_provider.dart';
import '../../models/conductor_profile_model.dart';
import '../../services/approval_notification_service.dart';
import '../widgets/viaje_activo_card.dart';
import '../widgets/conductor_alerts.dart';
import '../widgets/approval_success_dialog.dart';
import 'conductor_profile_screen.dart';
import 'conductor_earnings_screen.dart';
import 'conductor_trips_screen.dart';
import 'license_registration_screen.dart';
import 'vehicle_only_registration_screen.dart';
import 'conductor_searching_passengers_screen.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/theme_provider.dart';

class ConductorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> conductorUser;

  const ConductorHomeScreen({super.key, required this.conductorUser});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  int? _conductorId;
  bool _hasShownProfileAlert = false;

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
      _conductorId = int.tryParse(
        widget.conductorUser['id']?.toString() ?? '0',
      );

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
      if (!mounted) return;

      // Load conductor profile
      final profileProvider = Provider.of<ConductorProfileProvider>(
        context,
        listen: false,
      );
      await profileProvider.loadProfile(_conductorId!);
      if (!mounted) return;

      // Check if profile is incomplete and show alert if not shown before
      final profile = profileProvider.profile;
      if (profile != null) {
        // Verificar si debe mostrar alerta de aprobaciÃ³n
        final shouldShowApproval =
            await ApprovalNotificationService.shouldShowApprovalAlert(
              _conductorId!,
              profile.estadoVerificacion.value,
              profile.aprobado,
            );

        if (shouldShowApproval && mounted) {
          // Esperar un poco antes de mostrar el diÃ¡logo
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            await ApprovalSuccessDialog.show(context);
            // Marcar como mostrado
            await ApprovalNotificationService.markApprovalAlertAsShown(
              _conductorId!,
            );
          }
        }

        // Verificar alertas de perfil incompleto
        if (!_hasShownProfileAlert) {
          final actionType = getProfileActionType(profile);

          // Only show alert if there are pending actions (not in review or complete)
          if (actionType == ProfileAction.registerLicense ||
              actionType == ProfileAction.registerVehicle ||
              actionType == ProfileAction.submitVerification) {
            _hasShownProfileAlert = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ProfileIncompleteAlert.show(
                  context,
                  missingItems: profile.pendingTasks.isEmpty
                      ? [
                          'Registrar licencia de conducciÃƒÂ³n',
                          'Registrar vehÃƒÂ­culo',
                          'Completar documentos',
                        ]
                      : profile.pendingTasks,
                  dismissible: true,
                  actionType: actionType,
                ).then((shouldComplete) {
                  if (shouldComplete == true && mounted) {
                    _handleProfileAction(actionType, profile);
                  }
                });
              }
            });
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error cargando datos del conductor: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleProfileAction(
    ProfileAction actionType,
    ConductorProfileModel profile,
  ) {
    switch (actionType) {
      case ProfileAction.registerLicense:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LicenseRegistrationScreen(
              conductorId: _conductorId!,
              existingLicense: profile.licencia,
            ),
          ),
        ).then((result) {
          if (result == true) {
            final profileProvider = Provider.of<ConductorProfileProvider>(
              context,
              listen: false,
            );
            profileProvider.loadProfile(_conductorId!);
          }
        });
        break;

      case ProfileAction.registerVehicle:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleOnlyRegistrationScreen(
              conductorId: _conductorId!,
              existingVehicle: profile.vehiculo,
            ),
          ),
        ).then((result) {
          if (result == true) {
            final profileProvider = Provider.of<ConductorProfileProvider>(
              context,
              listen: false,
            );
            profileProvider.loadProfile(_conductorId!);
          }
        });
        break;

      case ProfileAction.submitVerification:
      case ProfileAction.completeProfile:
      case ProfileAction.inReview:
      case ProfileAction.awaitingApproval:
        // Navegar a la pantalla de perfil
        // La pantalla detectarÃƒÂ¡ automÃƒÂ¡ticamente si el conductor estÃƒÂ¡ aprobado
        final profileProvider = Provider.of<ConductorProfileProvider>(
          context,
          listen: false,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConductorProfileScreen(conductorId: _conductorId!),
          ),
        ).then((result) {
          profileProvider.loadProfile(_conductorId!);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
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
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (value) async {
                  if (_conductorId == null) return;

                  // Check if profile is complete before allowing availability
                  if (value) {
                    final profileProvider =
                        Provider.of<ConductorProfileProvider>(
                          context,
                          listen: false,
                        );

                    // Load profile if not loaded
                    if (profileProvider.profile == null) {
                      await profileProvider.loadProfile(_conductorId!);
                    }

                    final profile = profileProvider.profile;

                    // Check if can be available
                    if (profile == null) {
                      // Show error if profile couldn't be loaded
                      ErrorNotification.show(
                        context,
                        message:
                            'No se pudo verificar tu perfil. Intenta nuevamente.',
                      );
                      return;
                    }

                    if (!profile.canBeAvailable) {
                      // Show appropriate alert based on profile status
                      final actionType = getProfileActionType(profile);

                      // Always show alert, but content depends on status
                      final shouldComplete = await ProfileIncompleteAlert.show(
                        context,
                        missingItems: profile.pendingTasks.isEmpty
                            ? [
                                'Registrar licencia de conducciÃƒÂ³n',
                                'Registrar vehÃƒÂ­culo',
                                'Completar documentos',
                              ]
                            : profile.pendingTasks,
                        dismissible: true,
                        actionType: actionType,
                      );

                      if (shouldComplete == true && mounted) {
                        _handleProfileAction(actionType, profile);
                      }
                      return;
                    }

                    // Perfil completo - navegar a pantalla de bÃºsqueda
                    final nombre =
                        provider.conductor?.nombre ??
                        widget.conductorUser['nombre'] ??
                        'Conductor';
                    final tipoVehiculo = profile.vehiculo?.tipo.value ?? 'moto';

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConductorSearchingPassengersScreen(
                              conductorId: _conductorId!,
                              conductorNombre: nombre,
                              tipoVehiculo: tipoVehiculo,
                            ),
                      ),
                    );

                    // Si el conductor aceptÃƒÂ³ un viaje, recargar datos
                    if (result == true && mounted) {
                      await provider.loadViajesActivos(_conductorId!);
                    }
                  } else {
                    // Toggle availability off
                    await provider.toggleDisponibilidad(
                      conductorId: _conductorId!,
                    );

                    if (mounted) {
                      SuccessNotification.show(
                        context,
                        message: 'Has dejado de estar disponible',
                      );
                    }
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
    return _buildShimmerLoading();
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Welcome section shimmer
            _buildShimmerBox(height: 20, width: 120),
            const SizedBox(height: 8),
            _buildShimmerBox(height: 40, width: 200),
            const SizedBox(height: 24),
            // Disponibility card shimmer
            _buildShimmerBox(height: 100, width: double.infinity),
            const SizedBox(height: 24),
            // Stats title shimmer
            _buildShimmerBox(height: 28, width: 180),
            const SizedBox(height: 16),
            // Stats cards shimmer
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBox(height: 100)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBox(height: 100)),
              ],
            ),
            const SizedBox(height: 24),
            // Active trips title shimmer
            _buildShimmerBox(height: 28, width: 150),
            const SizedBox(height: 16),
            // Active trips card shimmer
            _buildShimmerBox(height: 150, width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, double? width}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Shimmer.fromColors(
          baseColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface.withOpacity(0.1),
          highlightColor: isDark
              ? AppColors.darkCard
              : AppColors.lightCard.withOpacity(0.2),
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return ConductorTripsScreen(conductorId: _conductorId ?? 0);
      case 2:
        return ConductorEarningsScreen(conductorId: _conductorId ?? 0);
      case 3:
        return ConductorProfileScreen(
          conductorId: _conductorId ?? 0,
          showBackButton: false,
        );
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadConductorData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Hero Header Section
            SliverToBoxAdapter(child: _buildHeroSection()),

            // Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildModernStatusCard(),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickStatsGrid(),
              ),
            ),

            // Active Trips Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActiveTripsSection(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ==================== NUEVO DISEÃ‘O MODERNO ====================

  Widget _buildHeroSection() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final nombre =
            provider.conductor?.nombre ??
            widget.conductorUser['nombre'] ??
            'Conductor';
        final hora = DateTime.now().hour;
        String emoji = 'ðŸŒ…';
        String saludo = 'Buenos dÃ­as';

        if (hora >= 12 && hora < 18) {
          saludo = 'Buenas tardes';
          emoji = 'â˜€ï¸';
        } else if (hora >= 18) {
          saludo = 'Buenas noches';
          emoji = 'ðŸŒ™';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary.withOpacity(0.08), Colors.transparent],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saludo,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nombre.split(' ').first,
                          style: TextStyle(
                            color: theme.textTheme.displayMedium?.color,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.conductor?.calificacionPromedio
                                  .toStringAsFixed(1) ??
                              '5.0',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatusCard() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final disponible = provider.disponible;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: disponible
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? AppColors.darkCard.withOpacity(0.8)
                                  : AppColors.lightCard.withOpacity(0.8),
                              isDark
                                  ? AppColors.darkCard.withOpacity(0.6)
                                  : AppColors.lightCard.withOpacity(0.6),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: disponible
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Status Icon
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(
                              begin: 0.0,
                              end: disponible ? 1.0 : 0.0,
                            ),
                            builder: (context, value, child) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: disponible
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  disponible
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                  color: disponible
                                      ? Colors.white
                                      : Colors.grey[400],
                                  size: 32,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          // Status Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disponible
                                      ? 'ðŸš€ EstÃ¡s en lÃ­nea'
                                      : 'â¸ï¸ Fuera de lÃ­nea',
                                  style: TextStyle(
                                    color: disponible
                                        ? Colors.white
                                        : theme.textTheme.headlineSmall?.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  disponible
                                      ? 'Buscando viajes cerca de ti'
                                      : 'ActÃ­vate para empezar a recibir viajes',
                                  style: TextStyle(
                                    color: disponible
                                        ? Colors.white.withOpacity(0.9)
                                        : theme.textTheme.bodyMedium?.color
                                              ?.withOpacity(0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (disponible) ...[
                        const SizedBox(height: 20),
                        // Searching Animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 2),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStatsGrid() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final stats = provider.estadisticas;

        final statsData = [
          {
            'icon': Icons.local_taxi_rounded,
            'label': 'Viajes hoy',
            'value': stats['viajes_hoy']?.toString() ?? '0',
            'color': const Color(0xFF6366F1),
            'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          },
          {
            'icon': Icons.payments_rounded,
            'label': 'Ganancias',
            'value': '\$${stats['ganancias_hoy']?.toString() ?? '0'}',
            'color': const Color(0xFF10B981),
            'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
          },
          {
            'icon': Icons.schedule_rounded,
            'label': 'Horas activo',
            'value': '${stats['horas_hoy']?.toString() ?? '0'}h',
            'color': const Color(0xFFF59E0B),
            'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          },
          {
            'icon': Icons.trending_up_rounded,
            'label': 'Promedio',
            'value':
                '\$${((stats['ganancias_hoy'] ?? 0) / (stats['viajes_hoy'] ?? 1)).toStringAsFixed(0)}',
            'color': const Color(0xFFEC4899),
            'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tu dÃ­a en nÃºmeros',
                    style: TextStyle(
                      color: theme.textTheme.headlineMedium?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: statsData.length,
              itemBuilder: (context, index) {
                final stat = statsData[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (stat['color'] as Color).withOpacity(0.1),
                                (stat['color'] as Color).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (stat['color'] as Color).withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: stat['gradient'] as List<Color>,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (stat['color'] as Color)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  stat['icon'] as IconData,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat['value'] as String,
                                    style: TextStyle(
                                      color:
                                          theme.textTheme.displayMedium?.color,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stat['label'] as String,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildActiveTripsSection() {
    return Consumer<ConductorProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final viajesActivos = provider.viajesActivos;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Viajes en curso',
                    style: TextStyle(
                      color: theme.textTheme.headlineMedium?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (viajesActivos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${viajesActivos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (viajesActivos.isEmpty)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? AppColors.darkCard.withOpacity(0.5)
                                  : AppColors.lightCard.withOpacity(0.5),
                              isDark
                                  ? AppColors.darkCard.withOpacity(0.3)
                                  : AppColors.lightCard.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.explore_rounded,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Sin viajes activos',
                              style: TextStyle(
                                color: theme.textTheme.titleMedium?.color,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Activa tu disponibilidad arriba\npara empezar a recibir solicitudes',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viajesActivos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: ViajeActivoCard(viaje: viajesActivos[index]),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ==================== FIN NUEVO DISEÃ‘O ====================

  Widget _buildBottomNav() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withOpacity(0.98)
                : Colors.white.withOpacity(0.98),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Inicio'),
                  _buildNavItem(1, Icons.directions_car_rounded, 'Viajes'),
                  _buildNavItem(2, Icons.payments_rounded, 'Ganancias'),
                  _buildNavItem(3, Icons.person_rounded, 'Perfil'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final isSelected = _selectedIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              // Haptic feedback suave
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    tween: Tween(begin: 1.0, end: isSelected ? 1.1 : 1.0),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          icon,
                          color: isSelected
                              ? AppColors.primary
                              : theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.4,
                                ),
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                      fontSize: isSelected ? 12 : 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
