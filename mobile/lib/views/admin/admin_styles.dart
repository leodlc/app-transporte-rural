import 'package:flutter/material.dart';

class AdminStyles {
  // General
  static const String appTitle = "Administrador";

  // Paleta de colores inspirada en el logo de RutaMóvil
  static const Color primaryColor = Color(0xFF00384D); // Azul oscuro del logo
  static const Color accentColor = Color(0xFF5E9D48);  // Verde del logo
  static const Color secondaryColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;
  static const Color subtitleTextColor = Colors.black87;
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Drawer Header
  static const Color drawerHeaderColor = primaryColor;
  static const Color drawerHeaderTextColor = secondaryColor;
  static const Color drawerHeaderSubTextColor = secondaryTextColor;

  static const TextStyle drawerHeaderTitleStyle = TextStyle(
    color: drawerHeaderTextColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle drawerHeaderSubtitleStyle = TextStyle(
    color: drawerHeaderSubTextColor,
    fontSize: 14,
  );

  static const CircleAvatar drawerAvatar = CircleAvatar(
    backgroundColor: secondaryColor,
    radius: 30,
    child: Icon(Icons.person, size: 36, color: primaryColor),
  );

  // Drawer Icons
  static const Icon conductoresIcon = Icon(Icons.group_outlined);
  static const Icon clientesIcon = Icon(Icons.person_outline);
  static const Icon vehiculosIcon = Icon(Icons.directions_car_filled_outlined);
  static const Icon cooperativasIcon = Icon(Icons.account_balance_outlined);
  static const Icon logoutIcon = Icon(Icons.logout);
  static const Icon aboutIcon = Icon(Icons.info_outline);

  // Roles
  static const TextStyle rolText = TextStyle(
    fontSize: 14,
    color: drawerHeaderSubTextColor,
  );

  // App Info
  static const String appName = "RutaMóvil";
  static const String appVersion = "1.0.0";
  static const String appLegalese = "© 2025 RutaMóvil";

  // Card titles
  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.black, // El negro es ideal para la legibilidad del título
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: subtitleTextColor,
  );

  // Card styling helper
  static BoxDecoration cardBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Icon buttons
  static const Icon editIcon = Icon(Icons.edit_outlined, color: accentColor); // Usamos el verde de acento
  static const Icon deleteIcon = Icon(Icons.delete_outline, color: Colors.red); // Mantenemos el rojo por UX
  static const Icon fabAddIcon = Icon(Icons.add, color: Colors.white);

  // Spacing
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 8, horizontal: 12);
  static const EdgeInsets listPadding = EdgeInsets.all(16);
}