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
import 'cliente_styles.dart';

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

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    String initials = '';

    if (names.isNotEmpty) {
      initials = names[0][0].toUpperCase();
      if (names.length > 1) {
        initials += names[names.length - 1][0].toUpperCase();
      }
    }

    return initials.isEmpty ? 'U' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: Text(
          ClienteStyles.appTitle,
          style: ClienteStyles.appBarTitle,
        ),
        iconTheme: IconThemeData(color: ClienteStyles.textPrimary),
      ),
      drawer: Drawer(
        backgroundColor: ClienteStyles.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(ClienteStyles.radiusLarge),
            bottomRight: Radius.circular(ClienteStyles.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              decoration: ClienteStyles.drawerHeaderDecoration,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(ClienteStyles.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClienteStyles.drawerAvatar(
                        initials: _getInitials(nombre),
                      ),
                      SizedBox(height: ClienteStyles.spacing16),
                      Text(
                        nombre,
                        style: ClienteStyles.drawerHeaderTitle,
                      ),
                      SizedBox(height: ClienteStyles.spacing8),
                      Text(
                        email,
                        style: ClienteStyles.drawerHeaderSubtitle,
                      ),
                      SizedBox(height: ClienteStyles.spacing8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ClienteStyles.spacing12,
                          vertical: ClienteStyles.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: ClienteStyles.surfaceWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(ClienteStyles.radiusCircular),
                        ),
                        child: Text(
                          rol,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ClienteStyles.surfaceWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Items del drawer
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: ClienteStyles.spacing16,
                ),
                children: [
                  _buildDrawerItem(
                    icon: ClienteStyles.inicioIcon,
                    title: "Inicio",
                    isSelected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: ClienteStyles.transporteIcon,
                    title: "Transporte",
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      _onItemTapped(1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: ClienteStyles.perfilIcon,
                    title: "Perfil",
                    isSelected: _selectedIndex == 2,
                    onTap: () {
                      _onItemTapped(2);
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClienteStyles.spacing20,
                      vertical: ClienteStyles.spacing8,
                    ),
                    child: Divider(color: ClienteStyles.dividerColor),
                  ),
                  _buildDrawerItem(
                    icon: ClienteStyles.aboutIcon,
                    title: "Acerca de",
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: ClienteStyles.appName,
                        applicationVersion: ClienteStyles.appVersion,
                        applicationLegalese: ClienteStyles.appLegalese,
                        applicationIcon: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: ClienteStyles.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ClienteStyles.radiusLarge),
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            size: 40,
                            color: ClienteStyles.primaryGreen,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botón de cerrar sesión
            Container(
              padding: const EdgeInsets.all(ClienteStyles.spacing16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ClienteStyles.dividerColor),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _loginController.logout(context),
                  icon: ClienteStyles.logoutIcon,
                  label: const Text("Cerrar sesión"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClienteStyles.errorColor,
                    foregroundColor: ClienteStyles.surfaceWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: ClienteStyles.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          const KeepAliveWrapper(child: InicioCliente()),
          const KeepAliveWrapper(child: TransporteCliente()),
          KeepAliveWrapper(
            child: PerfilCliente(
              onPerfilActualizado: () async {
                await _loadUserData();
                if (mounted) setState(() {}); // 👈 fuerza actualización del drawer
              },
            ),
          ),
        ],

        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ClienteStyles.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Inicio",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_rounded),
                label: "Transporte",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "Perfil",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required Icon icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ClienteStyles.spacing12,
        vertical: ClienteStyles.spacing8 / 2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? ClienteStyles.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          icon.icon,
          color: isSelected
              ? ClienteStyles.primaryGreen
              : ClienteStyles.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: ClienteStyles.drawerItemText.copyWith(
            color: isSelected
                ? ClienteStyles.primaryGreen
                : ClienteStyles.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        ),
      ),
    );
  }
}