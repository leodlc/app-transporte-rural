import 'package:flutter/material.dart';

class ClienteStyles {
  // Título general para AppBar
  static const String appTitle = "RutaMóvil";

  // Colores principales heredados del sistema de diseño
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryNavy = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);

  // Colores neutros
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFF57C00);

  // Colores específicos para cliente
  static const Color primaryColor = primaryGreen;
  static const Color drawerHeaderGradientStart = primaryGreen;
  static const Color drawerHeaderGradientEnd = Color(0xFF388E3C);
  static const Color selectedItemColor = primaryGreen;
  static const Color unselectedItemColor = textPrimary;

  // Espaciados consistentes
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircular = 100.0;

  // Elevaciones
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  // Estilos de texto
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle drawerHeaderTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: surfaceWhite,
    letterSpacing: -0.5,
  );

  static const TextStyle drawerHeaderSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: surfaceWhite,
    letterSpacing: 0.1,
  );

  static const TextStyle drawerItemText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Avatar en el drawer
  static Widget drawerAvatar({String? imageUrl, String? initials}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 35,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: surfaceWhite,
      );
    }

    return CircleAvatar(
      radius: 35,
      backgroundColor: surfaceWhite,
      child: initials != null
          ? Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryGreen,
        ),
      )
          : Icon(
        Icons.person_rounded,
        size: 40,
        color: primaryGreen,
      ),
    );
  }

  // Decoración del header del drawer
  static BoxDecoration drawerHeaderDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [drawerHeaderGradientStart, drawerHeaderGradientEnd],
    ),
  );

  // Íconos del drawer con estilo moderno
  static const Icon inicioIcon = Icon(Icons.home_rounded, size: 24);
  static const Icon transporteIcon = Icon(Icons.directions_bus_rounded, size: 24);
  static const Icon historialIcon = Icon(Icons.history_rounded, size: 24);
  static const Icon perfilIcon = Icon(Icons.person_rounded, size: 24);
  static const Icon configuracionIcon = Icon(Icons.settings_rounded, size: 24);
  static const Icon notificacionesIcon = Icon(Icons.notifications_rounded, size: 24);
  static const Icon ayudaIcon = Icon(Icons.help_rounded, size: 24);
  static const Icon logoutIcon = Icon(Icons.logout_rounded, size: 24);
  static const Icon aboutIcon = Icon(Icons.info_rounded, size: 24);

  // Decoración de tarjetas
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Decoración de contenedores elevados
  static BoxDecoration elevatedContainerDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Estilos de botones
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    foregroundColor: surfaceWhite,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing24,
      vertical: spacing16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: elevationSmall,
    textStyle: buttonText,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceWhite,
    foregroundColor: primaryGreen,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing24,
      vertical: spacing16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      side: BorderSide(color: primaryGreen, width: 1.5),
    ),
    elevation: 0,
    textStyle: buttonText,
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: accentBlue,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing8,
    ),
    textStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // Estilo para ListTile del drawer
  static ListTileThemeData drawerListTileTheme = ListTileThemeData(
    selectedColor: primaryGreen,
    selectedTileColor: primaryGreen.withOpacity(0.1),
    iconColor: textSecondary,
    textColor: textPrimary,
    horizontalTitleGap: spacing12,
    contentPadding: EdgeInsets.symmetric(
      horizontal: spacing20,
      vertical: spacing8,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
  );

  // Decoración para campos de búsqueda
  static InputDecoration searchInputDecoration = InputDecoration(
    hintText: 'Buscar...',
    hintStyle: TextStyle(color: textSecondary),
    prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
    filled: true,
    fillColor: surfaceWhite,
    contentPadding: EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusCircular),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusCircular),
      borderSide: BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusCircular),
      borderSide: BorderSide(color: primaryGreen, width: 2),
    ),
  );

  // Estilo para badges/chips
  static BoxDecoration chipDecoration({Color? color}) {
    return BoxDecoration(
      color: (color ?? primaryGreen).withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusCircular),
      border: Border.all(
        color: (color ?? primaryGreen).withOpacity(0.3),
      ),
    );
  }

  // Información de la app
  static const String appName = "RutaMóvil";
  static const String appVersion = "1.0.0";
  static const String appLegalese = "© 2025 RutaMóvil - Transporte Rural";
  static const String appDescription = "Tu transporte rural confiable";

  // Tema para la aplicación del cliente
  static ThemeData clientTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: accentBlue,
      surface: surfaceWhite,
      background: backgroundLight,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: appBarTitle,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: surfaceWhite,
      elevation: elevationLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(radiusLarge),
          bottomRight: Radius.circular(radiusLarge),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: textButtonStyle,
    ),
    cardTheme: CardThemeData(
      elevation: elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      color: surfaceWhite,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: elevationLarge,
    ),
  );
}