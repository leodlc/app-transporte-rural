import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificacionController {
  Future<String?> obtenerTokenFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Forzar actualización del token
    await messaging.deleteToken();
    String? token = await messaging.getToken();

    print("🔑 Token FCM actualizado: $token");
    return token;
  }

  /// Actualizar el Token FCM de un cliente
  Future<bool> actualizarTokenCliente(String clienteId) async {
    final token = await obtenerTokenFCM();
    if (token == null) return false;

    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/clientes/$clienteId/tokenFCM");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"tokenFCM": token}),
      );

      if (response.statusCode == 200) {
        print("✅ Token FCM actualizado para cliente");
        return true;
      } else {
        print("❌ Error al actualizar token FCM del cliente: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }

  /// Actualizar el Token FCM de un conductor
  Future<bool> actualizarTokenConductor(String conductorId) async {
    final token = await obtenerTokenFCM();
    if (token == null) return false;

    final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/1.0/conductor/$conductorId/tokenFCM");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"tokenFCM": token}),
      );

      if (response.statusCode == 200) {
        print("✅ Token FCM actualizado para conductor");
        return true;
      } else {
        print(
            "❌ Error al actualizar token FCM del conductor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }

  /// Actualizar el Token FCM de un administrador
  Future<bool> actualizarTokenAdmin(String adminId) async {
    final token = await obtenerTokenFCM();
    if (token == null) return false;

    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/admin/$adminId/tokenFCM");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"tokenFCM": token}),
      );

      if (response.statusCode == 200) {
        print("✅ Token FCM actualizado para administrador");
        return true;
      } else {
        print(
            "❌ Error al actualizar token FCM del administrador: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }

  /// Enviar notificación push a un cliente
  /*Future<bool> enviarNotificacionCliente(String clienteId, String titulo, String cuerpo) async {
    final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/1.0/clientes/$clienteId/sendPushNotification");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"titulo": titulo, "cuerpo": cuerpo}),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada al cliente");
        return true;
      } else {
        print("❌ Error al enviar notificación al cliente: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }

  */

  /// Enviar notificación push a un conductor
  /*
  Future<bool> enviarNotificacionConductor(String conductorId, String titulo, String cuerpo) async {
    final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/1.0/conductores/$conductorId/sendPushNotification");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"titulo": titulo, "cuerpo": cuerpo}),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada al conductor");
        return true;
      } else {
        print("❌ Error al enviar notificación al conductor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }
  */

  /// Enviar notificación push a un administrador
  /*
  Future<bool> enviarNotificacionAdmin(String adminId, String titulo, String cuerpo) async {
    final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/1.0/admin/$adminId/sendPushNotification");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"titulo": titulo, "cuerpo": cuerpo}),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada al administrador");
        return true;
      } else {
        print(
            "❌ Error al enviar notificación al administrador: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return false;
    }
  }
  */

  /// Obtener notificaciones de un cliente
  /*
  Future<List<Map<String, dynamic>>> obtenerNotificacionesCliente(String clienteId) async {
    final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/1.0/clientes/$clienteId/notificaciones");

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)["data"];
        return data.cast<Map<String, dynamic>>();
      } else {
        print("❌ Error al obtener notificaciones: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return [];
    }
  }
   */
}
