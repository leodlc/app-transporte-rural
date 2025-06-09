import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'perfil_cliente.dart';
import 'transporte_cliente.dart';
import '../../widgets/verificacion.dart';


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
  final ClienteController _clienteController = ClienteController();

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
    rol = prefs.getString('role')?.toUpperCase() ?? "CLIENTE";
  });

  // Aquí decides cuándo mostrar el diálogo, ejemplo si no está verificado
  bool emailVerificado = prefs.getBool('emailVerificado') ?? false;

  if (!emailVerificado) {
    // Esperar un frame para evitar error "setState durante build"
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
          TransporteCliente(),
          PerfilCliente(),
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
