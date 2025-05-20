import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';

class AgregarConductor extends StatefulWidget {
  const AgregarConductor({super.key});

  @override
  _AgregarConductorState createState() => _AgregarConductorState();
}

class _AgregarConductorState extends State<AgregarConductor> {
  final AdminController _adminController = AdminController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _crearConductor() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final conductorData = {
      "nombre": _nombreController.text,
      "email": _emailController.text,
      "telefono": _telefonoController.text,
      "password": _passwordController.text,
      "activo": true,
      "rol": "conductor",
    };

    bool success = await _adminController.crearConductor(conductorData);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conductor creado exitosamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al crear el conductor")),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Conductor")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre")),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email")),
            TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: "Teléfono")),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _crearConductor,
                    child: const Text("Guardar Conductor")),
          ],
        ),
      ),
    );
  }
}
