import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'perfil_conductor.dart';
import 'solicitudes_conductor.dart';

class MainConductor extends StatefulWidget {
  const MainConductor({super.key});

  @override
  _MainConductorState createState() => _MainConductorState();
}

class _MainConductorState extends State<MainConductor> {
  String nombre = "Cargando...";
  String email = "Cargando...";
  String rol = "conductor";
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final LoginController _loginController = LoginController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombre = prefs.getString('nombre') ?? "Usuario";
      email = prefs.getString('email') ?? "email@example.com";
      rol = prefs.getString('role')?.toUpperCase() ?? "CONDUCTOR";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conductor")),
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
              title: const Text("Solicitudes"),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Configuración"),
              onTap: () {},
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
          SolicitudesConductor(),
          PerfilConductor(),
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
            icon: Icon(Icons.assignment),
            label: "Solicitudes",
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
