import 'package:flutter/material.dart';
import 'package:mobile/ws/SocketManager.dart';
import '../../widgets/agregarUbicacion.dart';
import '../cliente/cliente_styles.dart';

class InicioConductor extends StatefulWidget {
  const InicioConductor({super.key});

  @override
  State<InicioConductor> createState() => _InicioConductorState();
}

class _InicioConductorState extends State<InicioConductor> {
  final SocketManager _socketManager = SocketManager.instance;
  bool _isLoading = true;
  bool _isConnected = false; // Estado local para la conexión

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() async {
    try {
      final success = await _socketManager.initialize(userType: 'conductor');

      if (success) {
        setState(() {
          _isLoading = false;
          _isConnected = true;
        });
      } else {
        // Manejar error de inicialización
        print('Error al inicializar socket de conductor');
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
        // Opcional: mostrar mensaje de error al usuario
        _showErrorSnackBar('Error al conectar. Intenta nuevamente.');
      }
    } catch (e) {
      print('Error en _initializeSocket: $e');
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
      _showErrorSnackBar('Error de conexión.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeSocket();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    // No necesitas hacer dispose del socket aquí ya que es un singleton
    // El socket permanecerá activo para otras pantallas que lo necesiten
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: Text(
          "Inicio Conductor",
          style: ClienteStyles.appBarTitle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!_isConnected) {
                setState(() {
                  _isLoading = true;
                });
                _socketManager.reconnect().then((success) {
                  setState(() {
                    _isLoading = false;
                    _isConnected = _socketManager.isConnected;
                  });
                  if (!success) {
                    _showErrorSnackBar('Error al reconectar ');
                  }
                });
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ClienteStyles.spacing16),
          child: _isLoading
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Conectando...'),
            ],
          )
              : _socketManager.socket != null
              ? AgregarUbicacion(socket: _socketManager.socket!)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error de conexión',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _initializeSocket();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}