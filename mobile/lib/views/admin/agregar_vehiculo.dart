import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';

class AgregarVehiculo extends StatefulWidget {
  const AgregarVehiculo({super.key});

  @override
  _AgregarVehiculoState createState() => _AgregarVehiculoState();
}

class _AgregarVehiculoState extends State<AgregarVehiculo> {
  final AdminController _adminController = AdminController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _rmtController = TextEditingController();

  bool _isLoading = false;

  Future<void> _crearVehiculo() async {
    if (_marcaController.text.isEmpty ||
        _modeloController.text.isEmpty ||
        _placaController.text.isEmpty ||
        _rmtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final vehiculoData = {
      "marca": _marcaController.text,
      "modelo": _modeloController.text,
      "placa": _placaController.text,
      "rmt": _rmtController.text,
    };

    bool success = await _adminController.crearVehiculo(vehiculoData);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(
          context, true); // Devuelve true para actualizar la lista de vehículos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehículo creado exitosamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al crear el vehículo")),
      );
    }
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Vehículo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _marcaController,
              decoration: const InputDecoration(labelText: "Marca"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _modeloController,
              decoration: const InputDecoration(labelText: "Modelo"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _placaController,
              decoration: const InputDecoration(labelText: "Placa"),
            ),
            TextField(
              controller: _rmtController,
              decoration: const InputDecoration(labelText: "RMT (Número de habilitación operacional)"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _crearVehiculo,
                    child: const Text("Guardar Vehículo"),
                  ),
          ],
        ),
      ),
    );
  }
}
