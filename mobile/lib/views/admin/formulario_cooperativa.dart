// formulario_cooperativa.dart

import 'package:flutter/material.dart';
import 'package:mobile/controllers/cooperativa_controller.dart';
import 'admin_styles.dart'; // Asegúrate de que la ruta sea correcta

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
    final coop = widget.cooperativa;
    _nombreController = TextEditingController(text: coop?['nombre'] ?? '');
    _emailController = TextEditingController(text: coop?['email'] ?? '');
    _responsableController = TextEditingController(text: coop?['responsable'] ?? '');
    _ubicacionController = TextEditingController(text: coop?['ubicacion'] ?? '');
    _telefonoController = TextEditingController(text: coop?['telefono'] ?? '');
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

    setState(() => _guardando = true);

    final datos = {
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'responsable': _responsableController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'telefono': _telefonoController.text.trim(),
    };

    bool exito = widget.cooperativa != null
        ? await _cooperativaController.updateCooperativa(widget.cooperativa!['_id'], datos)
        : await _cooperativaController.createCooperativa(datos);

    setState(() => _guardando = false);

    if (mounted) {
      if (exito) {
        widget.onGuardar();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cooperativa != null ? "Cooperativa actualizada" : "Cooperativa registrada"),
            backgroundColor: AdminStyles.accentColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar la cooperativa"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return "Ingrese el email";
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) return "Ingrese un email válido";
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) return "Ingrese el teléfono";
    // Validador flexible para Ecuador (09..., 02..., +593...)
    final phoneRegExp = RegExp(r'^(?:\+593|0)?9\d{8}$|^0\d{8,9}$');
    if (!phoneRegExp.hasMatch(value)) return "Formato de teléfono no válido para Ecuador";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cooperativa != null;

    return Scaffold(
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Cooperativa" : "Nueva Cooperativa"),
        backgroundColor: AdminStyles.primaryColor,
        foregroundColor: AdminStyles.secondaryColor,
      ),
      body: SingleChildScrollView(
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
                  controller: _nombreController,
                  labelText: "Nombre de la Cooperativa",
                  icon: Icons.business_outlined,
                  validator: (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                ),
                const SizedBox(height: 16),
                _CustomTextFormField(
                  controller: _emailController,
                  labelText: "Email de Contacto",
                  icon: Icons.email_outlined,
                  validator: _validarEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _CustomTextFormField(
                  controller: _responsableController,
                  labelText: "Nombre del Responsable",
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? "Ingrese el responsable" : null,
                ),
                const SizedBox(height: 16),
                _CustomTextFormField(
                  controller: _ubicacionController,
                  labelText: "Ubicación (Oficina)",
                  icon: Icons.location_on_outlined,
                  validator: (v) => v!.isEmpty ? "Ingrese la ubicación" : null,
                ),
                const SizedBox(height: 16),
                _CustomTextFormField(
                  controller: _telefonoController,
                  labelText: "Teléfono",
                  icon: Icons.phone_outlined,
                  validator: _validarTelefono,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardarCooperativa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminStyles.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardando
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(esEdicion ? "Actualizar" : "Registrar", style: const TextStyle(fontSize: 16)),
                ),
              ],
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

  const _CustomTextFormField({
    required this.controller,
    required this.labelText,
    required this.icon,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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