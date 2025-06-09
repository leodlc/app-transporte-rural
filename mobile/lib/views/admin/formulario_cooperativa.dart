import 'package:flutter/material.dart';
import 'package:mobile/controllers/cooperativa_controller.dart';
import '../../controllers/admin_controller.dart';

class FormularioCooperativa extends StatefulWidget {
  final Map<String, dynamic>? cooperativa;
  final VoidCallback onGuardar;

  const FormularioCooperativa({
    super.key,
    this.cooperativa,
    required this.onGuardar,
  });

  @override
  _FormularioCooperativaState createState() => _FormularioCooperativaState();
}

class _FormularioCooperativaState extends State<FormularioCooperativa> {
  final _formKey = GlobalKey<FormState>();
  final CooperativaController _cooperativaController = CooperativaController();

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _responsableController;
  late TextEditingController _ubicacionController;
  late TextEditingController _telefonoController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cooperativa?['nombre'] ?? '');
    _emailController = TextEditingController(text: widget.cooperativa?['email'] ?? '');
    _responsableController = TextEditingController(text: widget.cooperativa?['responsable'] ?? '');
    _ubicacionController = TextEditingController(text: widget.cooperativa?['ubicacion'] ?? '');
    _telefonoController = TextEditingController(text: widget.cooperativa?['telefono'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _responsableController.dispose();
    _ubicacionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCooperativa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    final nuevaCoop = {
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'responsable': _responsableController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
    };

    bool exito = false;

    if (widget.cooperativa != null) {
      final id = widget.cooperativa!['_id'];
      exito = await _cooperativaController.updateCooperativa(id, nuevaCoop);
    } else {
      exito = await _cooperativaController.createCooperativa(nuevaCoop);
    }

    setState(() {
      _guardando = false;
    });

    if (exito) {
      widget.onGuardar();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar cooperativa")),
      );
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Ingrese el email";
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return "Ingrese un email válido";
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return "Ingrese el teléfono";
    }
    final phoneRegExp = RegExp(r'^\+?\d{10}$');
    if (!phoneRegExp.hasMatch(value)) {
      return "Ingrese un teléfono válido";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cooperativa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Cooperativa" : "Nueva Cooperativa"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) => value!.isEmpty ? "Ingrese el nombre" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: _validarEmail,
              ),
              TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(labelText: "Responsable"),
                validator: (value) => value!.isEmpty ? "Ingrese el responsable" : null,
              ),
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: "Ubicación"),
                validator: (value) => value!.isEmpty ? "Ingrese la ubicación" : null,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone,
                validator: _validarTelefono,
              ),
              const SizedBox(height: 20),
              _guardando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarCooperativa,
                      child: Text(esEdicion ? "Actualizar" : "Registrar"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
