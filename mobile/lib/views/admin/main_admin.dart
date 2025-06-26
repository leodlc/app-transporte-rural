import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'conductores_admin.dart';
import 'clientes_admin.dart';
import 'vehiculos_admin.dart';
import 'cooperativas_admin.dart';

class MainAdmin extends StatefulWidget {
  const MainAdmin({super.key});

  @override
  _MainAdminState createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin> {
  String nombre = "Cargando...";
  String email = "Cargando...";
  String rol = "admin";
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final LoginController _loginController = LoginController();

  final List<Widget> _screens = const [
    ConductoresAdmin(),
    ClientesAdmin(),
    VehiculosAdmin(),
    CooperativasAdmin(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupNotificationTapHandler();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Usuario";
      email = prefs.getString('email') ?? "email@example.com";
      rol = prefs.getString('role')?.toUpperCase() ?? "ADMIN";
    });
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
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'];
      if (route != null) {
        _navigateFromNotification(route);
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final route = message.data['route'];
        if (route != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateFromNotification(route);
          });
        }
      }
    });
  }

  void _navigateFromNotification(String route) {
    switch (route) {
      case 'conductores':
        _onItemTapped(0);
        break;
      case 'clientes':
        _onItemTapped(1);
        break;
      case 'vehiculos':
        _onItemTapped(2);
        break;
      case 'cooperativas':
        _onItemTapped(3);
        break;
      default:
        debugPrint('Ruta de notificación no reconocida: $route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administrador")),
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
                child: Icon(Icons.person, size: 40, color: Colors.red),
              ),
              decoration: const BoxDecoration(color: Colors.red),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Conductores"),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Clientes"),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text("Vehículos"),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text("Cooperativas"),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const AboutListTile(
              icon: Icon(Icons.info),
              applicationName: "LogisticOne",
              applicationVersion: "1.0.0",
              applicationLegalese: "© 2025 LogisticOne",
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
        children: _screens,
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
            icon: Icon(Icons.group),
            label: "Conductores",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Clientes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "Vehículos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: "Cooperativas",
          ),
        ],
      ),
    );
  }
}
