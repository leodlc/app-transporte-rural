import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CooperativaController {
  final String _baseUrl = "${ApiConfig.baseUrl}/api/1.0/cooperativa";

  Future<List<Map<String, dynamic>>> fetchAllCooperativas() async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.cast<Map<String, dynamic>>();
      } else {
        print("Error al obtener cooperativas: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCooperativaById(String id) async {
    final url = Uri.parse("$_baseUrl/$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        print("Error al obtener la cooperativa: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error de conexión: $e");
      return null;
    }
  }

  Future<bool> createCooperativa(Map<String, dynamic> cooperativa) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cooperativa),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Error al crear la cooperativa: $e");
      return false;
    }
  }

  Future<bool> updateCooperativa(String id, Map<String, dynamic> cooperativa) async {
    final url = Uri.parse("$_baseUrl/$id");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cooperativa),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar la cooperativa: $e");
      return false;
    }
  }

  Future<bool> deleteCooperativa(String id) async {
    final url = Uri.parse("$_baseUrl/$id");

    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Error al eliminar la cooperativa: $e");
      return false;
    }
  }
}
