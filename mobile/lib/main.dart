import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/login/main_login.dart';
import 'controllers/login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'views/admin/main_admin.dart';
import 'views/cliente/main_cliente.dart';
import 'views/conductor/main_conductor.dart';



Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Asegura la inicialización de Flutter

  //await dotenv.load(fileName: "assets/.env"); // Cargar variables de entorno

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase inicializado correctamente");
  } catch (e) {
    debugPrint("Error al inicializar Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _role;
  bool _isLoading = true; // Para manejar el estado de carga

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');

    if (mounted) {
      setState(() {
        _role = role;
        _isLoading = false; // La carga terminó
      });

      
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogisticOne',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _role == null
              ? const MainLogin()
              : _getHomeScreen(_role!),
    );
  }

  Widget _getHomeScreen(String role) {
    if (role == "cliente") return const MainCliente();
    if (role == "conductor") return const MainConductor();
    return const MainLogin(); // En caso de que haya un error
  }
}