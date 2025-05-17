import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage(context, "Inicio de sesión exitoso");

        String token = data["token"];
        String role = data["usuario"]["rol"];
        String userId = data["usuario"]["id"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('id', userId);

        if (role == "cliente") {
          await _clienteController.fetchClienteData(userId);
        } else if (role == "conductor") {
          await _conductorController.fetchConductorData(userId);
        }

        Future.delayed(Duration.zero, () {
          _navigateToRoleScreen(context, role);
        });
      } else {
        _showMessage(
            context, data["message"] ?? "Error en el inicio de sesión");
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
