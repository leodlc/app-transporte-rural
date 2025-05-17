import 'package:flutter/material.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente_model.dart';
import 'main_login.dart';

class RegistroClienteLogin extends StatefulWidget {
  const RegistroClienteLogin({super.key});

  @override
  _RegistroClienteLoginState createState() => _RegistroClienteLoginState();
}

class _RegistroClienteLoginState extends State<RegistroClienteLogin> {
  final _clienteController = ClienteController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); // Nuevo
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registrarCliente() async {
    if (_formKey.currentState!.validate()) {
      Cliente cliente = Cliente(
        nombre: _nombreController.text,
        username: _usernameController.text, // Nuevo
        email: _emailController.text,
        telefono: _telefonoController.text,
        direccion: "", // Dirección eliminada, se mantiene vacía por compatibilidad
        password: _passwordController.text,
      );

      bool registrado = await _clienteController.registerCliente(cliente);
      if (registrado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso. Inicia sesión.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLogin()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error en el registro. Inténtalo de nuevo.")),
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
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? "Mínimo 6 caracteres" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrarCliente,
                child: const Text("Registrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
