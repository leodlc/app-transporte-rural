import 'package:flutter/material.dart';

class LoginStyles {
  // Colores principales basados en el logo
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

  // Espaciados consistentes
  static const double spacing8 = 8.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevaciones
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  // Estilos de texto
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle cardText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle linkText = TextStyle(
    color: accentBlue,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputLabelStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  );

  // Decoraciones de input minimalistas
  static InputDecoration _baseInputDecoration({
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: inputLabelStyle,
      prefixIcon: Icon(
        icon,
        color: iconColor ?? textSecondary,
        size: 22,
      ),
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: dividerColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: primaryGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),
    );
  }

  // Inputs específicos
  static InputDecoration usernameInput = _baseInputDecoration(
    label: 'Usuario',
    icon: Icons.person_outline_rounded,
  );

  static InputDecoration passwordInput = _baseInputDecoration(
    label: 'Contraseña',
    icon: Icons.lock_outline_rounded,
  );

  static InputDecoration nombreInput = _baseInputDecoration(
    label: 'Nombre completo',
    icon: Icons.person_outline_rounded,
  );

  static InputDecoration usernameInputAlt = _baseInputDecoration(
    label: 'Nombre de usuario',
    icon: Icons.alternate_email_rounded,
  );

  static InputDecoration emailInput = _baseInputDecoration(
    label: 'Correo electrónico',
    icon: Icons.email_outlined,
  );

  static InputDecoration telefonoInput = _baseInputDecoration(
    label: 'Teléfono',
    icon: Icons.phone_outlined,
  );

  static InputDecoration passwordInputAlt = _baseInputDecoration(
    label: 'Contraseña',
    icon: Icons.lock_outline_rounded,
  );

  static InputDecoration confirmarPasswordInput = _baseInputDecoration(
    label: 'Confirmar contraseña',
    icon: Icons.lock_reset_rounded,
  );

  static InputDecoration cooperativaInput = _baseInputDecoration(
    label: 'Cooperativa',
    icon: Icons.business_rounded,
    iconColor: primaryNavy,
  );

  // Iconos estilizados
  static Icon clienteIcon = Icon(
    Icons.person_rounded,
    size: 64,
    color: primaryGreen,
  );

  static Icon conductorIcon = Icon(
    Icons.directions_car_rounded,
    size: 64,
    color: primaryNavy,
  );

  // Espaciados predefinidos
  static const SizedBox verticalSpacing = SizedBox(height: spacing16);
  static const SizedBox verticalSpacingSmall = SizedBox(height: spacing8);
  static const SizedBox verticalSpacingLarge = SizedBox(height: spacing24);
  static const SizedBox verticalSpacingXLarge = SizedBox(height: spacing32);

  // Estilos de botón
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    foregroundColor: surfaceWhite,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing32,
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
    foregroundColor: primaryNavy,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing32,
      vertical: spacing16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      side: BorderSide(color: primaryNavy, width: 1.5),
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
    textStyle: linkText,
  );

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

  // Estilo para DropdownButton
  static InputDecoration dropdownDecoration({
    required String label,
    required IconData icon,
    Color? iconColor,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: inputLabelStyle,
      helperText: helperText,
      helperStyle: TextStyle(
        fontSize: 12,
        color: textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        color: iconColor ?? textSecondary,
        size: 22,
      ),
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: dividerColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: primaryGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),
    );
  }

  // Tema de la aplicación
  static ThemeData appTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: primaryNavy,
      surface: surfaceWhite,
      background: backgroundLight,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceWhite,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: sectionTitle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: textButtonStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      color: surfaceWhite,
    ),
  );
}