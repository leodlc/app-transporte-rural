import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';
import '../../controllers/login_controller.dart';
import '../../views/login/login_styles.dart';

/// Formateador personalizado para convertir todo a MAYÚSCULAS
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// 🎨 Duplicación segura de baseInputDecoration
InputDecoration buildInputCodigo(String label, IconData icon, {String? errorText}) {
  return InputDecoration(
    labelText: label,
    labelStyle: LoginStyles.inputLabelStyle,
    prefixIcon: Icon(
      icon,
      color: LoginStyles.textSecondary,
      size: 22,
    ),
    filled: true,
    fillColor: LoginStyles.surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: LoginStyles.spacing16,
      vertical: LoginStyles.spacing16,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
      borderSide: const BorderSide(
        color: LoginStyles.dividerColor,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
      borderSide: const BorderSide(
        color: LoginStyles.primaryGreen,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
      borderSide: const BorderSide(
        color: LoginStyles.errorColor,
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
      borderSide: const BorderSide(
        color: LoginStyles.errorColor,
        width: 2,
      ),
    ),
    errorText: errorText,
    counterText: '',
  );
}

Future<void> showVerificationDialog(BuildContext context, String email) async {
  final TextEditingController _codeController = TextEditingController();
  bool isVerifying = false;
  String? errorMessage;

  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
          ),
          backgroundColor: LoginStyles.surfaceWhite,
          title: Text(
            'Verificar Código',
            style: LoginStyles.sectionTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa el código de verificación enviado a tu email.',
                style: LoginStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              LoginStyles.verticalSpacingLarge,
              TextField(
                controller: _codeController,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: buildInputCodigo(
                  'Código',
                  Icons.verified,
                  errorText: errorMessage,
                ),
              ),
              LoginStyles.verticalSpacing,
              if (isVerifying) const CircularProgressIndicator(),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: LoginStyles.spacing16,
            vertical: LoginStyles.spacing8,
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setState(() => isVerifying = true);

                      final isValid = await _verifyCode(email, _codeController.text);

                      setState(() {
                        isVerifying = false;
                        errorMessage = isValid ? null : 'Código incorrecto';
                      });

                      if (isValid) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('emailVerificado', true);
                        Navigator.of(context).pop();
                      }
                    },
              icon: const Icon(Icons.verified),
              label: const Text('Verificar'),
              style: LoginStyles.primaryButtonStyle,
            ),
            TextButton(
              onPressed: () {
                final loginController = LoginController();
                loginController.logout(context);
              },
              child: const Text('Cerrar sesión'),
              style: LoginStyles.textButtonStyle,
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _verifyCode(String email, String codigo) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/verificacion/codigo');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'codigo': codigo}),
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Error al verificar código: $e');
    return false;
  }
}
