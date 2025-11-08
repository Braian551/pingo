import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/conductor_profile_provider.dart';
import '../../models/conductor_profile_model.dart';
import 'license_registration_screen.dart';
import 'vehicle_only_registration_screen.dart';
import 'verification_status_screen.dart';
import 'package:viax/src/global/services/auth/user_service.dart';

class ConductorProfileScreen extends StatefulWidget {
  final int conductorId;
  final bool showBackButton;

  const ConductorProfileScreen({
    super.key,
    required this.conductorId,
    this.showBackButton = true,
  });

  @override
  State<ConductorProfileScreen> createState() => _ConductorProfileScreenState();
}

class _ConductorProfileScreenState extends State<ConductorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConductorProfileProvider>(
        context,
        listen: false,
      ).loadProfile(widget.conductorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Consumer<ConductorProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildShimmerLoading();
          }

          final profile = provider.profile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar el perfil',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadProfile(widget.conductorId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFF00),
                    ),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }

          // Si el conductor estÃ¡ aprobado, mostrar vista de perfil aprobado
          if (profile.aprobado &&
              profile.estadoVerificacion == VerificationStatus.aprobado) {
            return _buildApprovedProfileView(profile);
          }

          // Si no estÃ¡ aprobado, mostrar vista de verificaciÃ³n
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildCompletionProgress(profile),
                  const SizedBox(height: 32),
                  _buildVerificationStatus(profile),
                  const SizedBox(height: 24),
                  _buildLicenseSection(profile),
                  const SizedBox(height: 24),
                  _buildVehicleSection(profile),
                  const SizedBox(height: 24),
                  _buildPendingTasks(profile),
                  const SizedBox(height: 24),
                  if (profile.isProfileComplete &&
                      !profile.aprobado &&
                      profile.estadoVerificacion !=
                          VerificationStatus.enRevision)
                    _buildSubmitButton(provider, profile),
                  const SizedBox(height: 24),
                  if (profile.estadoVerificacion ==
                      VerificationStatus.enRevision)
                    _buildInReviewMessage(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
          ),
        ),
      ),
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: widget.showBackButton,
      title: const Text(
        'Mi Perfil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompletionProgress(ConductorProfileModel profile) {
    final percentage = profile.completionPercentage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFFF00).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Completitud del Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFFF00),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.isProfileComplete
                    ? 'Â¡Perfil completo!'
                    : 'Completa tu perfil para recibir viajes',
                style: TextStyle(
                  color: profile.isProfileComplete
                      ? Colors.green
                      : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus(ConductorProfileModel profile) {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (profile.estadoVerificacion) {
      case VerificationStatus.pendiente:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        statusMessage = 'Pendiente de verificaciÃ³n';
        break;
      case VerificationStatus.enRevision:
        statusColor = Colors.blue;
        statusIcon = Icons.search_rounded;
        statusMessage = 'En revisiÃ³n por el equipo';
        break;
      case VerificationStatus.aprobado:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusMessage = 'Â¡Perfil aprobado!';
        break;
      case VerificationStatus.rechazado:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusMessage = 'Documentos rechazados';
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationStatusScreen(conductorId: widget.conductorId),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.estadoVerificacion.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseSection(ConductorProfileModel profile) {
    final license = profile.licencia;
    final hasLicense = license != null && license.isComplete;

    return _buildSection(
      title: 'Licencia de ConducciÃ³n',
      icon: Icons.badge_rounded,
      isComplete: hasLicense,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LicenseRegistrationScreen(
              conductorId: widget.conductorId,
              existingLicense: license,
            ),
          ),
        );
        if (result == true && mounted) {
          Provider.of<ConductorProfileProvider>(
            context,
            listen: false,
          ).loadProfile(widget.conductorId);
        }
      },
      child: hasLicense
          ? Column(
              children: [
                _buildDetailRow('NÃºmero', license.numero),
                _buildDetailRow('CategorÃ­a', license.categoria.label),
                _buildDetailRow(
                  'Vencimiento',
                  '${license.fechaVencimiento.day}/${license.fechaVencimiento.month}/${license.fechaVencimiento.year}',
                ),
                if (!license.isValid)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Licencia vencida - Renovar urgente',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No has registrado tu licencia',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
    );
  }

  Widget _buildVehicleSection(ConductorProfileModel profile) {
    final vehicle = profile.vehiculo;
    final hasVehicle = vehicle != null && vehicle.isBasicComplete;

    return _buildSection(
      title: 'InformaciÃ³n del VehÃ­culo',
      icon: Icons.directions_car_rounded,
      isComplete: hasVehicle,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleOnlyRegistrationScreen(
              conductorId: widget.conductorId,
              existingVehicle: vehicle,
            ),
          ),
        );
        if (result == true && mounted) {
          Provider.of<ConductorProfileProvider>(
            context,
            listen: false,
          ).loadProfile(widget.conductorId);
        }
      },
      child: hasVehicle
          ? Column(
              children: [
                _buildDetailRow('Placa', vehicle.placa.toUpperCase()),
                _buildDetailRow('Tipo', vehicle.tipo.label),
                _buildDetailRow('Marca', vehicle.marca ?? 'N/A'),
                _buildDetailRow('Modelo', vehicle.modelo ?? 'N/A'),
                _buildDetailRow('AÃ±o', vehicle.anio?.toString() ?? 'N/A'),
                _buildDetailRow('Color', vehicle.color ?? 'N/A'),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No has registrado tu vehÃ­culo',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
    );
  }

  Widget _buildPendingTasks(ConductorProfileModel profile) {
    final tasks = profile.pendingTasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tareas Pendientes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tasks.map((task) => _buildTaskItem(task)),
      ],
    );
  }

  Widget _buildTaskItem(String task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFFF00), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFFFFF00),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isComplete,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isComplete
                  ? Colors.green.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (isComplete
                                      ? Colors.green
                                      : const Color(0xFFFFFF00))
                                  .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isComplete
                              ? Colors.green
                              : const Color(0xFFFFFF00),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isComplete)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 24,
                        )
                      else
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFFFFFF00),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    ConductorProfileProvider provider,
    ConductorProfileModel profile,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () async {
                final result = await provider.submitForVerification(
                  widget.conductorId,
                );
                if (mounted) {
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Â¡Perfil enviado para verificaciÃ³n exitosamente!',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    // Recargar perfil para actualizar estado
                    await provider.loadProfile(widget.conductorId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? 'Error al enviar perfil',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFFFFFF00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: provider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Enviar para VerificaciÃ³n',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInReviewMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.blue,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'VerificaciÃ³n en RevisiÃ³n',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tu perfil ha sido enviado y estÃ¡ siendo revisado por nuestro equipo. Te notificaremos cuando el proceso haya finalizado.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFFF00),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tiempo estimado: 24-48 horas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Completion progress shimmer
            _buildShimmerBox(height: 120, width: double.infinity),
            const SizedBox(height: 32),
            // Verification status shimmer
            _buildShimmerBox(height: 90, width: double.infinity),
            const SizedBox(height: 24),
            // License section shimmer
            _buildShimmerBox(height: 200, width: double.infinity),
            const SizedBox(height: 24),
            // Vehicle section shimmer
            _buildShimmerBox(height: 250, width: double.infinity),
            const SizedBox(height: 24),
            // Pending tasks title shimmer
            _buildShimmerBox(height: 24, width: 180),
            const SizedBox(height: 16),
            // Pending task items shimmer
            _buildShimmerBox(height: 60, width: double.infinity),
            const SizedBox(height: 12),
            _buildShimmerBox(height: 60, width: double.infinity),
            const SizedBox(height: 12),
            _buildShimmerBox(height: 60, width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ========== VISTA DE PERFIL APROBADO ==========

  Widget _buildApprovedProfileView(ConductorProfileModel profile) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildApprovedBadge(),
            const SizedBox(height: 24),
            _buildApprovedPersonalInfoSection(profile),
            const SizedBox(height: 24),
            _buildApprovedLicenseSection(profile),
            const SizedBox(height: 24),
            _buildApprovedVehicleSection(profile),
            const SizedBox(height: 24),
            _buildApprovedDocumentsSection(profile),
            const SizedBox(height: 24),
            _buildApprovedSettingsSection(),
            const SizedBox(height: 24),
            _buildApprovedAccountSection(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Â¡Conductor Verificado!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu perfil ha sido aprobado y verificado',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedPersonalInfoSection(ConductorProfileModel profile) {
    return _buildApprovedSection(
      title: 'InformaciÃ³n Personal',
      icon: Icons.person_rounded,
      children: [
        _buildApprovedInfoTile(
          icon: Icons.badge_rounded,
          label: 'Estado',
          value: 'Conductor Activo',
          valueColor: Colors.green,
        ),
        const Divider(color: Colors.white12),
        _buildApprovedInfoTile(
          icon: Icons.calendar_today_rounded,
          label: 'Verificado desde',
          value: _formatDate(profile.fechaUltimaVerificacion),
        ),
        const Divider(color: Colors.white12),
        _buildApprovedInfoTile(
          icon: Icons.security_rounded,
          label: 'Estado de Documentos',
          value: 'Todos verificados',
          valueColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildApprovedLicenseSection(ConductorProfileModel profile) {
    final license = profile.licencia;
    final hasLicense = license != null && license.isComplete;

    return _buildApprovedSection(
      title: 'Licencia de ConducciÃ³n',
      icon: Icons.credit_card_rounded,
      trailing: hasLicense
          ? IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFFFFFF00)),
              onPressed: () => _editLicense(license),
            )
          : null,
      children: hasLicense
          ? [
              _buildApprovedInfoTile(
                icon: Icons.numbers_rounded,
                label: 'NÃºmero',
                value: license.numero,
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.category_rounded,
                label: 'CategorÃ­a',
                value: license.categoria.label,
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.event_rounded,
                label: 'Fecha de Vencimiento',
                value:
                    '${license.fechaVencimiento.day}/${license.fechaVencimiento.month}/${license.fechaVencimiento.year}',
                valueColor: license.isValid
                    ? (license.isExpiringSoon ? Colors.orange : Colors.white)
                    : Colors.red,
              ),
              if (license.isExpiringSoon || !license.isValid) ...[
                const Divider(color: Colors.white12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (license.isValid ? Colors.orange : Colors.red)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: license.isValid ? Colors.orange : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          license.isValid
                              ? 'Tu licencia vence pronto. Considera renovarla.'
                              : 'Tu licencia estÃ¡ vencida. RenuÃ©vala urgentemente.',
                          style: TextStyle(
                            color: license.isValid ? Colors.orange : Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]
          : [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No has registrado tu licencia',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
    );
  }

  Widget _buildApprovedVehicleSection(ConductorProfileModel profile) {
    final vehicle = profile.vehiculo;
    final hasVehicle = vehicle != null && vehicle.isBasicComplete;

    return _buildApprovedSection(
      title: 'InformaciÃ³n del VehÃ­culo',
      icon: Icons.directions_car_rounded,
      trailing: hasVehicle
          ? IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFFFFFF00)),
              onPressed: () => _editVehicle(vehicle),
            )
          : null,
      children: hasVehicle
          ? [
              _buildApprovedInfoTile(
                icon: Icons.pin_rounded,
                label: 'Placa',
                value: vehicle.placa.toUpperCase(),
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.car_rental_rounded,
                label: 'Tipo',
                value: vehicle.tipo.label,
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.business_rounded,
                label: 'Marca',
                value: vehicle.marca ?? 'N/A',
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.inventory_rounded,
                label: 'Modelo',
                value: vehicle.modelo ?? 'N/A',
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.calendar_today_rounded,
                label: 'AÃ±o',
                value: vehicle.anio?.toString() ?? 'N/A',
              ),
              const Divider(color: Colors.white12),
              _buildApprovedInfoTile(
                icon: Icons.palette_rounded,
                label: 'Color',
                value: vehicle.color ?? 'N/A',
              ),
            ]
          : [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No has registrado tu vehÃ­culo',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
    );
  }

  Widget _buildApprovedDocumentsSection(ConductorProfileModel profile) {
    return _buildApprovedSection(
      title: 'Documentos',
      icon: Icons.folder_rounded,
      children: [
        _buildDocumentItem(
          'Licencia de ConducciÃ³n',
          Icons.badge_rounded,
          verified: profile.licencia != null,
        ),
        const Divider(color: Colors.white12),
        _buildDocumentItem(
          'SOAT',
          Icons.description_rounded,
          verified: profile.vehiculo?.fotoSoat != null,
        ),
        const Divider(color: Colors.white12),
        _buildDocumentItem(
          'Tarjeta de Propiedad',
          Icons.description_rounded,
          verified: profile.vehiculo?.fotoTarjetaPropiedad != null,
        ),
        const Divider(color: Colors.white12),
        _buildDocumentItem(
          'TecnomecÃ¡nica',
          Icons.build_rounded,
          verified: profile.vehiculo?.fotoTecnomecanica != null,
        ),
      ],
    );
  }

  Widget _buildDocumentItem(
    String title,
    IconData icon, {
    required bool verified,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (verified ? Colors.green : Colors.orange).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: verified ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            verified ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: verified ? Colors.green : Colors.orange,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedSettingsSection() {
    return _buildApprovedSection(
      title: 'ConfiguraciÃ³n',
      icon: Icons.settings_rounded,
      children: [
        _buildSettingItem(
          'Notificaciones',
          Icons.notifications_rounded,
          onTap: () => _showComingSoon('Notificaciones'),
        ),
        const Divider(color: Colors.white12),
        _buildSettingItem(
          'Privacidad',
          Icons.privacy_tip_rounded,
          onTap: () => _showComingSoon('Privacidad'),
        ),
        const Divider(color: Colors.white12),
        _buildSettingItem(
          'Idioma',
          Icons.language_rounded,
          trailing: 'EspaÃ±ol',
          onTap: () => _showComingSoon('Idioma'),
        ),
        const Divider(color: Colors.white12),
        _buildSettingItem(
          'Modo Oscuro',
          Icons.dark_mode_rounded,
          trailing: 'Activado',
          onTap: () => _showComingSoon('Modo Oscuro'),
        ),
      ],
    );
  }

  Widget _buildApprovedAccountSection() {
    return _buildApprovedSection(
      title: 'Cuenta',
      icon: Icons.account_circle_rounded,
      children: [
        _buildSettingItem(
          'Ayuda y Soporte',
          Icons.help_rounded,
          onTap: () => _showComingSoon('Ayuda y Soporte'),
        ),
        const Divider(color: Colors.white12),
        _buildSettingItem(
          'TÃ©rminos y Condiciones',
          Icons.article_rounded,
          onTap: () => _showComingSoon('TÃ©rminos y Condiciones'),
        ),
      ],
    );
  }

  Widget _buildApprovedSection({
    required String title,
    required IconData icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFF00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFFFFF00),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon, {
    String? trailing,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editLicense(license) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LicenseRegistrationScreen(
          conductorId: widget.conductorId,
          existingLicense: license,
        ),
      ),
    );
    if (result == true && mounted) {
      Provider.of<ConductorProfileProvider>(
        context,
        listen: false,
      ).loadProfile(widget.conductorId);
    }
  }

  void _editVehicle(vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleOnlyRegistrationScreen(
          conductorId: widget.conductorId,
          existingVehicle: vehicle,
        ),
      ),
    );
    if (result == true && mounted) {
      Provider.of<ConductorProfileProvider>(
        context,
        listen: false,
      ).loadProfile(widget.conductorId);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estarÃ¡ disponible prÃ³ximamente'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => _buildLogoutDialog(),
        );

        if (shouldLogout == true && mounted) {
          await UserService.clearSession();

          if (!mounted) return;

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/welcome', (route) => false);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFf5576c).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFf5576c).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFf5576c), size: 24),
                SizedBox(width: 12),
                Text(
                  'Cerrar sesiÃ³n',
                  style: TextStyle(
                    color: Color(0xFFf5576c),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf5576c).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFf5576c),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Â¿Cerrar sesiÃ³n?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Â¿EstÃ¡s seguro de que deseas cerrar sesiÃ³n?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFf5576c),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cerrar sesiÃ³n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
