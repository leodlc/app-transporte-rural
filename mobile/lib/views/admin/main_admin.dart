import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/login_controller.dart';
// import '../../widgets/custom_bottom_nav.dart'; // Reemplazaremos esto con el BottomNavigationBar estándar y estilizado
import 'conductores_admin.dart';
import 'clientes_admin.dart';
import 'vehiculos_admin.dart';
import 'cooperativas_admin.dart';
import 'admin_styles.dart';

class MainAdmin extends StatefulWidget {
  const MainAdmin({super.key});

  @override
  _MainAdminState createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin> {
  String _nombre = "Cargando...";
  String _email = "Cargando...";
  String _rol = "admin";
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final LoginController _loginController = LoginController();

  // Se añaden títulos para el AppBar dinámico
  final List<String> _pageTitles = const [
    "Gestión de Conductores",
    "Gestión de Clientes",
    "Gestión de Vehículos",
    "Gestión de Cooperativas",
  ];

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Usuario";
      _email = prefs.getString('email') ?? "email@example.com";
      _rol = prefs.getString('role')?.toUpperCase() ?? "ADMIN";
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
      if (route != null) _navigateFromNotification(route);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final route = message.data['route'];
        if (route != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigateFromNotification(route));
        }
      }
    });
  }

  void _navigateFromNotification(String route) {
    final routes = {'conductores': 0, 'clientes': 1, 'vehiculos': 2, 'cooperativas': 3};
    if (routes.containsKey(route)) {
      _onItemTapped(routes[route]!);
    } else {
      debugPrint('Ruta de notificación no reconocida: $route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]), // Título dinámico
        backgroundColor: AdminStyles.primaryColor,
        foregroundColor: AdminStyles.secondaryColor, // Para el color del ícono del drawer y título
      ),
      drawer: _AdminDrawer(
        nombre: _nombre,
        email: _email,
        rol: _rol,
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          _onItemTapped(index);
          Navigator.pop(context); // Cierra el drawer al seleccionar
        },
        onLogout: () => _loginController.logout(context),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AdminStyles.secondaryColor, // Fondo blanco
        selectedItemColor: AdminStyles.accentColor,   // Verde para el ítem activo
        unselectedItemColor: Colors.grey[600],       // Gris para los ítems inactivos
        type: BottomNavigationBarType.fixed,         // Asegura que todos los ítems sean visibles
        elevation: 8.0,
        items: const [
          BottomNavigationBarItem(icon: AdminStyles.conductoresIcon, label: "Conductores"),
          BottomNavigationBarItem(icon: AdminStyles.clientesIcon, label: "Clientes"),
          BottomNavigationBarItem(icon: AdminStyles.vehiculosIcon, label: "Vehículos"),
          BottomNavigationBarItem(icon: AdminStyles.cooperativasIcon, label: "Cooperativas"),
        ],
      ),
    );
  }
}

// WIDGET PERSONALIZADO PARA EL DRAWER
class _AdminDrawer extends StatelessWidget {
  final String nombre;
  final String email;
  final String rol;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onLogout;

  const _AdminDrawer({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AdminDrawerHeader(nombre: nombre, email: email, rol: rol),
          _DrawerItem(
            icon: AdminStyles.conductoresIcon,
            text: "Conductores",
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _DrawerItem(
            icon: AdminStyles.clientesIcon,
            text: "Clientes",
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          _DrawerItem(
            icon: AdminStyles.vehiculosIcon,
            text: "Vehículos",
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
          ),
          _DrawerItem(
            icon: AdminStyles.cooperativasIcon,
            text: "Cooperativas",
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
          const Divider(thickness: 1, indent: 16, endIndent: 16),
          const AboutListTile(
            icon: AdminStyles.aboutIcon,
            applicationName: AdminStyles.appName,
            applicationVersion: AdminStyles.appVersion,
            applicationLegalese: AdminStyles.appLegalese,
            child: Text("Acerca de"),
          ),
          ListTile(
            leading: AdminStyles.logoutIcon,
            title: const Text("Cerrar sesión"),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// WIDGET PARA EL ENCABEZADO DEL DRAWER
class _AdminDrawerHeader extends StatelessWidget {
  final String nombre, email, rol;
  const _AdminDrawerHeader({required this.nombre, required this.email, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      color: AdminStyles.drawerHeaderColor,
      child: Row(
        children: [
          AdminStyles.drawerAvatar,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: AdminStyles.drawerHeaderTitleStyle),
                const SizedBox(height: 4),
                Text(email, style: AdminStyles.drawerHeaderSubtitleStyle),
                Text("Rol: $rol", style: AdminStyles.drawerHeaderSubtitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET PARA CADA ITEM DEL DRAWER, MANEJA EL ESTADO DE SELECCIÓN
class _DrawerItem extends StatelessWidget {
  final Icon icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(text),
      selected: isSelected,
      onTap: onTap,
      selectedTileColor: AdminStyles.accentColor.withValues(alpha: 0.1),
      selectedColor: AdminStyles.accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}