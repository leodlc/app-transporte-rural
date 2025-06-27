import 'package:flutter/material.dart';

class ClienteStyles {
  // Título general para AppBar
  static const String appTitle = "Cliente";

  // Colores principales
  static const Color primaryColor = Colors.blue;
  static const Color drawerHeaderColor = Colors.blue;
  static const Color drawerTextColor = Colors.white;
  static const Color drawerSubTextColor = Colors.white70;

  // Avatar en el drawer
  static const CircleAvatar drawerAvatar = CircleAvatar(
    backgroundColor: Colors.white,
    child: Icon(Icons.person, size: 40, color: Colors.blue),
  );

  // Estilo para el rol
  static const TextStyle rolText = TextStyle(
    fontSize: 14,
    color: drawerSubTextColor,
  );

  // Íconos del drawer
  static const Icon inicioIcon = Icon(Icons.home);
  static const Icon transporteIcon = Icon(Icons.directions_bus);
  static const Icon perfilIcon = Icon(Icons.person);
  static const Icon configuracionIcon = Icon(Icons.settings);
  static const Icon logoutIcon = Icon(Icons.exit_to_app);
  static const Icon aboutIcon = Icon(Icons.info);

  // Información de la app
  static const String appName = "Transporte rural";
  static const String appVersion = "1.0.0";
  static const String appLegalese = "© 2025 TransporteRural";
}
