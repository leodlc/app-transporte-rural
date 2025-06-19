import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conductor_model.dart';
import '../config/api_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConductorController {
  Future<void> fetchConductorData(String id) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/id/$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        // Guardar los datos del conductor en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', data['_id']);
        await prefs.setString('nombre', data['nombre']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString('telefono', data['telefono']);
        await prefs.setString('vehiculo', data['vehiculo'] ?? "Sin vehículo asignado");
        await prefs.setString('role', data['rol']);
        await prefs.setBool('emailVerificado', data['emailVerificado']);
        await prefs.setBool('ubicacionActiva', data['ubicacionActiva']);


        // Guardar la cooperativa si existe
        if (data['cooperativa'] != null) {
          await prefs.setString('cooperativa', data['cooperativa'].toString());
        }
      } else {
        print("Error al obtener conductor: ${response.body}");
      }
    } catch (e) {
      print("Error obteniendo datos del conductor: $e");
    }
  }

  Future<bool> registerConductor(Conductor conductor) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/createDriver");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(conductor.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Error en el registro de conductor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }

  Future<bool> updateConductor(String id, Map<String, dynamic> fieldsToUpdate) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/$id");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(fieldsToUpdate),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar conductor: $e");
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getConductoresActivos() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/activos");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Error al obtener conductores activos: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error al obtener conductores activos: $e");
      return [];
    }
  }


}
