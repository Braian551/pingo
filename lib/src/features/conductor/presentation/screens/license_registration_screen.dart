import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/driver_license_model.dart';
import '../../providers/conductor_profile_provider.dart';
import 'vehicle_only_registration_screen.dart';

class LicenseRegistrationScreen extends StatefulWidget {
  final int conductorId;
  final DriverLicenseModel? existingLicense;

  const LicenseRegistrationScreen({
    super.key,
    required this.conductorId,
    this.existingLicense,
  });

  @override
  State<LicenseRegistrationScreen> createState() => _LicenseRegistrationScreenState();
}

class _LicenseRegistrationScreenState extends State<LicenseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  DateTime? _licenseExpedicion;
  DateTime? _licenseVencimiento;
  LicenseCategory _selectedCategory = LicenseCategory.c1;
  String? _licenceFotoPath;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingLicense != null) {
      final license = widget.existingLicense!;
      _licenseNumberController.text = license.numero;
      _licenseExpedicion = license.fechaExpedicion;
      _licenseVencimiento = license.fechaVencimiento;
      _selectedCategory = license.categoria;
    }
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLicense != null;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isEditing),
      body: Consumer<ConductorProfileProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(isEditing),
                    const SizedBox(height: 32),
                    _buildLicenseForm(),
                    const SizedBox(height: 32),
                    _buildSaveButton(provider, isEditing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEditing) {
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
      title: Text(
        isEditing ? 'Editar Licencia' : 'Registrar Licencia',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFFF00).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFF00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: Color(0xFFFFFF00),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Actualizar Información' : 'Licencia de Conducción',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing ? 'Modifica los datos de tu licencia' : 'Ingresa los datos de tu licencia',
                      style: const TextStyle(
                        color: Colors.white70,
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
  }

  Widget _buildLicenseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _licenseNumberController,
          label: 'Número de Licencia',
          hint: 'Ej: 12345678',
          icon: Icons.numbers_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el número de licencia';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Fecha de Expedición',
          selectedDate: _licenseExpedicion,
          onTap: () => _selectDate(context, isExpedicion: true),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Fecha de Vencimiento',
          selectedDate: _licenseVencimiento,
          onTap: () => _selectDate(context, isExpedicion: false),
        ),
        const SizedBox(height: 16),
        _buildPhotoUpload(
          label: 'Foto de la Licencia',
          photoPath: _licenceFotoPath,
          onTap: () => _pickImage(),
        ),
        if (_licenseVencimiento != null && _licenseVencimiento!.isBefore(DateTime.now()))
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tu licencia está vencida. Debes renovarla para poder recibir viajes.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: const Color(0xFFFFFF00)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<LicenseCategory>(
            value: _selectedCategory,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Categor�a de Licencia',
              labelStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.category_rounded, color: Color(0xFFFFFF00)),
            ),
            isExpanded: true,
            items: LicenseCategory.values
                .where((cat) => cat != LicenseCategory.ninguna)
                .map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  '${ category.label} - ${category.description}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFFFFFF00)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedDate != null
                            ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: selectedDate != null ? Colors.white : Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(ConductorProfileProvider provider, bool isEditing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _handleSave(provider, isEditing),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFFFFFF00),
          disabledBackgroundColor: Colors.grey,
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
            : Text(
                isEditing ? 'Actualizar Licencia' : 'Guardar Licencia',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Widget para seleccionar/mostrar foto de licencia
  Widget _buildPhotoUpload({
    required String label,
    required String? photoPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: photoPath != null 
                    ? const Color(0xFFFFFF00).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: photoPath != null
                        ? const Color(0xFFFFFF00).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photoPath != null ? 'Foto seleccionada' : 'Toca para seleccionar',
                        style: TextStyle(
                          color: photoPath != null 
                              ? const Color(0xFFFFFF00)
                              : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  photoPath != null ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                  color: photoPath != null
                      ? const Color(0xFFFFFF00)
                      : Colors.white.withOpacity(0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Seleccionar imagen de la galería o cámara
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Seleccionar foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFF00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFFFF00)),
                  ),
                  title: const Text(
                    'Tomar foto',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFF00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFFFFFF00)),
                  ),
                  title: const Text(
                    'Seleccionar de galería',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _licenceFotoPath = image.path;
          });
        }
      } catch (e) {
        print('Error al seleccionar imagen: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al seleccionar imagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isExpedicion}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpedicion
          ? (_licenseExpedicion ?? DateTime.now().subtract(const Duration(days: 365 * 5)))
          : (_licenseVencimiento ?? DateTime.now().add(const Duration(days: 365 * 5))),
      firstDate: isExpedicion ? DateTime(1950) : DateTime.now(),
      lastDate: isExpedicion ? DateTime.now() : DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFFF00),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpedicion) {
          _licenseExpedicion = picked;
        } else {
          _licenseVencimiento = picked;
        }
      });
    }
  }

  Future<void> _handleSave(ConductorProfileProvider provider, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    if (_licenseExpedicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de expedición'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_licenseVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de vencimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Primero subir la foto si existe
    if (_licenceFotoPath != null) {
      final uploadResult = await provider.uploadLicensePhoto(
        conductorId: widget.conductorId,
        licenciaFotoPath: _licenceFotoPath!,
      );

      if (uploadResult == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advertencia: No se pudo subir la foto de la licencia'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final license = DriverLicenseModel(
      numero: _licenseNumberController.text,
      fechaExpedicion: _licenseExpedicion!,
      fechaVencimiento: _licenseVencimiento!,
      categoria: _selectedCategory,
    );

    final success = await provider.updateLicense(
      conductorId: widget.conductorId,
      license: license,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Licencia actualizada exitosamente' : 'Licencia guardada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Si es registro nuevo (no edición), verificar si falta el vehículo
        if (!isEditing && provider.profile != null) {
          final hasVehicle = provider.profile!.vehiculo != null && 
                             provider.profile!.vehiculo!.isBasicComplete;
          
          if (!hasVehicle) {
            // Mostrar diálogo para ir a registrar vehículo
            final goToVehicle = await showDialog<bool>(
              context: context,
              builder: (context) => _buildNavigationDialog(
                icon: Icons.directions_car_rounded,
                title: 'Registrar Vehículo',
                message: '¡Licencia guardada! ¿Deseas continuar registrando tu vehículo ahora?',
              ),
            );

            if (goToVehicle == true && mounted) {
              // Ir a la pantalla de registro de vehículo
              final vehicleResult = await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleOnlyRegistrationScreen(
                    conductorId: widget.conductorId,
                  ),
                ),
              );
              // Si guardó el vehículo, retornar true
              if (vehicleResult == true) {
                return;
              }
            }
          }
        }
        
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Error al guardar licencia',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNavigationDialog({
    required IconData icon,
    required String title,
    required String message,
  }) {
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
                    color: const Color(0xFFFFFF00).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFFFFF00),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Después',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFFFFF00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
