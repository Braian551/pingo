// lib/src/widgets/dialogs/dialogs_example_screen.dart
// Esta pantalla es solo para demostraciÃ³n y pruebas
// No es necesaria para el funcionamiento de la app

import 'package:flutter/material.dart';
import 'dialog_helper.dart';
import '../snackbars/custom_snackbar.dart';

class DialogsExampleScreen extends StatelessWidget {
  const DialogsExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ejemplos de Alertas'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DiÃ¡logos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // DiÃ¡logo de Ã©xito
            ElevatedButton(
              onPressed: () {
                DialogHelper.showSuccess(
                  context,
                  title: 'Â¡Registro Exitoso!',
                  message: 'Tu cuenta ha sido creada correctamente y ya puedes comenzar a usar la aplicaciÃ³n.',
                  primaryButtonText: 'Continuar',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar DiÃ¡logo de Ã‰xito'),
            ),

            const SizedBox(height: 12),

            // DiÃ¡logo de error
            ElevatedButton(
              onPressed: () {
                DialogHelper.showError(
                  context,
                  title: 'CÃ³digo Incorrecto',
                  message: 'El cÃ³digo de verificaciÃ³n que ingresaste no es vÃ¡lido. Por favor, verifica e intenta nuevamente.',
                  primaryButtonText: 'Reintentar',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar DiÃ¡logo de Error'),
            ),

            const SizedBox(height: 12),

            // DiÃ¡logo de advertencia
            ElevatedButton(
              onPressed: () {
                DialogHelper.showWarning(
                  context,
                  title: 'AcciÃ³n Irreversible',
                  message: 'Esta acciÃ³n no se puede deshacer. Â¿EstÃ¡s seguro de que deseas continuar?',
                  primaryButtonText: 'Continuar',
                  secondaryButtonText: 'Cancelar',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar DiÃ¡logo de Advertencia'),
            ),

            const SizedBox(height: 12),

            // DiÃ¡logo informativo
            ElevatedButton(
              onPressed: () {
                DialogHelper.showInfo(
                  context,
                  title: 'InformaciÃ³n Importante',
                  message: 'Tu ubicaciÃ³n serÃ¡ utilizada para brindarte un mejor servicio y mostrarte las opciones mÃ¡s cercanas.',
                  primaryButtonText: 'Entendido',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar DiÃ¡logo Informativo'),
            ),

            const SizedBox(height: 12),

            // DiÃ¡logo de confirmaciÃ³n
            ElevatedButton(
              onPressed: () async {
                final result = await DialogHelper.showConfirmation(
                  context,
                  title: 'Â¿Eliminar Cuenta?',
                  message: 'Â¿EstÃ¡s seguro de que deseas eliminar tu cuenta? Esta acciÃ³n es permanente.',
                  confirmText: 'Eliminar',
                  cancelText: 'Cancelar',
                );

                if (result == true && context.mounted) {
                  CustomSnackbar.showSuccess(
                    context,
                    message: 'AcciÃ³n confirmada',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar DiÃ¡logo de ConfirmaciÃ³n'),
            ),

            const SizedBox(height: 32),

            const Text(
              'Snackbars',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Snackbar de Ã©xito
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.showSuccess(
                  context,
                  message: 'Â¡Correo verificado exitosamente!',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar Snackbar de Ã‰xito'),
            ),

            const SizedBox(height: 12),

            // Snackbar de error
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.showError(
                  context,
                  message: 'No se pudo conectar al servidor',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar Snackbar de Error'),
            ),

            const SizedBox(height: 12),

            // Snackbar de advertencia
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.showWarning(
                  context,
                  message: 'Por favor, completa todos los campos requeridos',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar Snackbar de Advertencia'),
            ),

            const SizedBox(height: 12),

            // Snackbar informativo
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.showInfo(
                  context,
                  message: 'Cargando informaciÃ³n del perfil...',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar Snackbar Informativo'),
            ),

            const SizedBox(height: 12),

            // Snackbar con acciÃ³n
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.showError(
                  context,
                  message: 'Error al guardar los cambios',
                  actionLabel: 'REINTENTAR',
                  onAction: () {
                    CustomSnackbar.showInfo(
                      context,
                      message: 'Reintentando...',
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mostrar Snackbar con AcciÃ³n'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
