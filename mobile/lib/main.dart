import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'views/login/main_login.dart';
import 'views/cliente/main_cliente.dart';
import 'views/conductor/main_conductor.dart';
import 'services/bloc/notifications_bloc.dart';
import 'services/localNotification/local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase inicializado correctamente");

    // Configurar handler para notificaciones en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inicializar notificaciones locales (requerido antes de mostrar alguna)
    await LocalNotifications.initialize();

  } catch (e) {
    debugPrint("Error al inicializar Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    if (mounted) {
      setState(() {
        _role = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => NotificationsBloc()
            ..add(InitializeNotifications())
            ..add(RequestPermissions()),
        ),
      ],
      child: MaterialApp(
        title: 'LogisticOne',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: _isLoading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _role == null
                ? const MainLogin()
                : _getHomeScreen(_role!),
      ),
    );
  }

  Widget _getHomeScreen(String role) {
    if (role == "cliente") return const MainCliente();
    if (role == "conductor") return const MainConductor();
    return const MainLogin();
  }
}
