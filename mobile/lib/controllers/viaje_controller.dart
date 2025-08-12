import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';

class ViajeController {
  Future<Map<String, dynamic>?> verificarViajeActivo(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/viaje/verificar/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['viajeExistente'] == true) {
          return {
            'viajeExistente': true,
            'viaje': jsonData['viaje'],
            'conductorData': jsonData['viaje']['conductorId'],
            'clienteData': jsonData['viaje']['clienteId'],
            'solicitudData': jsonData['viaje']['solicitudId'],
          };
        } else {
          return {
            'viajeExistente': false,
          };
        }
      } else {
        print('Error al verificar viaje activo: ${response.body}');
        throw Exception('Error al verificar viaje activo: ${response.body}');
      }
    } catch (e) {
      print('Error en verificarViajeActivo: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}