import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart'; // Asegúrate de importar correctamente tu baseUrl

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
          title: const Text('Verificar Código'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa el código de verificación enviado a tu email.'),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'Código',
                  errorText: errorMessage,
                  counterText: '', // Oculta el contador de caracteres
                ),
              ),
              const SizedBox(height: 10),
              if (isVerifying) const CircularProgressIndicator(),
            ],
          ),
          actions: [
            ElevatedButton(
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
              child: const Text('Verificar'),
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
