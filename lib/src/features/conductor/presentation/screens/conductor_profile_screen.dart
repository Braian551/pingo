import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/conductor_profile_provider.dart';
import '../../models/conductor_profile_model.dart';
import 'vehicle_registration_screen.dart';
import 'verification_status_screen.dart';

class ConductorProfileScreen extends StatefulWidget {
  final int conductorId;

  const ConductorProfileScreen({
    super.key,
    required this.conductorId,
  });

  @override
  State<ConductorProfileScreen> createState() => _ConductorProfileScreenState();
}

class _ConductorProfileScreenState extends State<ConductorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConductorProfileProvider>(context, listen: false)
          .loadProfile(widget.conductorId);
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
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFFF00),
              ),
            );
          }

          final profile = provider.profile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar el perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
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
                  if (profile.isProfileComplete && !profile.aprobado)
                    _buildSubmitButton(provider),
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
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
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
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFFF00).withOpacity(0.2),
                const Color(0xFFFFFF00).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                    ? '¡Perfil completo! 🎉'
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
        statusMessage = 'Pendiente de verificación';
        break;
      case VerificationStatus.enRevision:
        statusColor = Colors.blue;
        statusIcon = Icons.search_rounded;
        statusMessage = 'En revisión por el equipo';
        break;
      case VerificationStatus.aprobado:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusMessage = '¡Perfil aprobado!';
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
            builder: (context) => VerificationStatusScreen(
              conductorId: widget.conductorId,
            ),
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
      title: 'Licencia de Conducción',
      icon: Icons.badge_rounded,
      isComplete: hasLicense,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleRegistrationScreen(
              conductorId: widget.conductorId,
            ),
          ),
        );
        if (result == true && mounted) {
          Provider.of<ConductorProfileProvider>(context, listen: false)
              .loadProfile(widget.conductorId);
        }
      },
      child: hasLicense
          ? Column(
              children: [
                _buildDetailRow('Número', license.numero),
                _buildDetailRow('Categoría', license.categoria.label),
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
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleSection(ConductorProfileModel profile) {
    final vehicle = profile.vehiculo;
    final hasVehicle = vehicle != null && vehicle.isBasicComplete;

    return _buildSection(
      title: 'Información del Vehículo',
      icon: Icons.directions_car_rounded,
      isComplete: hasVehicle,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleRegistrationScreen(
              conductorId: widget.conductorId,
            ),
          ),
        );
        if (result == true && mounted) {
          Provider.of<ConductorProfileProvider>(context, listen: false)
              .loadProfile(widget.conductorId);
        }
      },
      child: hasVehicle
          ? Column(
              children: [
                _buildDetailRow('Placa', vehicle.placa.toUpperCase()),
                _buildDetailRow('Tipo', '${vehicle.tipo.emoji} ${vehicle.tipo.label}'),
                _buildDetailRow('Marca', vehicle.marca ?? 'N/A'),
                _buildDetailRow('Modelo', vehicle.modelo ?? 'N/A'),
                _buildDetailRow('Año', vehicle.anio?.toString() ?? 'N/A'),
                _buildDetailRow('Color', vehicle.color ?? 'N/A'),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No has registrado tu vehículo',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFFFF00),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
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
                          color: (isComplete ? Colors.green : const Color(0xFFFFFF00))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isComplete ? Colors.green : const Color(0xFFFFFF00),
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
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
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

  Widget _buildSubmitButton(ConductorProfileProvider provider) {
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
                          '¡Perfil enviado para verificación!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                'Enviar para Verificación',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
