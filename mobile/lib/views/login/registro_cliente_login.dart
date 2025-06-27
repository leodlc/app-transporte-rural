import 'package:flutter/material.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente_model.dart';
import 'main_login.dart';
import 'login_styles.dart'; // ← Importamos estilos

class RegistroClienteLogin extends StatefulWidget {
  const RegistroClienteLogin({super.key});

  @override
  _RegistroClienteLoginState createState() => _RegistroClienteLoginState();
}

class _RegistroClienteLoginState extends State<RegistroClienteLogin> {
  final _clienteController = ClienteController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();

  Future<void> _registrarCliente() async {
    if (_formKey.currentState!.validate()) {
      Cliente cliente = Cliente(
        nombre: _nombreController.text,
        username: _usernameController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        direccion: "",
        password: _passwordController.text,
      );

      bool registrado = await _clienteController.registerCliente(cliente);
      if (registrado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso. Inicia sesión y busca el código de verificación en tu correo.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLogin()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error en el registro. Inténtalo de nuevo.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Cliente")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: LoginStyles.nombreInput,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Campo obligatorio";
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return "Solo letras y espacios";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _usernameController,
                decoration: LoginStyles.usernameInputAlt,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Campo obligatorio";
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return "Solo letras, números o guiones bajos";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _emailController,
                decoration: LoginStyles.emailInput,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Campo obligatorio";
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return "Correo inválido";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _telefonoController,
                decoration: LoginStyles.telefonoInput,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Campo obligatorio";
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return "Debe tener 10 dígitos numéricos";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _passwordController,
                decoration: LoginStyles.passwordInputAlt,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "Mínimo 6 caracteres";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _confirmarPasswordController,
                decoration: LoginStyles.confirmarPasswordInput,
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return "Las contraseñas no coinciden";
                  }
                  return null;
                },
              ),
              LoginStyles.verticalSpacing,
              ElevatedButton(
                onPressed: _registrarCliente,
                child: const Text("Registrar", style: LoginStyles.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
