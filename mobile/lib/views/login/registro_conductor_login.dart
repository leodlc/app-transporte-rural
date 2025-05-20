import 'package:flutter/material.dart';
import '../../controllers/conductor_controller.dart';
import '../../controllers/cooperativa_controller.dart';
import '../../models/conductor_model.dart';
import '../../models/cooperativa_model.dart';
import 'main_login.dart';

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
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Cooperativa"),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrarConductor,
                child: const Text("Registrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
