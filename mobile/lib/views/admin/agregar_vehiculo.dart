import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';

class AgregarVehiculo extends StatefulWidget {
  const AgregarVehiculo({super.key});

  @override
  _AgregarVehiculoState createState() => _AgregarVehiculoState();
}

class _AgregarVehiculoState extends State<AgregarVehiculo> {
  final _formKey = GlobalKey<FormState>();
  final AdminController _adminController = AdminController();

  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _rmtController = TextEditingController();

  bool _isLoading = false;

  Future<void> _crearVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final vehiculoData = {
      "marca": _marcaController.text.trim(),
      "modelo": _modeloController.text.trim(),
      "placa": _placaController.text.trim(),
      "rmt": _rmtController.text.trim(),
    };

    bool success = await _adminController.crearVehiculo(vehiculoData);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context, true);
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
    _rmtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar Vehículo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: "Marca"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Ingrese la marca" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: "Modelo"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Ingrese el modelo" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: "Placa"),
                validator: (value) {
                  final placaRegExp = RegExp(r'^[A-Z]{3}-\d{3,4}$');
                  if (value == null || value.isEmpty) {
                    return "Ingrese la placa";
                  } else if (!placaRegExp.hasMatch(value)) {
                    return "Formato inválido (ej: PQW-1568 o PAW-151)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _rmtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "RMT (Número de habilitación operacional)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingrese el número RMT";
                  } else if (value.length > 6) {
                    return "Máximo 6 dígitos permitidos";
                  } else if (!RegExp(r'^\d{1,6}$').hasMatch(value)) {
                    return "Solo se permiten números";
                  }
                  return null;
                },
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
      ),
    );
  }
}
