import 'package:flutter/material.dart';
import 'package:mobile/views/admin/cooperativas_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/notificacion_controller.dart';
import 'clientes_admin.dart';
import 'conductores_admin.dart';
import 'vehiculos_admin.dart'; // ← Importar la nueva pantalla de Vehículos

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
/*   final NotificacionController _notificacionController = NotificacionController(); */

  final List<Widget> _screens = [
    const ConductoresAdmin(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    /* _actualizarTokenFCM(); */
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Usuario";
      email = prefs.getString('email') ?? "email@example.com";
      rol = prefs.getString('role')?.toUpperCase() ?? "ADMIN";
    });
  }

  /* Future<void> _actualizarTokenFCM() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    if (userId != null) {
      await _notificacionController.actualizarTokenAdmin(userId);
    }
  } */

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
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person), // Icono de vehículo
              title: const Text("Clientes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientesAdmin(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car), // Icono de vehículo
              title: const Text("Vehículos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VehiculosAdmin(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance), // Icono de vehículo
              title: const Text("Cooperativas"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CooperativasAdmin(),
                  ),
                );
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
      )
    );
  }
}
