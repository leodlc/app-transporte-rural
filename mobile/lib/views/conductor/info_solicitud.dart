import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';
import 'package:mobile/ws/SocketManager.dart';
import '../../controllers/notificacion_controller.dart';
import 'viaje/viaje_conductor.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/utils/geolocator_helper.dart';

class InfoSolicitud extends StatefulWidget {
  final Map<String, dynamic> solicitud;

  const InfoSolicitud({super.key, required this.solicitud});

  @override
  State<InfoSolicitud> createState() => _InfoSolicitudState();
}

class _InfoSolicitudState extends State<InfoSolicitud> {
  final SocketManager _socketManager = SocketManager.instance;
  final NotificacionController _notificacionController = NotificacionController();
  String? _conductorId;
  double? _conductorLat;
  double? _conductorLng;
  StreamSubscription<Position>? _positionSub;

  Map<String, dynamic>? _origen;
  String? _distanciaAO;
  String? _distanciaOD;

  @override
  void initState() {
    super.initState();
    _imprimirDatosDebug();
    print(widget.solicitud);
    _conductorId = widget.solicitud['conductorId'];
    _origen = widget.solicitud['origen'];
    _iniciarUbicacionTiempoReal();
  }

  Future<void> _iniciarUbicacionTiempoReal() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    if (permiso == LocationPermission.deniedForever) return;

    final posicion = await Geolocator.getCurrentPosition();
    _actualizarUbicacion(posicion);

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_actualizarUbicacion);
  }

  void _actualizarUbicacion(Position pos) {
    setState(() {
      _conductorLat = pos.latitude;
      _conductorLng = pos.longitude;
    });
    _calcularDistancias();
  }

  Future<void> _calcularDistancias() async {
    if (_conductorLat == null || _conductorLng == null || _origen == null) return;

    final latO = _toDouble(_origen?['latitud']);
    final lngO = _toDouble(_origen?['longitud']);
    final destino = widget.solicitud['destino'];
    final latD = _toDouble(destino?['latitud']);
    final lngD = _toDouble(destino?['longitud']);

    if (latO != null && lngO != null) {
      final distanciaAO = await GeolocatorHelper.calcularDistancia(_conductorLat!, _conductorLng!, latO, lngO) / 1000;
      setState(() {
        _distanciaAO = _formatearDistancia(distanciaAO);
      });
    }

    if (latO != null && lngO != null && latD != null && lngD != null) {
      final distanciaOD = await GeolocatorHelper.calcularDistancia(latO, lngO, latD, lngD) / 1000;
      setState(() {
        _distanciaOD = _formatearDistancia(distanciaOD);
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatearDistancia(double? km) {
    if (km == null) return '';
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  void _imprimirDatosDebug() {
    final cliente = widget.solicitud['clienteId'];
    final tokens = cliente['tokenFCM'] as List<dynamic>?;
    final destino = widget.solicitud['destino'];

    final emisorId = widget.solicitud['conductorId'];
    final receptorId = cliente['_id'];
    final tokenList = tokens ?? [];
    final ultimoToken = tokenList.isNotEmpty ? tokenList.last : 'Sin token disponible';

    print('🔵 Emisor (conductor): $emisorId');
    print('🟢 Receptor (cliente): $receptorId');
    print('📨 Tokens FCM del cliente: $tokenList');
    print('📍 Último token FCM del cliente (para enviar): $ultimoToken');
    print('🗺️ Destino solicitado: ${destino?['nombre']} - ${destino?['direccion']}');
  }

  void _cambiarEstado(BuildContext context, String nuevoEstado) async {
    void _onSolicitudError(error) {
      _socketManager.off('solicitud:error', _onSolicitudError);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al $nuevoEstado solicitud: $error'),
            backgroundColor: ConductorStyles.errorColor,
          ),
        );
      }
    }

    void _onSolicitudActualizar(data) {
      _socketManager.off('solicitud:estadoActualizado', _onSolicitudActualizar);
      _socketManager.off('solicitud:error', _onSolicitudError);

      final cliente = widget.solicitud['clienteId'];

      // Notificación push (opcional)
      _notificacionController.enviarNotificacion(
        emisorId: widget.solicitud['conductorId'],
        rolEmisor: 'conductor',
        usuarioId: cliente['_id'],
        rol: 'cliente',
        titulo: 'Solicitud $nuevoEstado',
        cuerpo: 'Tu solicitud fue $nuevoEstado por el conductor.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud $nuevoEstado exitosamente')),
        );
      }

      _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});


      print('🔵 Emisor (conductor): ${nuevoEstado}');
      // NUEVA LÓGICA: Si la solicitud fue aceptada, iniciar el viaje y navegar
      if (nuevoEstado == 'aceptada') {
        print('🔵 Emisor (conductor): ${widget.solicitud['conductorId']}');
        // Iniciar el viaje
        _socketManager.emit('viaje:iniciar', {
          'solicitudId': widget.solicitud['_id'],
          'conductorId': widget.solicitud['conductorId'],
          'clienteId': cliente['_id'],
        });

        // Escuchar cuando el viaje se inicie exitosamente
        _socketManager.on('viaje:iniciado', (viajeData) {
          _socketManager.off('viaje:iniciado');

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ViajeConductor(
                  viajeData: viajeData['viaje'],
                  clienteData: cliente,
                ),
              ),
            );
          }
        });
      } else {
        Navigator.pop(context);
      }
    }

    _socketManager.on('solicitud:estadoActualizado', _onSolicitudActualizar);
    _socketManager.on('solicitud:error', _onSolicitudError);

    _socketManager.emit('solicitud:actualizar', {
      'solicitudId': widget.solicitud['_id'],
      'estado': nuevoEstado
    });
  }

  Widget _buildUbicacionCard({
    required String titulo,
    required IconData icono,
    required Color color,
    String? nombre,
    String? direccion,
    required String distanciaLabel,
    String? distancia,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icono, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nombre != null)
                        Text(
                          nombre,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (direccion != null)
                        Text(
                          direccion,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (distancia != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.route, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "$distanciaLabel: ",
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                    Text(
                      distancia,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.solicitud['clienteId'];
    final destino = widget.solicitud['destino'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del cliente (más compacta)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Información del Cliente",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${cliente['nombre']}",
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "${cliente['telefono']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ubicaciones (más compactas)
                  if (_origen != null)
                    _buildUbicacionCard(
                      titulo: "Origen",
                      icono: Icons.my_location,
                      color: Colors.green,
                      nombre: _origen?['nombre'],
                      direccion: _origen?['direccion'],
                      distanciaLabel: "Distancia al origen",
                      distancia: _distanciaAO,
                    ),

                  if (destino != null)
                    _buildUbicacionCard(
                      titulo: "Destino",
                      icono: Icons.location_on,
                      color: Colors.red,
                      nombre: destino?['nombre'],
                      direccion: destino?['direccion'],
                      distanciaLabel: "Distancia Origen-Destino",
                      distancia: _distanciaOD,
                    ),
                ],
              ),
            ),
          ),

          // Botones fijos en la parte inferior
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cambiarEstado(context, 'aceptada'),
                      icon: const Icon(Icons.check, color: Colors.white, size: 20),
                      label: const Text("Aceptar", style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cambiarEstado(context, 'rechazada'),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      label: const Text("Rechazar", style: TextStyle(fontSize: 16, color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}