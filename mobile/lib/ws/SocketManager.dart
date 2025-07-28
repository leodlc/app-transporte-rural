import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketManager {
  static SocketManager? _instance;
  IO.Socket? _socket;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentUserType;

  // Constructor privado
  SocketManager._();

  // Getter para obtener la instancia única
  static SocketManager get instance {
    _instance ??= SocketManager._();
    return _instance!;
  }

  // Getter para obtener el socket
  IO.Socket? get socket => _socket;

  // Getter para verificar si está inicializado
  bool get isInitialized => _isInitialized;

  // Getter para verificar si está conectado
  bool get isConnected => _socket?.connected ?? false;

  // Inicializar el socket con el tipo de usuario
  Future<bool> initialize({required String userType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id');

      if (userId == null) {
        print('ID de usuario no encontrado en SharedPreferences');
        return false;
      }

      // Si ya está inicializado con los mismos parámetros, no hacer nada
      if (_isInitialized &&
          _currentUserId == userId &&
          _currentUserType == userType &&
          _socket != null &&
          _socket!.connected) {
        print('Socket ya inicializado y conectado para $userType: $userId');
        return true;
      }

      // Desconectar socket anterior si existe
      await disconnect();

      _currentUserId = userId;
      _currentUserType = userType;

      // Crear nuevo socket
      _socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'reconnection': true,  // Permitir reconexiones automáticas
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'timeout': 5000,
        'query': <String, String>{
          'tipo': userType,
          'id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString()
        }
      });

      // Configurar listeners básicos
      _setupBasicListeners();

      // Conectar
      _socket!.connect();

      _isInitialized = true;
      print('Socket inicializado para $userType: $userId');
      return true;

    } catch (e) {
      print('Error al inicializar socket: $e');
      return false;
    }
  }

  // Reconectar con los mismos parámetros
  Future<bool> reconnect() async {
    if (_currentUserType == null) {
      print('No se puede reconectar: tipo de usuario no definido');
      return false;
    }

    return await initialize(userType: _currentUserType!);
  }

  // Configurar listeners básicos
  void _setupBasicListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('Socket $_currentUserType conectado exitosamente');
      print('Socket ID: ${_socket!.id}');
      print('Query enviado: tipo=$_currentUserType, id=$_currentUserId');
    });

    _socket!.onDisconnect((_) {
      print('Socket $_currentUserType desconectado');
    });

    _socket!.onConnectError((error) {
      print('Error de conexión $_currentUserType: $error');
    });

    _socket!.onReconnect((_) {
      print('Socket $_currentUserType reconectado');
    });

    _socket!.onReconnectError((error) {
      print('Error de reconexión $_currentUserType: $error');
    });
  }

  // Agregar listener personalizado
  void on(String event, dynamic callback) {
    _socket?.on(event, callback);
  }

  // Remover listener
  void off(String event, [dynamic callback]) {
    _socket?.off(event, callback);
  }

  // Emitir evento
  void emit(String event, [dynamic data]) {
    if (_socket?.connected == true) {
      _socket!.emit(event, data);
    } else {
      print('Socket no conectado. No se puede emitir evento: $event');
    }
  }

  // Desconectar socket
  Future<void> disconnect() async {
    if (_socket != null) {
      if (_socket!.connected) {
        _socket!.disconnect();
      }
      _socket!.clearListeners();
      _socket!.dispose();
      _socket = null;
    }
    _isInitialized = false;
    print('Socket desconectado y limpiado');
  }

  // Método para destruir completamente la instancia (útil para testing)
  static void destroyInstance() {
    if (_instance != null) {
      _instance!.disconnect();
      _instance = null;
    }
  }
}