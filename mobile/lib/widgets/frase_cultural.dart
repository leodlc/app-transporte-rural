import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';

class FraseCulturalDialog extends StatefulWidget {
  const FraseCulturalDialog({super.key});

  @override
  State<FraseCulturalDialog> createState() => _FraseCulturalDialogState();
}

class _FraseCulturalDialogState extends State<FraseCulturalDialog> {
  String? frase;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerFrase();
  }

  Future<void> obtenerFrase() async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/1.0/frase/aleatoria'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        frase = data['data']['frase'];  // 🔥 Aquí está el fix
        cargando = false;
      });
    } else {
      setState(() {
        frase = 'No se pudo cargar la frase cultural.';
        cargando = false;
      });
    }
  } catch (e) {
    setState(() {
      frase = 'Error de conexión.';
      cargando = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Frase Cultural'),
      content: cargando
          ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
          : Text(frase ?? 'Sin frase disponible'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
