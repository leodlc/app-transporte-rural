// controllers/notificacion_controller.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class NotificacionController {
  Future<void> enviarNotificacion({
    required String emisorId,
    required String rolEmisor,
    required String usuarioId,
    required String rol,
    required String titulo,
    required String cuerpo,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/notificacion/enviar');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emisorId': emisorId,
        'rolEmisor': rolEmisor,
        'usuarioId': usuarioId, // receptor
        'rol': rol,             // rol del receptor
        'titulo': titulo,
        'cuerpo': cuerpo,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar notificación: ${response.body}');
    }
  }


  Future<void> registrarTokenFCM({
    required String usuarioId,
    required String rol,
    required String tokenFCM,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/notificacion/token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioId,
        'rol': rol,
        'tokenFCM': tokenFCM,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al registrar token FCM: ${response.body}');
    }
  }
}
