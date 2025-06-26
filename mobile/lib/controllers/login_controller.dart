import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/controllers/admin_controller.dart';
import 'package:mobile/views/admin/main_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/cliente/main_cliente.dart';
import '../views/conductor/main_conductor.dart';
import '../views/login/main_login.dart';
import 'cliente_controller.dart';
import 'conductor_controller.dart';
import '../config/api_config.dart';

class LoginController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ClienteController _clienteController = ClienteController();
  final ConductorController _conductorController = ConductorController();
  final AdminController _adminController = AdminController();


  Future<void> login(BuildContext context) async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage(context, "Por favor, ingresa tu usuario y contraseña.");
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/api/1.0/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String token = data["token"];
        String role = data["usuario"]["rol"];
        String userId = data["usuario"]["id"];
        bool isActive = data["usuario"]["activo"];
        bool emailVerificado = data["usuario"]["emailVerificado"] ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('id', userId);
        await prefs.setBool('emailVerificado', emailVerificado);

        if (role == "cliente") {
          await _clienteController.fetchClienteData(userId);
        } else if (role == "conductor") {
          await _conductorController.fetchConductorData(userId);
        } else if (role == "admin") {
          await _adminController.fetchAdminData(userId);
        }

        Future.delayed(Duration.zero, () {
          if (isActive) {
            _showMessage(context, "Inicio de sesión exitoso");
            _navigateToRoleScreen(context, role);
          } else {
            _showMessage(context, "Usuario bloqueado");
          }
        });
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Error de credenciales
        final data = jsonDecode(response.body);
        String error = data['error'] ?? "Credenciales incorrectas.";
        _showMessage(context, error);
      } else {
        _showMessage(context, "Ocurrió un error inesperado.");
      }
    } catch (e) {
      _showMessage(context, "Error de conexión al servidor");
    }
  }


  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? role = prefs.getString('role');

    if (token != null && role != null) {
      print("Usuario logueado como $role");
    }
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    String? role = prefs.getString('role');

    if (userId != null && role != null) {
      String endpoint;

      switch (role) {
        case "cliente":
          endpoint = "/api/1.0/cliente/$userId/clear-token";
          break;
        case "conductor":
          endpoint = "/api/1.0/conductor/$userId/clear-token";
          break;
        case "admin":
          endpoint = "/api/1.0/admin/$userId/clear-token";
          break;
        default:
          endpoint = "";
      }

      if (endpoint.isNotEmpty) {
        final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");

        try {
          await http.patch(url);
        } catch (e) {
          print("Error eliminando token FCM del backend: $e");
        }
      }
    }

    // Limpiar almacenamiento local
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLogin()),
    );
  }


  void _navigateToRoleScreen(BuildContext context, String role) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (role == "cliente") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainCliente()));
      } else if (role == "conductor") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainConductor()));
      } else if (role == "admin") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainAdmin()));
      }
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
  }
}
