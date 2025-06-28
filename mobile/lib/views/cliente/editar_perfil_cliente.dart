import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/cliente_controller.dart';
import 'cliente_styles.dart';

class EditarPerfilCliente extends StatefulWidget {
  const EditarPerfilCliente({super.key});

  @override
  State<EditarPerfilCliente> createState() => _EditarPerfilClienteState();
}

class _EditarPerfilClienteState extends State<EditarPerfilCliente> {
  final _formKey = GlobalKey<FormState>();
  final ClienteController _clienteController = ClienteController();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String? _clienteId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    _clienteId = prefs.getString('id');
    setState(() {
      _nombreController.text = prefs.getString('nombre') ?? '';
      _telefonoController.text = prefs.getString('telefono') ?? '';
    });
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate() && _clienteId != null) {
      setState(() => _isSaving = true);

      final actualizado = await _clienteController.updateCliente(_clienteId!, {
        "nombre": _nombreController.text.trim(),
        "telefono": _telefonoController.text.trim(),
      });

      setState(() => _isSaving = false);

      if (actualizado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: ClienteStyles.textSecondary),
      filled: true,
      fillColor: ClienteStyles.surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        borderSide: BorderSide(color: ClienteStyles.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        borderSide: BorderSide(color: ClienteStyles.primaryGreen, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: ClienteStyles.appBarTitle),
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: ClienteStyles.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ClienteStyles.spacing20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Campo: Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: _inputDecoration("Nombre completo", Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El nombre es obligatorio";
                    }
                    if (value.trim().length < 3) {
                      return "Debe tener al menos 3 caracteres";
                    }
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
                      return "Solo letras y espacios";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ClienteStyles.spacing16),

                // Campo: Teléfono
                TextFormField(
                  controller: _telefonoController,
                  decoration: _inputDecoration("Teléfono", Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El teléfono es obligatorio";
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return "Debe tener 10 dígitos";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ClienteStyles.spacing20),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_rounded, size: 20),
                    label: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Guardar'),
                    onPressed: _isSaving ? null : _guardarCambios,
                    style: ClienteStyles.primaryButtonStyle.copyWith(
                      padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      textStyle: MaterialStateProperty.all(
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
