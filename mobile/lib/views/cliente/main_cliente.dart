import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../controllers/cliente_controller.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'perfil_cliente.dart';
import 'transporte_cliente.dart';
import '../../widgets/verificacion.dart';
import 'inicio_cliente.dart';
import '../../utils/keep_alive_wrapper.dart';
import '../../controllers/notificacion_controller.dart';

class MainCliente extends StatefulWidget {
  const MainCliente({super.key});

  @override
  _MainClienteState createState() => _MainClienteState();
}

class _MainClienteState extends State<MainCliente> {
  String nombre = "Cargando...";
  String email = "Cargando...";
  String rol = "cliente";
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final LoginController _loginController = LoginController();
  final NotificacionController _notificacionController = NotificacionController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupNotificationTapHandler();
    _obtenerYGuardarTokenFCM().then((_) => _registrarTokenFCM());

  }

  Future<void> _registrarTokenFCM() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getString('id');
    final rol = prefs.getString('role');
    final token = prefs.getString('fcm_token');

    if (usuarioId != null && rol != null && token != null) {
      try {
        await _notificacionController.registrarTokenFCM(
          usuarioId: usuarioId,
          rol: rol,
          tokenFCM: token,
        );
        print("Token FCM registrado exitosamente para $rol");
      } catch (e) {
        print(" Error registrando token FCM: $e");
      }
    }
  }

  Future<void> _obtenerYGuardarTokenFCM() async {
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM Token obtenido (cliente): $token");

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }
  }


  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Usuario";
      email = prefs.getString('email') ?? "email@example.com";
      rol = prefs.getString('role')?.toUpperCase() ?? "CLIENTE";
    });

    bool emailVerificado = prefs.getBool('emailVerificado') ?? false;

    if (!emailVerificado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showVerificationDialog(context, email);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _setupNotificationTapHandler() {
    // App ya abierta y usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'];
      if (route != null) {
        _navigateFromNotification(route);
      }
    });

    // App cerrada y se abre desde notificación
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final route = message.data['route'];
        if (route != null) {
          // Ejecutar después del primer frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateFromNotification(route);
          });
        }
      }
    });
  }

  void _navigateFromNotification(String route) {
    switch (route) {
      case 'inicio':
        _onItemTapped(0);
        break;
      case 'transporte':
        _onItemTapped(1);
        break;
      case 'perfil':
        _onItemTapped(2);
        break;
      default:
        debugPrint('Ruta de notificación no reconocida: $route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cliente")),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(nombre),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email),
                  Text(
                    "Rol: $rol",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text("Transporte"),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Configuración"),
              onTap: () {}, // Puedes enlazar una pantalla de configuración aquí
            ),
            const Divider(),
            const AboutListTile(
              icon: Icon(Icons.info),
              applicationName: "Transporte rural",
              applicationVersion: "1.0.0",
              applicationLegalese: "© 2025 TransporteRural",
              child: Text("Acerca de"),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Cerrar sesión"),
              onTap: () => _loginController.logout(context),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: const [
          KeepAliveWrapper(child: InicioCliente()),
          KeepAliveWrapper(child: TransporteCliente()),
          KeepAliveWrapper(child: PerfilCliente()),
        ],
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: "Transporte",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
