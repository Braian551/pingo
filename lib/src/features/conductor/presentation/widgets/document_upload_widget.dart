import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

enum DocumentType {
  image,
  pdf,
  any,
}

class DocumentUploadWidget extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? filePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final IconData icon;
  final DocumentType acceptedType;
  final bool isRequired;

  const DocumentUploadWidget({
    super.key,
    required this.label,
    this.subtitle,
    required this.filePath,
    required this.onTap,
    this.onRemove,
    this.icon = Icons.upload_file_rounded,
    this.acceptedType = DocumentType.any,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath != null && filePath!.isNotEmpty;
    final isPdf = hasFile && filePath!.toLowerCase().endsWith('.pdf');

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
                color: hasFile
                    ? const Color(0xFFFFFF00).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Previsualización o icono
                    _buildPreview(hasFile, isPdf),
                    const SizedBox(width: 16),
                    
                    // Información del documento
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isRequired && !hasFile)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Requerido',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasFile
                                ? _getFileName()
                                : subtitle ?? _getAcceptedTypesText(),
                            style: TextStyle(
                              color: hasFile
                                  ? const Color(0xFFFFFF00)
                                  : Colors.white54,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Icono de acción
                    if (hasFile && onRemove != null)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        onPressed: onRemove,
                        tooltip: 'Eliminar',
                      )
                    else
                      Icon(
                        hasFile
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: hasFile
                            ? const Color(0xFFFFFF00)
                            : Colors.white.withOpacity(0.3),
                        size: 28,
                      ),
                  ],
                ),
                
                // Botón de vista previa ampliada (solo para imágenes)
                if (hasFile && !isPdf)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () => _showFullPreview(context),
                      icon: const Icon(
                        Icons.visibility_rounded,
                        size: 18,
                        color: Color(0xFFFFFF00),
                      ),
                      label: const Text(
                        'Ver imagen completa',
                        style: TextStyle(
                          color: Color(0xFFFFFF00),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: const Color(0xFFFFFF00).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

  Widget _buildPreview(bool hasFile, bool isPdf) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: hasFile
            ? const Color(0xFFFFFF00).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile
              ? const Color(0xFFFFFF00).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: hasFile
          ? isPdf
              ? _buildPdfPreview()
              : _buildImagePreview()
          : _buildEmptyPreview(),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(filePath!),
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          color: Colors.red.shade400,
          size: 36,
        ),
        const SizedBox(height: 4),
        const Text(
          'PDF',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return Icon(
      icon,
      color: Colors.white.withOpacity(0.4),
      size: 36,
    );
  }

  String _getFileName() {
    if (filePath == null || filePath!.isEmpty) return '';
    final file = File(filePath!);
    final name = file.path.split('/').last;
    
    // Si el nombre es muy largo, mostrar solo el inicio y el final
    if (name.length > 30) {
      return '${name.substring(0, 15)}...${name.substring(name.length - 10)}';
    }
    return name;
  }

  String _getAcceptedTypesText() {
    switch (acceptedType) {
      case DocumentType.image:
        return 'Toca para seleccionar imagen';
      case DocumentType.pdf:
        return 'Toca para seleccionar PDF';
      case DocumentType.any:
        return 'Imagen o PDF';
    }
  }

  void _showFullPreview(BuildContext context) {
    if (filePath == null || filePath!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(filePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Botón cerrar
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              
              // Indicador de nombre del archivo
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFFFFFF00),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFileName(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper para mostrar bottom sheet de selección de documento
class DocumentPickerHelper {
  static Future<String?> showPickerOptions({
    required BuildContext context,
    required DocumentType documentType,
  }) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentPickerBottomSheet(
        documentType: documentType,
      ),
    );

    return source;
  }

  static Future<String?> pickDocument({
    required BuildContext context,
    required DocumentType documentType,
  }) async {
    try {
      final action = await showPickerOptions(
        context: context,
        documentType: documentType,
      );

      if (action == null) return null;

      if (action == 'pdf') {
        // Seleccionar PDF
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          return result.files.single.path!;
        }
      } else {
        // Seleccionar imagen (cámara o galería)
        final ImagePicker picker = ImagePicker();
        final ImageSource source = action == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;

        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          return image.path;
        }
      }
    } catch (e) {
      print('Error al seleccionar documento: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar documento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return null;
  }
}

class _DocumentPickerBottomSheet extends StatelessWidget {
  final DocumentType documentType;

  const _DocumentPickerBottomSheet({
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                'Seleccionar documento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Opciones según el tipo de documento aceptado
              if (documentType == DocumentType.image ||
                  documentType == DocumentType.any) ...[
                _buildOption(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar foto',
                  subtitle: 'Usa la cámara',
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                _buildOption(
                  context: context,
                  icon: Icons.photo_library_rounded,
                  title: 'Galería de fotos',
                  subtitle: 'Selecciona una imagen',
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ],
              
              if (documentType == DocumentType.pdf ||
                  documentType == DocumentType.any) ...[
                _buildOption(
                  context: context,
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Archivo PDF',
                  subtitle: 'Selecciona un documento PDF',
                  color: Colors.red.shade400,
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? const Color(0xFFFFFF00);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: optionColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: optionColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
