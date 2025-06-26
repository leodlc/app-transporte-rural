import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localNotification/local_notifications.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // Extraer datos de la notificación
  final title = message.notification?.title ?? message.data['title'] ?? '';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  
  if (title.isNotEmpty && body.isNotEmpty) {
    final id = Random().nextInt(100000);
    await LocalNotifications.showNotification(
      id: id,
      title: title,
      body: body,
      payload: message.data.toString(),
    );
  }
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(NotificationsInitial()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<RequestPermissions>(_onRequestPermissions);
    on<TokenReceived>(_onTokenReceived);
    on<NotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    try {
      // Inicializar notificaciones locales
      await LocalNotifications.initialize();

      // Configurar listeners para notificaciones
      _setupFirebaseListeners();

      emit(const NotificationsInitialized());
    } catch (e) {
      print('Error inicializando notificaciones: $e');
      emit(NotificationsInitial());
    }
  }

  Future<void> _onRequestPermissions(
    RequestPermissions event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      // Solicitar permisos de Firebase
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Solicitar permisos de notificaciones locales
      final localPermissionGranted = await LocalNotifications.requestPermissions();

      if (settings.authorizationStatus == AuthorizationStatus.authorized && 
          localPermissionGranted) {
        emit(NotificationsPermissionGranted());
        
        // Obtener token FCM
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          add(TokenReceived(token));
        }
      } else {
        emit(NotificationsPermissionDenied());
      }
    } catch (e) {
      print('Error solicitando permisos: $e');
      emit(NotificationsPermissionDenied());
    }
  }

  Future<void> _onTokenReceived(
    TokenReceived event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      // Guardar token en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', event.token);
      
      print('FCM Token: ${event.token}');
      
      emit(NotificationsInitialized(token: event.token));
    } catch (e) {
      print('Error guardando token: $e');
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final id = Random().nextInt(100000);
      await LocalNotifications.showNotification(
        id: id,
        title: event.title,
        body: event.body,
        payload: event.data.toString(),
      );

      emit(NotificationDisplayed(title: event.title, body: event.body));
    } catch (e) {
      print('Error mostrando notificación: $e');
    }
  }

  void _setupFirebaseListeners() {
    // Escuchar notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      
      final title = message.notification?.title ?? message.data['title'] ?? '';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      
      if (title.isNotEmpty && body.isNotEmpty) {
        add(NotificationReceived(
          title: title,
          body: body,
          data: message.data,
        ));
      }
    });

    // Escuchar cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
      // Aquí puedes navegar a una pantalla específica
    });

    // Listener para actualización de token
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      add(TokenReceived(newToken));
    });
  }

  // Método para obtener el token actual
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }
}