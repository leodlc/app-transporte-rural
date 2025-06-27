import 'package:flutter/material.dart';
import '../../controllers/conductor_controller.dart';
import '../../controllers/cooperativa_controller.dart';
import '../../models/conductor_model.dart';
import '../../models/cooperativa_model.dart';
import 'main_login.dart';
import 'login_styles.dart'; // ← Importamos estilos

class RegistroConductorLogin extends StatefulWidget {
  const RegistroConductorLogin({super.key});

  @override
  _RegistroConductorLoginState createState() => _RegistroConductorLoginState();
}

class _RegistroConductorLoginState extends State<RegistroConductorLogin> {
  final _conductorController = ConductorController();
  final _cooperativaController = CooperativaController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();

  List<Cooperativa> _cooperativas = [];
  String? _cooperativaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCooperativas();
  }

  Future<void> _cargarCooperativas() async {
    try {
      List<Map<String, dynamic>> cooperativasJson = await _cooperativaController.fetchAllCooperativas();
      setState(() {
        _cooperativas = cooperativasJson.map((json) => Cooperativa.fromJson(json)).toList();
      });
    } catch (e) {
      print("Error al cargar cooperativas: $e");
    }
  }

  Future<void> _registrarConductor() async {
    if (_formKey.currentState!.validate() && _cooperativaSeleccionada != null) {
      Conductor conductor = Conductor(
        nombre: _nombreController.text,
        username: _usernameController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        password: _passwordController.text,
        vehiculo: null,
        tokenFCM: null,
        activo: true,
        rol: "conductor",
        cooperativa: _cooperativaSeleccionada!,
      );

      bool registrado = await _conductorController.registerConductor(conductor);
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
          const SnackBar(content: Text("Error en el registro. Inténtalo de nuevo.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una cooperativa.")),
      );
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) return "Campo obligatorio";
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value) ? null : "Formato de email inválido";
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) return "Campo obligatorio";
    final telefonoRegex = RegExp(r'^\d{10}$');
    return telefonoRegex.hasMatch(value) ? null : "Teléfono debe tener 10 dígitos numéricos";
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return "Campo obligatorio";
    return value.length < 6 ? "Mínimo 6 caracteres" : null;
  }

  String? _confirmarPassword(String? value) {
    if (value == null || value.isEmpty) return "Confirma la contraseña";
    return value != _passwordController.text ? "Las contraseñas no coinciden" : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Conductor")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: LoginStyles.nombreInput,
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _usernameController,
                decoration: LoginStyles.usernameInputAlt,
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _emailController,
                decoration: LoginStyles.emailInput,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _telefonoController,
                decoration: LoginStyles.telefonoInput,
                keyboardType: TextInputType.phone,
                validator: _validarTelefono,
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _passwordController,
                decoration: LoginStyles.passwordInputAlt,
                obscureText: true,
                validator: _validarPassword,
              ),
              LoginStyles.verticalSpacing,
              TextFormField(
                controller: _confirmarPasswordController,
                decoration: LoginStyles.confirmarPasswordInput,
                obscureText: true,
                validator: _confirmarPassword,
              ),
              LoginStyles.verticalSpacing,
              DropdownButtonFormField<String>(
                decoration: LoginStyles.cooperativaInput,
                value: _cooperativaSeleccionada,
                items: _cooperativas.map((cooperativa) {
                  return DropdownMenuItem<String>(
                    value: cooperativa.id,
                    child: Text(cooperativa.nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _cooperativaSeleccionada = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Selecciona una cooperativa" : null,
              ),
              LoginStyles.verticalSpacing,
              ElevatedButton(
                onPressed: _registrarConductor,
                child: const Text("Registrar", style: LoginStyles.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
