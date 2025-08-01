import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/controllers/viaje_controller.dart';
import 'package:mobile/main.dart';
import 'package:mobile/views/conductor/viaje/viaje_conductor.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cliente/cliente_styles.dart';

class InicioConductor extends StatefulWidget {
  const InicioConductor({super.key});

  @override
  State<InicioConductor> createState() => _InicioConductorState();
}

class _InicioConductorState extends State<InicioConductor> with RouteAware {
  final SocketManager _socketManager = SocketManager.instance;
  final ViajeController _viajeController = ViajeController();

  bool _isLoading = true;
  bool _isConnected = false;
  bool _isCheckingViaje = true;
  String _loadingMessage = 'Conectando...';
  String? _usuarioId;
  Map<String, dynamic>? _viajeActivo;
  StreamSubscription<Position>? _posicionSub;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() async {
    super.didPopNext();
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

    await _initializeSocket();
    await _checkViajeActivo();

    setState(() {
      _isLoading = false;
      _isCheckingViaje = false;
    });
  }

  Future<void> _initializeSocket() async {
    try {
      final success = await _socketManager.initialize(userType: 'conductor');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id');

      if (!mounted) return;
      setState(() {
        _usuarioId = userId;
      });

      if (success) {
        _setupConnectionListeners();
        await _activarUbicacion();
        setState(() {
          _isConnected = true;
        });
      } else {
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

  void _setupConnectionListeners() {
    _socketManager.on('connect', (_) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socketManager.on('disconnect', (_) {
      if (mounted) setState(() => _isConnected = false);
    });

    setState(() {
      _isConnected = _socketManager.isConnected;
    });
  }

  Future<void> _checkViajeActivo() async {
    setState(() {
      _loadingMessage = 'Verificando viaje activo...';
    });

    try {
      final userId = _usuarioId ?? await _getUserId();

      if (userId == null) throw Exception('No se pudo obtener el ID');

      final viajeData = await _viajeController.verificarViajeActivo(userId);

      setState(() {
        _viajeActivo = (viajeData != null && viajeData['viajeExistente'] == true)
            ? viajeData
            : null;
      });
    } catch (e) {
      print('Error al verificar viaje activo: $e');
      _showErrorSnackBar('Error al verificar viaje activo');
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  void _navigateToViaje() {
    if (_viajeActivo != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViajeConductor(
            viajeData: _viajeActivo!['viaje'],
            clienteData: _viajeActivo!['clienteData'],
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
          return 'Llegando al cliente';
        default:
          return 'Viaje activo';
      }
    }
    return 'Viaje activo';
  }

  void _iniciarEscuchaPosicion() {
    _posicionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position posicion) {
      _socketManager.emit("ubicacion:actualizar", {
        "conductorId": _usuarioId,
        "lat": posicion.latitude,
        "lng": posicion.longitude,
      });
    });
  }

  Future<void> _activarUbicacion() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso de ubicación denegado")),
      );
      return;
    }

    final posicion = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));

    _socketManager.emit("ubicacion:actualizar", {
      "conductorId": _usuarioId,
      "lat": posicion.latitude,
      "lng": posicion.longitude,
    });

    _iniciarEscuchaPosicion();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ubicacionActiva', true);
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
            onPressed: _initializeApp,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _posicionSub?.cancel();
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
        title: Text("Inicio Conductor", style: ClienteStyles.appBarTitle),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!_isConnected) {
                _initializeApp();
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
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_loadingMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_viajeActivo != null)
            _buildViajeActivoCard()
          else
            _buildNoViajeContent()
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
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 40,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Sin solicitudes activas?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Aún no tienes viajes asignados. Mantente disponible y conectado para recibir nuevas solicitudes.',
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Consejo: Asegúrate de tener conexión activa y ubicación encendida para recibir solicitudes.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
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
}
