import 'package:flutter/material.dart';

class AdminStyles {
  // Estilo general para el AppBar
  static const String appTitle = "Administrador";

  // Estilo para el drawer header
  static const Color drawerHeaderColor = Colors.red;
  static const Color drawerHeaderTextColor = Colors.white;
  static const Color drawerHeaderSubTextColor = Colors.white70;

  // Estilo para los íconos del drawer
  static const Icon conductoresIcon = Icon(Icons.group);
  static const Icon clientesIcon = Icon(Icons.person);
  static const Icon vehiculosIcon = Icon(Icons.directions_car);
  static const Icon cooperativasIcon = Icon(Icons.account_balance);
  static const Icon logoutIcon = Icon(Icons.exit_to_app);
  static const Icon aboutIcon = Icon(Icons.info);

  // Estilo para el avatar del usuario
  static const CircleAvatar drawerAvatar = CircleAvatar(
    backgroundColor: Colors.white,
    child: Icon(Icons.person, size: 40, color: Colors.red),
  );

  // Estilo de texto para roles
  static const TextStyle rolText = TextStyle(fontSize: 14, color: drawerHeaderSubTextColor);

  // Estilo para versión y legalidad del app
  static const String appName = "RutaMóvil";
  static const String appVersion = "1.0.0";
  static const String appLegalese = "© 2025 RutaMóvil";

  // Estilo para títulos de tarjetas
  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Estilo base para subtítulos
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  // Estilo para botones de edición
  static const Icon editIcon = Icon(Icons.edit, color: Colors.blue);

  // Estilo para botones de eliminación
  static const Icon deleteIcon = Icon(Icons.delete, color: Colors.red);

  // Estilo para FAB
  static const Icon fabAddIcon = Icon(Icons.add);

  // Margen de tarjetas
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 8);

  // Padding general
  static const EdgeInsets listPadding = EdgeInsets.all(10);
}
