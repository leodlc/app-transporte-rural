import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cliente_model.dart';
import '../config/api_config.dart';
/* import '../models/direccion_model.dart';
import '../models/ubicacion_model.dart'; */

class ClienteController {
  Future<Map<String, dynamic>?> fetchClienteData(String id) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente/id/$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        // Guardar los datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', data['_id']);
        await prefs.setString('nombre', data['nombre']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString('telefono', data['telefono']);
        await prefs.setString('role', data['rol']);

        // Retornar la información del cliente
        return data;
      } else {
        print("Error obteniendo datos del cliente: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return null;
    }
  }

  Future<bool> registerCliente(Cliente cliente) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente/createClient");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Error en el registro de cliente: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }

  Future<List<Cliente>> fetchAllClientes() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((json) => Cliente.fromJson(json)).toList();
      } else {
        print("Error al obtener la lista de clientes: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return [];
    }
  }

  Future<Cliente?> fetchClienteByNombre(String nombre) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente/nombre/$nombre");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return Cliente.fromJson(data);
      } else {
        print("Error al buscar cliente por nombre: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return null;
    }
  }

  Future<bool> updateCliente(String id, Map<String, dynamic> fieldsToUpdate) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente/$id");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(fieldsToUpdate),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar cliente: $e");
      return false;
    }
  }


  Future<bool> deleteCliente(String id) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/cliente/$id");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error al eliminar cliente: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }



}