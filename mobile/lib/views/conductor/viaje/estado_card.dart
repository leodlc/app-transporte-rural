import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';

class EstadoCard extends StatelessWidget {
  final String estado;

  const EstadoCard({required this.estado});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String titulo;

    switch (estado) {
      case 'iniciado':
        icon = Icons.navigation_rounded;
        color = ConductorStyles.primaryColor;
        titulo = 'Dirigiéndose al origen';
        break;
      case 'llegando':
        icon = Icons.security_rounded;
        color = ConductorStyles.warningColor;
        titulo = 'Esperando código de seguridad';
        break;
      case 'en_curso':
        icon = Icons.directions_car_rounded;
        color = ConductorStyles.successColor;
        titulo = 'Viaje en curso';
        break;
      case 'finalizado':
        icon = Icons.check_circle_rounded;
        color = ConductorStyles.successColor;
        titulo = 'Viaje finalizado';
        break;
      case 'cancelado':
        icon = Icons.cancel_rounded;
        color = ConductorStyles.errorColor;
        titulo = 'Viaje cancelado';
        break;
      default:
        icon = Icons.help_rounded;
        color = ConductorStyles.textSecondary;
        titulo = 'Estado desconocido';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}