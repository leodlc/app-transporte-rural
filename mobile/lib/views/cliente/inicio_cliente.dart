import 'package:flutter/material.dart';
import 'package:mobile/controllers/viaje_controller.dart';
import 'package:mobile/main.dart';
import 'package:mobile/views/cliente/viaje_cliente.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cliente_styles.dart';
import 'dart:async';


class InicioCliente extends StatefulWidget {
  const InicioCliente({super.key});

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente> with RouteAware {
  final SocketManager _socketManager = SocketManager.instance;
  final ViajeController _viajeController = ViajeController();

  bool _isLoading = true;
  bool _isConnected = false;
  bool _isCheckingViaje = true;
  String _loadingMessage = 'Conectando...';
  Map<String, dynamic>? _viajeActivo;
  Timer? _viajeCheckTimer;


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // me suscribo al observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() async {
    super.didPopNext();

    // Verificar viaje activo
    await _checkViajeActivo();

    setState(() {
      _isLoading = false;
      _isCheckingViaje = false;
    });
  }

  void _initializeApp() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Inicializando...';
    });

    // Inicializar socket
    await _initializeSocket();

    // Verificar viaje activo
    await _checkViajeActivo();

    // Iniciar verificación periódica de viaje activo
    _viajeCheckTimer?.cancel(); // cancelar si ya existía
    _viajeCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkViajeActivo();
    });

    setState(() {
      _isLoading = false;
      _isCheckingViaje = false;
    });
  }

  Future<void> _initializeSocket() async {
    setState(() {
      _loadingMessage = 'Conectando...';
    });

    try {
      final success = await _socketManager.initialize(userType: 'cliente');

      if (success) {
        _setupConnectionListeners();
        setState(() {
          _isConnected = _socketManager.isConnected;
        });
      } else {
        print('Error al inicializar socket de cliente');
        setState(() {
          _isConnected = false;
        });
        _showErrorSnackBar('Error al conectar. Intenta nuevamente.');
      }
    } catch (e) {
      print('Error en _initializeSocket: $e');
      setState(() {
        _isConnected = false;
      });
      _showErrorSnackBar('Error de conexión.');
    }
  }

  Future<void> _checkViajeActivo() async {
    setState(() {
      _loadingMessage = 'Verificando viajes activos...';
    });

    try {
      String? userId = await _getUserId();

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final viajeData = await _viajeController.verificarViajeActivo(userId);

      if (viajeData != null && viajeData['viajeExistente'] == true) {
        setState(() {
          _viajeActivo = viajeData;
        });
      } else {
        setState(() {
          _viajeActivo = null;
        });
      }
    } catch (e) {
      print('Error al verificar viaje activo: $e');
      setState(() {
        _viajeActivo = null;
      });
      _showErrorSnackBar('Error al verificar viajes activos');
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  void _setupConnectionListeners() {
    _socketManager.on('connect', (_) {
      print('Cliente conectado - actualizando UI');
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });

    _socketManager.on('disconnect', (_) {
      print('Cliente desconectado - actualizando UI');
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    });

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
              _initializeApp();
            },
          ),
        ),
      );
    }
  }

  void _retryConnection() {
    setState(() {
      _isLoading = true;
    });
    _socketManager.reconnect().then((success) {
      setState(() {
        _isLoading = false;
        _isConnected = _socketManager.isConnected;
      });
      if (!success) {
        _showErrorSnackBar('Error al reconectar');
      }
    });
  }

  void _navigateToViaje() {
    if (_viajeActivo != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViajeCliente(
            viajeData: _viajeActivo!['viaje'],
            conductorData: _viajeActivo!['conductorData'],
          ),
        ),
      );
    }
  }

  String _getEstadoViaje() {
    if (_viajeActivo?['viaje']?['estado'] != null) {
      final estado = _viajeActivo!['viaje']['estado'];
      switch (estado) {
        case 'iniciado':
          return 'Viaje iniciado';
        case 'en_curso':
          return 'En curso';
        case 'llegando':
          return 'Conductor llegando';
        default:
          return 'Viaje activo';
      }
    }
    return 'Viaje activo';
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _socketManager.off('connect');
    _socketManager.off('disconnect');
    _viajeCheckTimer?.cancel();
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
          "Inicio",
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
                _retryConnection();
              }
            },
          ),
        ],
      ),
      body: _isLoading || _isCheckingViaje
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : _socketManager.socket != null
          ? _buildMainContent()
          : _buildErrorContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenido principal basado en si hay viaje activo
          if (_viajeActivo != null) ...[
            _buildViajeActivoCard(),
          ] else ...[
            _buildNoViajeContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildViajeActivoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tienes un viaje activo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      _getEstadoViaje(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToViaje,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ver mi viaje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoViajeContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Necesitas un transporte?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Para solicitar un viaje, navega a la pestaña "Transporte" y encuentra el conductor perfecto para ti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Mantén tu ubicación activada para una mejor experiencia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error de conexión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No se pudo establecer conexión con el servidor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar conexión',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}