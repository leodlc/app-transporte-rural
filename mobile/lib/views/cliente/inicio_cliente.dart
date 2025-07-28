import 'package:flutter/material.dart';
import 'package:mobile/ws/SocketManager.dart';
import '../../widgets/agregarUbicacionCliente.dart';
import 'cliente_styles.dart';

class InicioCliente extends StatefulWidget {
  const InicioCliente({super.key});

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente> {
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
      final success = await _socketManager.initialize(userType: 'cliente');

      if (success) {
        _setupConnectionListeners(); // Configurar listeners para eventos de conexión
        setState(() {
          _isLoading = false;
          _isConnected = _socketManager.isConnected;
        });
      } else {
        print('Error al inicializar socket de cliente');
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
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

  void _setupConnectionListeners() {
    // Escuchar evento de conexión
    _socketManager.on('connect', (_) {
      print('Cliente conectado - actualizando UI');
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });

    // Escuchar evento de desconexión
    _socketManager.on('disconnect', (_) {
      print('Cliente desconectado - actualizando UI');
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    });

    // Verificar estado inicial
    setState(() {
      _isConnected = _socketManager.isConnected;
    });
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
    // Remover listeners específicos de esta página
    _socketManager.off('connect');
    _socketManager.off('disconnect');
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
          "Inicio Cliente",
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
              ? Column(
            children: [
              // Widget principal
              Expanded(
                child: AgregarUbicacionCliente(socket: _socketManager.socket!),
              ),
            ],
          )
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