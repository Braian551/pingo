import 'dart:ui';
import 'package:flutter/material.dart';

class ViajeActivoCard extends StatelessWidget {
  final Map<String, dynamic> viaje;

  const ViajeActivoCard({
    super.key,
    required this.viaje,
  });

  @override
  Widget build(BuildContext context) {
    final origen = viaje['origen'] ?? 'Origen desconocido';
    final destino = viaje['destino'] ?? 'Destino desconocido';
    final estado = viaje['estado'] ?? 'pendiente';
    final precio = viaje['precio_estimado']?.toString() ?? '0';
    final clienteNombre = viaje['cliente_nombre'] ?? 'Cliente';

    Color estadoColor;
    IconData estadoIcon;
    String estadoTexto;

    switch (estado) {
      case 'en_camino':
        estadoColor = Colors.blue;
        estadoIcon = Icons.directions_car;
        estadoTexto = 'En camino al origen';
        break;
      case 'en_progreso':
        estadoColor = Colors.green;
        estadoIcon = Icons.navigation;
        estadoTexto = 'En progreso';
        break;
      case 'por_iniciar':
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
        estadoTexto = 'Por iniciar';
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help_outline;
        estadoTexto = 'Pendiente';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, color: estadoColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          estadoTexto,
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$$precio',
                    style: const TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFFF00),
                    radius: 20,
                    child: Text(
                      clienteNombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      clienteNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLocationRow(Icons.circle, Colors.green, origen),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.location_on, Colors.red, destino),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Llamar al cliente
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Llamar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Ver detalles del viaje
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
