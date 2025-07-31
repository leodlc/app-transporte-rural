import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/bloc/notifications_bloc.dart';
import 'info_solicitud.dart';

class SolicitudesConductor extends StatefulWidget {
  const SolicitudesConductor({super.key});

  @override
  _SolicitudesConductorState createState() => _SolicitudesConductorState();
}

class _SolicitudesConductorState extends State<SolicitudesConductor> {
  late NotificationsBloc _notificationsBloc;
  final SocketManager _socketManager = SocketManager.instance;

  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = true;
  bool _isConnected = false;

  String? _conductorId;
  double? _conductorLatitud;
  double? _conductorLongitud;

  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = context.read<NotificationsBloc>();
    _isConnected = _socketManager.socket != null;
    _inicializarSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notificationsBloc.add(RequestPermissions());
      await _obtenerConductorId();
      await _iniciarSeguimientoUbicacion();
      if (_conductorId != null) {
        _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró ID de conductor')),
        );
      }
    });
  }

  void _inicializarSocket() {
    _socketManager.on('solicitud:lista', (data) {
      try {
        if (data is List) {
          setState(() {
            _solicitudes = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        } else {
          throw Exception('Data no es una lista');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint('Error al procesar solicitudes: $e');
      }
    });

    _socketManager.on('solicitud:nueva', (data) {
      if (data is Map<String, dynamic>) {
        setState(() => _solicitudes.add(data));
      }
    });
  }

  Future<void> _obtenerConductorId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _conductorId = prefs.getString('id');
    });
  }

  /// 1. Pide permisos, 2. obtiene posición inicial, 3. escucha cambios en tiempo real
  Future<void> _iniciarSeguimientoUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    // Posición inicial
    final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));
    setState(() {
      _conductorLatitud = pos.latitude;
      _conductorLongitud = pos.longitude;
    });

    // Stream para actualizaciones en tiempo real
    _positionSub = Geolocator
        .getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // cada 10 metros
      ),
    )
        .listen((Position updated) {
      setState(() {
        _conductorLatitud = updated.latitude;
        _conductorLongitud = updated.longitude;
      });
    });
  }

  String _formatearDistancia(double km) {
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, String> _obtenerInfoCliente(Map<String, dynamic> s) {
    if (s['clienteId'] is Map<String, dynamic>) {
      final c = s['clienteId'] as Map<String, dynamic>;
      return {
        'nombre': c['nombre']?.toString() ?? 'Sin nombre',
        'telefono': c['telefono']?.toString() ?? 'Sin teléfono',
      };
    }
    return {
      'nombre': s['clienteNombre']?.toString() ??
          s['nombre']?.toString() ??
          'Sin nombre',
      'telefono': s['clienteTelefono']?.toString() ??
          s['telefono']?.toString() ??
          'Sin teléfono',
    };
  }

  Future<Map<String, dynamic>> _obtenerInfoOrigen(
      Map<String, dynamic> s) async {
    final o = s['origen'] as Map<String, dynamic>?;
    if (_conductorLatitud == null || o == null) {
      return {'distancia': null, 'nombre': o?['nombre'], 'direccion': o?['direccion']};
    }
    final latO = _toDouble(o['latitud']);
    final lngO = _toDouble(o['longitud']);
    if (latO == null || lngO == null) {
      return {'distancia': null, 'nombre': o['nombre'], 'direccion': o['direccion']};
    }

    final meters = await Geolocator.distanceBetween(
      _conductorLatitud!, _conductorLongitud!, latO, lngO,
    );
    final km = meters / 1000;
    return {
      'distancia': _formatearDistancia(km),
      'nombre': o['nombre']?.toString(),
      'direccion': o['direccion']?.toString(),
    };
  }

  Future<Map<String, dynamic>> _obtenerInfoDestino(
      Map<String, dynamic> s) async {
    final d = s['destino'] as Map<String, dynamic>?;
    final o = s['origen'] as Map<String, dynamic>?;
    if (d == null || o == null) return {'distancia': null, 'nombre': d?['nombre'], 'direccion': d?['direccion']};

    final latO = _toDouble(o['latitud']);
    final lngO = _toDouble(o['longitud']);
    final latD = _toDouble(d['latitud']);
    final lngD = _toDouble(d['longitud']);
    if (latO == null || lngO == null || latD == null || lngD == null) {
      return {'distancia': null, 'nombre': d['nombre'], 'direccion': d['direccion']};
    }

    final meters = await Geolocator.distanceBetween(latO, lngO, latD, lngD);
    final km = meters / 1000;
    return {
      'distancia': _formatearDistancia(km),
      'nombre': d['nombre']?.toString(),
      'direccion': d['direccion']?.toString(),
    };
  }

  Future<Widget> _buildSolicitudItemAsync(Map<String, dynamic> s, int idx) async {
    final cli  = _obtenerInfoCliente(s);
    final ori  = await _obtenerInfoOrigen(s);
    final des  = await _obtenerInfoDestino(s);
    final dOri = ori['distancia'];
    final dDes = des['distancia'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InfoSolicitud(solicitud: s)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 20,
                child: Text('${idx + 1}', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cli['nombre']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Row(children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(cli['telefono']!, style: TextStyle(color: Colors.grey[600])),
                        ])
                      ])),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ]),
            if (ori['nombre'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.my_location, Colors.green, 'Origen',
                  ori['nombre'], ori['direccion'], "Distancia a origen: ", dOri),
            ],
            if (des['nombre'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _buildLocationRow(Icons.location_on, Colors.red, 'Destino',
                  des['nombre'], des['direccion'], "Distancia Origen/Destino: ", dDes),
            ],
            if (des['nombre'] == null)
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text('Sin destino especificado',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic)),
                ],
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color color, String title,
      String? nombre, String? direccion, String mensaje,
      [String? distancia]) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          const SizedBox(height: 2),
          if (nombre != null)
            Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (direccion != null)
            Text(direccion,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          if (distancia != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.route_outlined, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(mensaje, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(distancia, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ]),
      )
    ]);
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listener: (context, state) {
        if (state is NotificationsPermissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permisos de notificaciones concedidos')));
        } else if (state is NotificationsPermissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permisos de notificaciones denegados')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solicitudes pendientes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.green),
              onPressed: () {
                if (_conductorId != null) {
                  setState(() => _isLoading = true);
                  _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});
                }
              },
            ),
            IconButton(
              icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red),
              onPressed: () {
                if (!_isConnected) {
                  _socketManager.reconnect().then((_) {
                    setState(() => _isConnected = _socketManager.isConnected);
                  });
                }
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _solicitudes.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No hay solicitudes pendientes',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _solicitudes.length,
          itemBuilder: (ctx, i) => FutureBuilder<Widget>(
            future: _buildSolicitudItemAsync(_solicitudes[i], i),
            builder: (c, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return ListTile(
                  title: Text('Error solicitud #$i'),
                  subtitle: Text(snap.error.toString()),
                );
              }
              return snap.data!;
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _socketManager.off('solicitud:lista');
    _socketManager.off('solicitud:nueva');
    super.dispose();
  }
}
