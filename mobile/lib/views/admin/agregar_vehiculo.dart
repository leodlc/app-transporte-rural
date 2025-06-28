// agregar_vehiculo.dart

import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';
import 'admin_styles.dart'; // Asegúrate de que la ruta sea correcta

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

    setState(() => _isLoading = true);

    final vehiculoData = {
      "marca": _marcaController.text.trim(),
      "modelo": _modeloController.text.trim(),
      "placa": _placaController.text.trim().toUpperCase(),
      "rmt": _rmtController.text.trim(),
    };

    bool success = await _adminController.crearVehiculo(vehiculoData);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vehículo creado exitosamente"),
            backgroundColor: AdminStyles.accentColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al crear el vehículo"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: const Text("Agregar Vehículo"),
        backgroundColor: AdminStyles.primaryColor,
        foregroundColor: AdminStyles.secondaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: AdminStyles.cardBoxDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CustomTextFormField(
                    controller: _marcaController,
                    labelText: "Marca",
                    icon: Icons.label_outline,
                    validator: (value) => value == null || value.isEmpty ? "Ingrese la marca" : null,
                  ),
                  const SizedBox(height: 16),
                  _CustomTextFormField(
                    controller: _modeloController,
                    labelText: "Modelo",
                    icon: Icons.directions_car_filled_outlined,
                    validator: (value) => value == null || value.isEmpty ? "Ingrese el modelo" : null,
                  ),
                  const SizedBox(height: 16),
                  _CustomTextFormField(
                    controller: _placaController,
                    labelText: "Placa (Ej: ABC-1234)",
                    icon: Icons.pin_outlined,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      final placaRegExp = RegExp(r'^[A-Z]{3}-\d{3,4}$');
                      if (value == null || value.isEmpty) return "Ingrese la placa";
                      if (!placaRegExp.hasMatch(value.toUpperCase())) return "Formato inválido (ej: ABC-1234)";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _CustomTextFormField(
                    controller: _rmtController,
                    labelText: "RMT (Habilitación operacional)",
                    icon: Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Ingrese el RMT";
                      if (value.length > 6) return "Máximo 6 dígitos";
                      if (!RegExp(r'^\d{1,6}$').hasMatch(value)) return "Solo números";
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _crearVehiculo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminStyles.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                        width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text("Guardar Vehículo", style: TextStyle(fontSize: 16)),
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

// WIDGET REUTILIZABLE PARA CAMPOS DE TEXTO ESTILIZADOS
class _CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _CustomTextFormField({
    required this.controller,
    required this.labelText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AdminStyles.primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminStyles.accentColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}