import 'package:flutter/material.dart';
import '../../controllers/login_controller.dart';
import 'opcion_registro_login.dart';
import '../../widgets/frase_cultural.dart';
import 'login_styles.dart'; // ← Importar estilos

class MainLogin extends StatefulWidget {
  const MainLogin({super.key});

  @override
  _MainLoginState createState() => _MainLoginState();
}

class _MainLoginState extends State<MainLogin> {
  final LoginController _loginController = LoginController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (_) => const FraseCulturalDialog(),
      );
    });
  }

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
            const Text('RutaMóvil', style: LoginStyles.title),
            const SizedBox(height: 5),
            const Text('Developed by Group #', style: LoginStyles.subtitle),
            const SizedBox(height: 40),
            TextField(
              controller: _loginController.usernameController,
              decoration: LoginStyles.usernameInput,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _loginController.passwordController,
              decoration: LoginStyles.passwordInput,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OpcionRegistroLogin()),
                  );
                },
                child: const Text('¿No tienes cuenta? Regístrate', style: LoginStyles.linkText),
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
