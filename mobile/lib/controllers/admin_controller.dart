import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
//import '../models/producto_model.dart';

class AdminController {
  Future<void> fetchAdminData(String id) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/admin/id/$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        // Guardar los datos del administrador en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', data['_id']);
        await prefs.setString('nombre', data['nombre']);
        await prefs.setString('email', data['email']);
        await prefs.setString('telefono', data['telefono']);
        await prefs.setString('role', data['rol']);
      }
    } catch (e) {
      print("Error obteniendo datos del administrador: $e");
    }
  }

  /// Obtener conductores disponibles (tienen vehículo y no tienen pedidos asignados)
  /*Future<List<Map<String, dynamic>>> fetchConductoresDisponibles() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/disponibles");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data
            .map((conductor) => Map<String, dynamic>.from(conductor))
            .toList();
      } else {
        print("❌ Error obteniendo conductores disponibles: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error de conexión al servidor: $e");
      return [];
    }
  }
*/

  /// Asignar un conductor a un pedido
  /*Future<bool> asignarConductor(String pedidoId, String conductorId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/pedidos/$pedidoId/estado");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": "asignado", "conductor": conductorId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ Error asignando conductor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }
  */


  /// Obtener todos los vehículos
  Future<List<Map<String, dynamic>>> fetchVehiculos() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/vehiculo");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data
            .map((vehiculo) => Map<String, dynamic>.from(vehiculo))
            .toList();
      } else {
        print("Error obteniendo vehículos: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return [];
    }
  }

  /// Crear un nuevo vehículo
  Future<bool> crearVehiculo(Map<String, dynamic> vehiculoData) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/vehiculo/createVehiculo");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehiculoData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Error al crear vehículo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }

  /// Eliminar un vehículo
  Future<bool> eliminarVehiculo(String vehiculoId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/vehiculo/$vehiculoId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error eliminando vehículo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }


  /// Obtener todos los conductores
  Future<List<Map<String, dynamic>>> fetchConductores() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data
            .map((conductor) => Map<String, dynamic>.from(conductor))
            .toList();
      } else {
        print("Error obteniendo conductores: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return [];
    }
  }

  /// Crear un nuevo conductor
  Future<bool> crearConductor(Map<String, dynamic> conductorData) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/createDriver");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(conductorData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Error al crear conductor: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }

  /// Obtener vehículos disponibles para asignación
  Future<List<Map<String, dynamic>>> fetchVehiculosDisponibles() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/vehiculo");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data
            .where((vehiculo) => vehiculo['conductor'] == null)
            .map((vehiculo) => Map<String, dynamic>.from(vehiculo))
            .toList();
      } else {
        print("Error obteniendo vehículos disponibles: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return [];
    }
  }

  /// Asignar un vehículo a un conductor
  Future<bool> asignarVehiculoAConductor(String conductorId, String vehiculoId) async {
    final url =
        Uri.parse("${ApiConfig.baseUrl}/api/1.0/conductor/$conductorId");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"vehiculo": vehiculoId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error al asignar vehículo: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión al servidor: $e");
      return false;
    }
  }
}
