import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vehicle_model.dart';
import '../../providers/conductor_profile_provider.dart';
import 'license_registration_screen.dart';

class VehicleOnlyRegistrationScreen extends StatefulWidget {
  final int conductorId;
  final VehicleModel? existingVehicle;

  const VehicleOnlyRegistrationScreen({
    super.key,
    required this.conductorId,
    this.existingVehicle,
  });

  @override
  State<VehicleOnlyRegistrationScreen> createState() => _VehicleOnlyRegistrationScreenState();
}

class _VehicleOnlyRegistrationScreenState extends State<VehicleOnlyRegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Vehicle data
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  VehicleType _selectedType = VehicleType.motocicleta;

  // Document data
  final _soatNumberController = TextEditingController();
  DateTime? _soatVencimiento;
  final _tecnomecanicaNumberController = TextEditingController();
  DateTime? _tecnomecanicaVencimiento;
  final _tarjetaPropiedadController = TextEditingController();

  // Photos
  String? _soatFotoPath;
  String? _tecnomecanicaFotoPath;
  String? _tarjetaPropiedadFotoPath;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingVehicle != null) {
      final vehicle = widget.existingVehicle!;
      _placaController.text = vehicle.placa;
      _selectedType = vehicle.tipo;
      _marcaController.text = vehicle.marca ?? '';
      _modeloController.text = vehicle.modelo ?? '';
      _anioController.text = vehicle.anio?.toString() ?? '';
      _colorController.text = vehicle.color ?? '';
      _soatNumberController.text = vehicle.soatNumero ?? '';
      _soatVencimiento = vehicle.soatVencimiento;
      _tecnomecanicaNumberController.text = vehicle.tecnomecanicaNumero ?? '';
      _tecnomecanicaVencimiento = vehicle.tecnomecanicaVencimiento;
      _tarjetaPropiedadController.text = vehicle.tarjetaPropiedadNumero ?? '';
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    _soatNumberController.dispose();
    _tecnomecanicaNumberController.dispose();
    _tarjetaPropiedadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVehicle != null;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isEditing),
      body: Consumer<ConductorProfileProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
                _buildNavigationButtons(provider),
              ],
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isEditing ? 'Editar Vehículo' : 'Registrar Vehículo',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Vehículo'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Documentos'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFFFFFF00)
                  : isActive
                      ? const Color(0xFFFFFF00).withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive || isCompleted 
                    ? const Color(0xFFFFFF00) 
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.black, size: 20)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? const Color(0xFFFFFF00) : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      flex: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: step < _currentStep
            ? const Color(0xFFFFFF00)
            : Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildVehicleStep();
      case 1:
        return _buildDocumentsStep();
      default:
        return Container();
    }
  }

  Widget _buildVehicleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Información del Vehículo',
          Icons.directions_car_rounded,
        ),
        const SizedBox(height: 24),
        _buildVehicleTypeSelector(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _placaController,
          label: 'Placa',
          hint: 'Ej: ABC123',
          icon: Icons.pin_rounded,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la placa';
            }
            if (value.length < 6) {
              return 'La placa debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _marcaController,
                label: 'Marca',
                hint: 'Ej: Toyota',
                icon: Icons.branding_watermark_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _modeloController,
                label: 'Modelo',
                hint: 'Ej: Corolla',
                icon: Icons.description_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _anioController,
                label: 'Año',
                hint: '2020',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                    return 'Año inválido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _colorController,
                label: 'Color',
                hint: 'Ej: Blanco',
                icon: Icons.palette_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Documentos del Vehículo',
          Icons.description_rounded,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _soatNumberController,
          label: 'Número SOAT',
          hint: 'Número de póliza SOAT',
          icon: Icons.shield_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el número SOAT';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Vencimiento SOAT',
          selectedDate: _soatVencimiento,
          onTap: () => _selectSOATDate(context),
        ),
        const SizedBox(height: 16),
        _buildPhotoUpload(
          label: 'Foto del SOAT',
          photoPath: _soatFotoPath,
          onTap: () => _pickImage('soat'),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _tecnomecanicaNumberController,
          label: 'Número Tecnomecánica',
          hint: 'Número de certificado',
          icon: Icons.build_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el número de tecnomecánica';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Vencimiento Tecnomecánica',
          selectedDate: _tecnomecanicaVencimiento,
          onTap: () => _selectTecnomecanicaDate(context),
        ),
        const SizedBox(height: 16),
        _buildPhotoUpload(
          label: 'Foto de la Tecnomecánica',
          photoPath: _tecnomecanicaFotoPath,
          onTap: () => _pickImage('tecnomecanica'),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _tarjetaPropiedadController,
          label: 'Tarjeta de Propiedad',
          hint: 'Número de tarjeta',
          icon: Icons.credit_card_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el número de tarjeta de propiedad';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPhotoUpload(
          label: 'Foto de la Tarjeta de Propiedad',
          photoPath: _tarjetaPropiedadFotoPath,
          onTap: () => _pickImage('tarjeta_propiedad'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFFF00), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
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

  Widget _buildVehicleTypeSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              const Text(
                'Tipo de Vehículo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: VehicleType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFFF00).withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFFF00).withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 20,
                            color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.label,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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

  Widget _buildNavigationButtons(ConductorProfileProvider provider) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Atrás',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : () => _handleNext(provider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFFFFF00),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            _currentStep < 1 ? 'Siguiente' : 'Guardar',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para seleccionar/mostrar foto
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
  Future<void> _pickImage(String documentType) async {
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
                  subtitle: Text(
                    'Usar cámara',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
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
                  subtitle: Text(
                    'Elegir foto existente',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
            switch (documentType) {
              case 'soat':
                _soatFotoPath = image.path;
                break;
              case 'tecnomecanica':
                _tecnomecanicaFotoPath = image.path;
                break;
              case 'tarjeta_propiedad':
                _tarjetaPropiedadFotoPath = image.path;
                break;
            }
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

  Future<void> _selectSOATDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _soatVencimiento ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() => _soatVencimiento = picked);
    }
  }

  Future<void> _selectTecnomecanicaDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tecnomecanicaVencimiento ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() => _tecnomecanicaVencimiento = picked);
    }
  }

  Future<void> _handleNext(ConductorProfileProvider provider) async {
    if (_currentStep < 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
      }
    } else {
      // Save all vehicle data
      await _saveData(provider);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _soatNumberController.text.isNotEmpty &&
            _soatVencimiento != null &&
            _tecnomecanicaNumberController.text.isNotEmpty &&
            _tecnomecanicaVencimiento != null &&
            _tarjetaPropiedadController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _saveData(ConductorProfileProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    if (_soatVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de vencimiento del SOAT'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tecnomecanicaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha de vencimiento de la tecnomecánica'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Primero subir las fotos si existen
    if (_soatFotoPath != null || _tecnomecanicaFotoPath != null || _tarjetaPropiedadFotoPath != null) {
      final uploadResults = await provider.uploadVehicleDocuments(
        conductorId: widget.conductorId,
        soatFotoPath: _soatFotoPath,
        tecnomecanicaFotoPath: _tecnomecanicaFotoPath,
        tarjetaPropiedadFotoPath: _tarjetaPropiedadFotoPath,
      );

      // Verificar si algún upload falló
      final failedUploads = uploadResults.entries.where((e) => e.value == null).toList();
      if (failedUploads.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Advertencia: No se pudieron subir algunas fotos: ${failedUploads.map((e) => e.key).join(", ")}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final vehicle = VehicleModel(
      placa: _placaController.text,
      tipo: _selectedType,
      marca: _marcaController.text,
      modelo: _modeloController.text,
      anio: int.parse(_anioController.text),
      color: _colorController.text,
      soatNumero: _soatNumberController.text,
      soatVencimiento: _soatVencimiento,
      tecnomecanicaNumero: _tecnomecanicaNumberController.text,
      tecnomecanicaVencimiento: _tecnomecanicaVencimiento,
      tarjetaPropiedadNumero: _tarjetaPropiedadController.text,
    );

    final vehicleSuccess = await provider.updateVehicle(
      conductorId: widget.conductorId,
      vehicle: vehicle,
    );

    if (mounted) {
      if (vehicleSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingVehicle != null 
                  ? 'Vehículo actualizado exitosamente' 
                  : 'Vehículo guardado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Si es registro nuevo (no edición), verificar si falta la licencia
        final isEditing = widget.existingVehicle != null;
        if (!isEditing && provider.profile != null) {
          final hasLicense = provider.profile!.licencia != null && 
                             provider.profile!.licencia!.isComplete;
          
          if (!hasLicense) {
            // Mostrar diálogo para ir a registrar licencia
            final goToLicense = await showDialog<bool>(
              context: context,
              builder: (context) => _buildNavigationDialog(
                icon: Icons.badge_rounded,
                title: 'Registrar Licencia',
                message: '¡Vehículo guardado! ¿Deseas continuar registrando tu licencia de conducción ahora?',
              ),
            );

            if (goToLicense == true && mounted) {
              // Ir a la pantalla de registro de licencia
              final licenseResult = await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LicenseRegistrationScreen(
                    conductorId: widget.conductorId,
                  ),
                ),
              );
              // Si guardó la licencia, retornar true
              if (licenseResult == true) {
                return;
              }
            }
          }
        }
        
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al guardar vehículo'),
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
