import 'package:flutter/material.dart';

class ConductorStyles {
  // Título principal
  static const String appTitle = "Conductor";

  // Colores generales
  static const Color primaryColor = Colors.blue;
  static const Color drawerHeaderColor = Colors.blue;
  static const Color drawerTextColor = Colors.white;
  static const Color drawerSubTextColor = Colors.white70;

  // Avatar del drawer
  static const CircleAvatar drawerAvatar = CircleAvatar(
    backgroundColor: Colors.white,
    child: Icon(Icons.person, size: 40, color: Colors.blue),
  );

  // Estilo de texto para el rol
  static const TextStyle rolText = TextStyle(
    fontSize: 14,
    color: drawerSubTextColor,
  );

  // Íconos
  static const Icon inicioIcon = Icon(Icons.home);
  static const Icon solicitudesIcon = Icon(Icons.assignment);
  static const Icon configuracionIcon = Icon(Icons.settings);
  static const Icon logoutIcon = Icon(Icons.exit_to_app);
  static const Icon aboutIcon = Icon(Icons.info);

  // Info de la app
  static const String appName = "Transporte rural";
  static const String appVersion = "1.0.0";
  static const String appLegalese = "© 2025 TransporteRural";
}
