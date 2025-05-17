import 'package:flutter/material.dart';
import '../../controllers/login_controller.dart';
import 'opcion_registro_login.dart';

class MainLogin extends StatefulWidget {
  const MainLogin({super.key});

  @override
  _MainLoginState createState() => _MainLoginState();
}

class _MainLoginState extends State<MainLogin> {
  final LoginController _loginController = LoginController();

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Transporte rural',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Developed by Group #',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _loginController.usernameController,  // Cambiado aquí
              decoration: const InputDecoration(
                labelText: 'Usuario',  // Cambiado a "Usuario"
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),  // Icono más adecuado
              ),
              keyboardType: TextInputType.text,  // Cambiado a texto normal
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _loginController.passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OpcionRegistroLogin()),
                  );
                },
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _loginController.login(context);
                },
                child: const Text('Ingresar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
