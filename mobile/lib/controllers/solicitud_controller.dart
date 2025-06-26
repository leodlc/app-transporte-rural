import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class SolicitudController {
  // Obtener solicitudes pendientes por conductor
  Future<List<Map<String, dynamic>>> getSolicitudesPorConductor(String conductorId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/por-conductor/$conductorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonData['data']);
    } else {
      throw Exception('Error al obtener solicitudes: ${response.body}');
    }
  }

  // Cambiar estado de una solicitud (PATCH)
  Future<void> actualizarEstadoSolicitud({
    required String solicitudId,
    required String nuevoEstado,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/$solicitudId/estado');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': nuevoEstado}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado: ${response.body}');
    }
  }

  // Crear nueva solicitud (opcional)
  Future<void> crearSolicitud({
    required String clienteId,
    required String conductorId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/crear');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clienteId': clienteId,
        'conductorId': conductorId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al crear solicitud: ${response.body}');
    }
  }
}
