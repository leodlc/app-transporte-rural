import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'perfil_conductor.dart';
import 'solicitudes_conductor.dart';
import '../../widgets/verificacion.dart';
import 'inicio_conductor.dart';
import '../../utils/keep_alive_wrapper.dart';
import '../../controllers/notificacion_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'conductor_styles.dart';

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
  final NotificacionController _notificacionController = NotificacionController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    print("FCM Token obtenido: $token");

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
      rol = prefs.getString('role')?.toUpperCase() ?? "CONDUCTOR";
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ConductorStyles.conductorTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            ConductorStyles.appTitle,
            style: ConductorStyles.appBarTitle,
          ),
          backgroundColor: ConductorStyles.surfaceWhite,
          foregroundColor: ConductorStyles.textPrimary,
          elevation: 0,
          iconTheme: IconThemeData(color: ConductorStyles.textPrimary),
        ),
        drawer: Drawer(
          backgroundColor: ConductorStyles.surfaceWhite,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 180, // altura fija
                decoration: ConductorStyles.drawerHeaderDecoration,
                child: Padding(
                  padding: const EdgeInsets.all(ConductorStyles.spacing16),
                  child: SingleChildScrollView( // <-- envuelve aquí
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.center, // <--- elimina esta línea
                      children: [
                        ConductorStyles.drawerAvatar(
                          initials: nombre.isNotEmpty ? nombre[0] : 'C',
                        ),
                        const SizedBox(height: ConductorStyles.spacing12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            nombre,
                            style: ConductorStyles.drawerHeaderTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        const SizedBox(height: ConductorStyles.spacing8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: ConductorStyles.drawerHeaderSubtitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rol: $rol",
                                style: ConductorStyles.drawerHeaderSubtitle.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ConductorStyles.spacing12,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: ConductorStyles.spacing8),
                    ListTile(
                      leading: ConductorStyles.inicioIcon,
                      title: Text(
                        "Inicio",
                        style: ConductorStyles.drawerItemText,
                      ),
                      selected: _selectedIndex == 0,
                      selectedColor: ConductorStyles.selectedItemColor,
                      selectedTileColor: ConductorStyles.selectedItemColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ConductorStyles.spacing16,
                        vertical: ConductorStyles.spacing4, // Reducido de spacing8
                      ),
                      onTap: () {
                        _onItemTapped(0);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: ConductorStyles.spacing4), // Reducido de spacing8
                    ListTile(
                      leading: const Icon(Icons.assignment_rounded, size: 24),
                      title: Text(
                        "Solicitudes",
                        style: ConductorStyles.drawerItemText,
                      ),
                      selected: _selectedIndex == 1,
                      selectedColor: ConductorStyles.selectedItemColor,
                      selectedTileColor: ConductorStyles.selectedItemColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ConductorStyles.spacing16,
                        vertical: ConductorStyles.spacing4, // Reducido de spacing8
                      ),
                      onTap: () {
                        _onItemTapped(1);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: ConductorStyles.spacing4), // Reducido de spacing8
                    ListTile(
                      leading: ConductorStyles.configuracionIcon,
                      title: Text(
                        "Configuración",
                        style: ConductorStyles.drawerItemText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ConductorStyles.spacing16,
                        vertical: ConductorStyles.spacing4, // Reducido de spacing8
                      ),
                      onTap: () {},
                    ),
                    const SizedBox(height: ConductorStyles.spacing12), // Reducido de spacing16
                    Divider(
                      color: ConductorStyles.dividerColor,
                      thickness: 1,
                    ),
                    const SizedBox(height: ConductorStyles.spacing4), // Reducido de spacing8
                    ListTile(
                      leading: ConductorStyles.aboutIcon,
                      title: Text(
                        "Acerca de",
                        style: ConductorStyles.drawerItemText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ConductorStyles.spacing16,
                        vertical: ConductorStyles.spacing4, // Reducido de spacing8
                      ),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: ConductorStyles.appName,
                          applicationVersion: ConductorStyles.appVersion,
                          applicationLegalese: ConductorStyles.appLegalese,
                          applicationIcon: Icon(
                            Icons.drive_eta_rounded,
                            size: 48,
                            color: ConductorStyles.primaryColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: ConductorStyles.spacing4), // Reducido de spacing8
                    ListTile(
                      leading: ConductorStyles.logoutIcon,
                      title: Text(
                        "Cerrar sesión",
                        style: ConductorStyles.drawerItemText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: ConductorStyles.spacing16,
                        vertical: ConductorStyles.spacing4, // Reducido de spacing8
                      ),
                      onTap: () => _loginController.logout(context),
                    ),
                    const SizedBox(height: ConductorStyles.spacing8), // Padding final
                  ],
                ),
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          children: const [
            KeepAliveWrapper(child: InicioConductor()),
            KeepAliveWrapper(child: SolicitudesConductor()),
            KeepAliveWrapper(child: PerfilConductor()),
          ],
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: ConductorStyles.conductorTheme.bottomNavigationBarTheme,
          ),
          child: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Inicio",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: "Solicitudes",
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
}