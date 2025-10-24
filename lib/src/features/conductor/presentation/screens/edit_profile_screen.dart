import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/vehicle_model.dart';
import '../../providers/conductor_profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final int conductorId;

  const EditProfileScreen({
    super.key,
    required this.conductorId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Vehicle data
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  VehicleType _selectedType = VehicleType.motocicleta;

  // License data
  final _licenseNumberController = TextEditingController();
  DateTime? _licenseVencimiento;

  // Insurance data
  final _aseguradoraController = TextEditingController();
  final _numeroPolizaController = TextEditingController();
  DateTime? _seguroVencimiento;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = Provider.of<ConductorProfileProvider>(context, listen: false);
    await provider.loadProfile(widget.conductorId);
    
    final profile = provider.profile;
    if (profile != null) {
      // Load vehicle data
      if (profile.vehiculo != null) {
        _placaController.text = profile.vehiculo!.placa;
        _marcaController.text = profile.vehiculo!.marca ?? '';
        _modeloController.text = profile.vehiculo!.modelo ?? '';
        _anioController.text = profile.vehiculo!.anio?.toString() ?? '';
        _colorController.text = profile.vehiculo!.color ?? '';
        _selectedType = profile.vehiculo!.tipo;
        _aseguradoraController.text = profile.vehiculo!.aseguradora ?? '';
        _numeroPolizaController.text = profile.vehiculo!.numeroPoliza ?? '';
        if (profile.vehiculo!.vencimientoSeguro != null) {
          _seguroVencimiento = profile.vehiculo!.vencimientoSeguro;
        }
      }
      
      // Load license data
      if (profile.licencia != null) {
        _licenseNumberController.text = profile.licencia!.numero;
        _licenseVencimiento = profile.licencia!.fechaVencimiento;
      }
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    _licenseNumberController.dispose();
    _aseguradoraController.dispose();
    _numeroPolizaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFFF00),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionTitle('Información Personal', Icons.person),
                      const SizedBox(height: 16),
                      _buildInfoMessage(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Licencia de Conducción', Icons.badge),
                      const SizedBox(height: 16),
                      _buildLicenseSection(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Información del Vehículo', Icons.directions_car),
                      const SizedBox(height: 16),
                      _buildVehicleSection(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Seguro del Vehículo', Icons.shield),
                      const SizedBox(height: 16),
                      _buildInsuranceSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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
        'Completar Perfil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFFF00), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFF00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFFF00).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFFFF00),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Completa todos los campos para poder activar tu disponibilidad y recibir viajes.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _licenseNumberController,
          label: 'Número de Licencia',
          hint: 'Ej: 12345678',
          icon: Icons.numbers,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Fecha de Vencimiento',
          date: _licenseVencimiento,
          icon: Icons.calendar_today,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _licenseVencimiento ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
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
                _licenseVencimiento = picked;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _placaController,
          label: 'Placa del Vehículo',
          hint: 'Ej: ABC123',
          icon: Icons.pin,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _marcaController,
          label: 'Marca',
          hint: 'Ej: Yamaha',
          icon: Icons.branding_watermark,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _modeloController,
          label: 'Modelo',
          hint: 'Ej: FZ-16',
          icon: Icons.motorcycle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _anioController,
                label: 'Año',
                hint: 'Ej: 2023',
                icon: Icons.calendar_month,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Obligatorio';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1990 || year > DateTime.now().year + 1) {
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
                hint: 'Ej: Rojo',
                icon: Icons.palette,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _aseguradoraController,
          label: 'Aseguradora',
          hint: 'Ej: SURA',
          icon: Icons.business,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _numeroPolizaController,
          label: 'Número de Póliza',
          hint: 'Ej: 123456789',
          icon: Icons.numbers,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Vencimiento del Seguro',
          date: _seguroVencimiento,
          icon: Icons.calendar_today,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _seguroVencimiento ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
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
                _seguroVencimiento = picked;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Vehículo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VehicleType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFFF00)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFFF00)
                              : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 20,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.label,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: const Color(0xFFFFFF00)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
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
                Icon(icon, color: const Color(0xFFFFFF00)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: date != null ? Colors.white : Colors.white.withOpacity(0.3),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFFF00),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFFFFFF00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Guardar y Continuar',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_licenseVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar la fecha de vencimiento de la licencia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ConductorProfileProvider>(context, listen: false);
      
      final data = {
        'conductor_id': widget.conductorId,
        'licencia_conduccion': _licenseNumberController.text.trim(),
        'licencia_vencimiento': '${_licenseVencimiento!.year}-${_licenseVencimiento!.month.toString().padLeft(2, '0')}-${_licenseVencimiento!.day.toString().padLeft(2, '0')}',
        'vehiculo_tipo': _selectedType.value,
        'vehiculo_placa': _placaController.text.trim().toUpperCase(),
        'vehiculo_marca': _marcaController.text.trim(),
        'vehiculo_modelo': _modeloController.text.trim(),
        'vehiculo_anio': int.parse(_anioController.text.trim()),
        'vehiculo_color': _colorController.text.trim(),
      };

      if (_aseguradoraController.text.isNotEmpty) {
        data['aseguradora'] = _aseguradoraController.text.trim();
      }
      if (_numeroPolizaController.text.isNotEmpty) {
        data['numero_poliza_seguro'] = _numeroPolizaController.text.trim();
      }
      if (_seguroVencimiento != null) {
        data['vencimiento_seguro'] = '${_seguroVencimiento!.year}-${_seguroVencimiento!.month.toString().padLeft(2, '0')}-${_seguroVencimiento!.day.toString().padLeft(2, '0')}';
      }

      final success = await provider.updateProfile(data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Perfil guardado exitosamente!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload profile
          await provider.loadProfile(widget.conductorId);
          
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Error al guardar el perfil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
