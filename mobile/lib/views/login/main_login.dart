import 'package:flutter/material.dart';
import '../../controllers/login_controller.dart';
import 'opcion_registro_login.dart';
import '../../widgets/frase_cultural.dart';
import 'login_styles.dart';

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
      backgroundColor: LoginStyles.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LoginStyles.spacing24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo con sombra sutil
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LoginStyles.radiusXLarge),
                      boxShadow: [
                        BoxShadow(
                          color: LoginStyles.primaryGreen.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 200,
                    ),
                  ),

                  LoginStyles.verticalSpacingLarge,

                  // Título de bienvenida
                  Text(
                    'Bienvenido a RutaMóvil',
                    style: LoginStyles.title,
                    textAlign: TextAlign.center,
                  ),

                  LoginStyles.verticalSpacingSmall,

                  // Subtítulo
                  Text(
                    'Tu transporte confiable',
                    style: LoginStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),

                  LoginStyles.verticalSpacingXLarge,

                  // Contenedor de formulario
                  Container(
                    padding: const EdgeInsets.all(LoginStyles.spacing24),
                    decoration: LoginStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo de usuario
                        TextField(
                          controller: _loginController.usernameController,
                          decoration: LoginStyles.usernameInput,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        LoginStyles.verticalSpacing,

                        // Campo de contraseña
                        TextField(
                          controller: _loginController.passwordController,
                          decoration: LoginStyles.passwordInput,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _loginController.login(context),
                        ),

                        LoginStyles.verticalSpacing,

                        // Link de registro centrado
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OpcionRegistroLogin(),
                                ),
                              );
                            },
                            style: LoginStyles.textButtonStyle,
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ),

                        LoginStyles.verticalSpacing,

                        // Botón de ingreso
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              _loginController.login(context);
                            },
                            style: LoginStyles.primaryButtonStyle,
                            child: const Text('Ingresar'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  LoginStyles.verticalSpacingLarge,

                  // Créditos
                  Text(
                    'Developed by Group #',
                    style: LoginStyles.subtitle.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}