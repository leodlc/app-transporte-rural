import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';

class ClienteInfoCard extends StatelessWidget {

  final Map<String, dynamic> clienteData;

  const ClienteInfoCard({required this.clienteData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ConductorStyles.primaryColor,
            child: Text(
              clienteData['nombre'][0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clienteData['nombre'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  clienteData['telefono'],
                  style: TextStyle(fontSize: 14, color: ConductorStyles.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}