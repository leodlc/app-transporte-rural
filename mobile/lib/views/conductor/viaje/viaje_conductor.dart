import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/config/api_config.dart';
import 'package:mobile/utils/maps_utils.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';
import 'package:mobile/views/conductor/viaje/acciones_botones.dart';
import 'package:mobile/views/conductor/viaje/cliente_info_card.dart';
import 'package:mobile/views/conductor/viaje/dialogo_codigo_seguridad.dart';
import 'package:mobile/views/conductor/viaje/estado_card.dart';
import 'package:mobile/widgets/mapa_widget.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../controllers/notificacion_controller.dart';

class ViajeConductor extends StatefulWidget {
  final Map<String, dynamic> viajeData;
  final Map<String, dynamic> clienteData;

  const ViajeConductor({
    super.key,
    required this.viajeData,
    required this.clienteData,
  });

  @override
  State<ViajeConductor> createState() => _ViajeConductorState();
}

class _ViajeConductorState extends State<ViajeConductor> {
  final SocketManager _socketManager = SocketManager.instance;
  final NotificacionController _notificacionController = NotificacionController();

  // Variables principales
  String? _conductorId;
  String? _viajeId;
  String _estadoViaje = 'iniciado';
  bool _enviandoAccion = false;
  Timer? _locationTimer;

  // Variables para código de seguridad
  int _intentosRestantes = 3;
  Completer<bool>? _codigoVerificacionCompleter;
  final TextEditingController _codigoController = TextEditingController();

  // Variables para Google Maps optimizadas
  GoogleMapController? _mapController;
  Position? _ubicacionConductor;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _ubicacionOrigen;
  LatLng? _ubicacionDestino;

  // Optimización de rutas
  LatLng? _ultimaUbicacionRuta;
  DateTime? _ultimaActualizacionRuta;
  String? _ultimoEstadoRuta;
  bool _rutaCargada = false;
  static const int _intervaloActualizacionRuta = 60; // Reducido para mayor fluidez
  static const int _distanciaActualizacionRuta = 100;

  // API Key de Google Maps
  static const String _googleMapsApiKey = ApiConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _inicializarViaje();
    _configurarEventosSocket();
    _iniciarCompartirUbicacion();
    _extraerUbicaciones();
  }

  void _inicializarViaje() async {
    final prefs = await SharedPreferences.getInstance();
    _conductorId = prefs.getString('id');
    _viajeId = widget.viajeData['_id'];
    _estadoViaje = widget.viajeData['estado'] ?? 'iniciado';

    _socketManager.emit('viaje:unirse', {
      'viajeId': _viajeId,
      'usuarioId': _conductorId,
      'tipoUsuario': 'conductor'
    });
  }

  Future<bool> _esperarVerificacionCodigo() {
    _codigoVerificacionCompleter = Completer<bool>();
    return _codigoVerificacionCompleter!.future;
  }

  void _extraerUbicaciones() {
    if (widget.viajeData['solicitudId'] != null) {
      final solicitud = widget.viajeData['solicitudId'];

      if (solicitud['origen'] != null) {
        _ubicacionOrigen = LatLng(
          solicitud['origen']['latitud'].toDouble(),
          solicitud['origen']['longitud'].toDouble(),
        );
      }

      if (solicitud['destino'] != null) {
        _ubicacionDestino = LatLng(
          solicitud['destino']['latitud'].toDouble(),
          solicitud['destino']['longitud'].toDouble(),
        );
      }
    }
  }

  void _iniciarCompartirUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _mostrarError('Se necesitan permisos de ubicación para el viaje');
      return;
    }

    _locationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(accuracy: LocationAccuracy.high)
        );

        setState(() {
          _ubicacionConductor = position;
        });

        if (_estadoViaje != 'cancelado') {
          _socketManager.emit('viaje:ubicacion-actualizar', {
            'viajeId': _viajeId,
            'usuarioId': _conductorId,
            'tipoUsuario': 'conductor',
            'lat': position.latitude,
            'lng': position.longitude,
          });

          await _actualizarMapaInteligente();
        }

      } catch (e) {
        print('Error obteniendo ubicación del conductor: $e');
      }
    });
  }

  Future<void> _actualizarMapaInteligente() async {
    if (_ubicacionConductor == null) return;

    final ubicacionActual = LatLng(_ubicacionConductor!.latitude, _ubicacionConductor!.longitude);
    final ahora = DateTime.now();

    // Actualizar marcador del conductor siempre
    _actualizarMarcadorConductor();

    // Determinar si necesita actualizar ruta
    bool necesitaActualizarRuta = false;

    if (!_rutaCargada || _ultimoEstadoRuta != _estadoViaje) {
      necesitaActualizarRuta = true;
    } else if (_ultimaActualizacionRuta == null ||
        ahora.difference(_ultimaActualizacionRuta!).inSeconds >= _intervaloActualizacionRuta) {
      necesitaActualizarRuta = true;
    } else if (_ultimaUbicacionRuta != null &&
        _distanciaEnMetros(_ultimaUbicacionRuta!, ubicacionActual) > _distanciaActualizacionRuta) {
      necesitaActualizarRuta = true;
    }

    if (necesitaActualizarRuta) {
      await _cargarRutaOptimizada();
      _ultimaUbicacionRuta = ubicacionActual;
      _ultimaActualizacionRuta = ahora;
      _ultimoEstadoRuta = _estadoViaje;
      _rutaCargada = true;
    }
  }

  double _distanciaEnMetros(LatLng punto1, LatLng punto2) {
    return Geolocator.distanceBetween(
        punto1.latitude, punto1.longitude,
        punto2.latitude, punto2.longitude
    );
  }

  void _actualizarMarcadorConductor() {
    if (_ubicacionConductor == null) return;

    Set<Marker> nuevosMarkers = Set.from(_markers);
    nuevosMarkers.removeWhere((marker) => marker.markerId.value == 'conductor');

    nuevosMarkers.add(
      Marker(
        markerId: MarkerId('conductor'),
        position: LatLng(_ubicacionConductor!.latitude, _ubicacionConductor!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Mi ubicación'),
      ),
    );

    setState(() {
      _markers = nuevosMarkers;
    });
  }

  Future<void> _cargarRutaOptimizada() async {
    if (_ubicacionConductor == null) return;

    LatLng? destino;
    Color colorRuta = ConductorStyles.accentBlue;

    if (_estadoViaje == 'iniciado' || _estadoViaje == 'llegando') {
      destino = _ubicacionOrigen;
    } else if (_estadoViaje == 'en_curso') {
      destino = _ubicacionDestino;
    }

    if (destino == null) return;

    // Actualizar marcadores
    Set<Marker> nuevosMarkers = {
      Marker(
        markerId: MarkerId('conductor'),
        position: LatLng(_ubicacionConductor!.latitude, _ubicacionConductor!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Mi ubicación'),
      ),
      Marker(
        markerId: MarkerId('destino'),
        position: destino,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue
        ),
        infoWindow: InfoWindow(
            title: _estadoViaje == 'en_curso' ? 'Destino' : 'Origen'
        ),
      ),
    };

    setState(() {
      _markers = nuevosMarkers;
    });

    // Cargar ruta
    await _obtenerRuta(
      LatLng(_ubicacionConductor!.latitude, _ubicacionConductor!.longitude),
      destino,
      colorRuta,
    );

    // Ajustar cámara solo si es necesario
    if (_mapController != null) {
      _ajustarCamara();
    }
  }

  Future<void> _obtenerRuta(LatLng origen, LatLng destino, Color color) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origen.latitude},${origen.longitude}'
        '&destination=${destino.latitude},${destino.longitude}'
        '&key=$_googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = MapsUtils.decodificarPolyline(route['overview_polyline']['points']);

          setState(() {
            _polylines = {
              Polyline(
                polylineId: PolylineId('ruta'),
                points: polylinePoints,
                color: color,
                width: 5,
              ),
            };
          });
        }
      }
    } catch (e) {
      print('Error obteniendo ruta: $e');
    }
  }

  void _ajustarCamara() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      minLat = minLat > marker.position.latitude ? marker.position.latitude : minLat;
      maxLat = maxLat < marker.position.latitude ? marker.position.latitude : maxLat;
      minLng = minLng > marker.position.longitude ? marker.position.longitude : minLng;
      maxLng = maxLng < marker.position.longitude ? marker.position.longitude : maxLng;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  void _configurarEventosSocket() {
    _socketManager.on('viaje:conductor-llegando', _onConductorLlegando);
    _socketManager.on('viaje:codigo-incorrecto', _onCodigoIncorrecto);
    _socketManager.on('viaje:comenzado', _onViajeComenzado);
    _socketManager.on('viaje:finalizado', _onViajeFinalized);
    _socketManager.on('viaje:cancelado', _onViajeCancelado);
    _socketManager.on('viaje:error', _onViajeError);
  }

  void _onConductorLlegando(dynamic data) {
    setState(() {
      _estadoViaje = 'llegando';
    });
    _mostrarExito('Has indicado que estás llegando');
  }

  void _onCodigoIncorrecto(dynamic data) {
    setState(() {
      _intentosRestantes = data['intentosRestantes'] ?? 0;
    });

    _codigoController.clear();
    _codigoVerificacionCompleter?.complete(false);
    _codigoVerificacionCompleter = null;
  }

  void _reproducirAudioAleatorio() {
    final random = Random();
    final numero = random.nextInt(17) + 1; // 1 a 17
    final path = 'audios/audio_${numero.toString().padLeft(2, '0')}.mp3';

    final player = AudioPlayer();
    player.play(AssetSource(path));
  }

  void _onViajeComenzado(dynamic data) {
    _codigoVerificacionCompleter?.complete(true);
    _codigoVerificacionCompleter = null;

    setState(() {
      _estadoViaje = 'en_curso';
    });

    _cargarRutaOptimizada();
    _mostrarExito('¡Código verificado! Viaje iniciado hacia el destino a');
    Future.delayed(Duration(seconds: 5), _reproducirAudioAleatorio);
  }

  void _onViajeFinalized(dynamic data) {
    setState(() {
      _estadoViaje = 'finalizado';
    });
    _locationTimer?.cancel();
    _mostrarExito('Viaje finalizado exitosamente');
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _onViajeCancelado(dynamic data) {
    setState(() {
      _estadoViaje = 'cancelado';
    });
    _locationTimer?.cancel();
    _locationTimer = null;
    _mostrarError('Viaje cancelado: ${data['motivo'] ?? 'Sin motivo especificado'}');
  }

  void _onViajeError(dynamic error) {
    _mostrarError('Error: $error');
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: ConductorStyles.successColor,
        ),
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: ConductorStyles.errorColor,
        ),
      );
    }
  }

  void _marcarLlegando() {
    setState(() {
      _enviandoAccion = true;
    });

    _socketManager.emit('viaje:llegando', {
      'viajeId': _viajeId,
      'conductorId': _conductorId,
    });

    _notificacionController.enviarNotificacion(
      emisorId: _conductorId!,
      rolEmisor: 'conductor',
      usuarioId: widget.clienteData['_id'],
      rol: 'cliente',
      titulo: 'Conductor llegando',
      cuerpo: 'El conductor está llegando a tu ubicación',
    );

    setState(() {
      _enviandoAccion = false;
    });
  }

  void _mostrarDialogoCodigoSeguridad() async {
    // El diálogo ahora es "inteligente" y no necesita que le pasemos un callback complejo.
    // Solo espera el resultado final.
    await DialogoCodigoSeguridad.mostrar(
      context: context,
      intentosRestantesInicial: _intentosRestantes,
      onVerificarCodigo: (codigoIngresado) async {
        // Esta parte sigue siendo necesaria para la comunicación con el backend.
        if (_viajeId == null || _conductorId == null) return false;

        _socketManager.emit('viaje:verificar-codigo', {
          'viajeId': _viajeId,
          'conductorId': _conductorId,
          'codigoIngresado': codigoIngresado,
        });

        // Espera la respuesta del socket (viaje:comenzado o viaje:codigo-incorrecto)
        return await _esperarVerificacionCodigo();
      },
    );
  }

  void _finalizarViaje() {
    setState(() {
      _enviandoAccion = true;
    });

    _socketManager.emit('viaje:terminar', {
      'viajeId': _viajeId,
      'conductorId': _conductorId,
    });

    _notificacionController.enviarNotificacion(
      emisorId: _conductorId!,
      rolEmisor: 'conductor',
      usuarioId: widget.clienteData['_id'],
      rol: 'cliente',
      titulo: 'Viaje finalizado',
      cuerpo: 'Tu viaje ha llegado a su destino',
    );

    setState(() {
      _enviandoAccion = false;
    });
  }

  void _cancelarViaje() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String motivo = '';
        return AlertDialog(
          title: Text('Cancelar Viaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Seguro quieres cancelar este viaje?'),
              SizedBox(height: 20),
              TextField(
                onChanged: (value) => motivo = value,
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintStyle: const TextStyle(color: Colors.black54),
                  suffixStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                    borderSide: BorderSide(color: Colors.black54.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                    borderSide: BorderSide(color: Colors.black54, width: 2),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _socketManager.emit('viaje:cancelar', {
                  'viajeId': _viajeId,
                  'usuarioId': _conductorId,
                  'tipoUsuario': 'conductor',
                  'motivo': motivo.isEmpty ? 'Cancelado por el conductor' : motivo,
                });

                _notificacionController.enviarNotificacion(
                  emisorId: _conductorId!,
                  rolEmisor: 'conductor',
                  usuarioId: widget.clienteData['_id'],
                  rol: 'cliente',
                  titulo: 'Viaje cancelado',
                  cuerpo: 'El conductor ha cancelado el viaje',
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    _codigoController.dispose();
    _socketManager.off('viaje:unido');
    _socketManager.off('viaje:conductor-llegando');
    _socketManager.off('viaje:codigo-incorrecto');
    _socketManager.off('viaje:comenzado');
    _socketManager.off('viaje:finalizado');
    _socketManager.off('viaje:cancelado');
    _socketManager.off('viaje:error');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConductorStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ConductorStyles.surfaceWhite,
        title: Text('Viaje en Curso', style: ConductorStyles.appBarTitle),
        leading: ['finalizado', 'cancelado'].contains(_estadoViaje)
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EstadoCard(estado: _estadoViaje),
            SizedBox(height: 16),
            ClienteInfoCard(clienteData: widget.clienteData),
            SizedBox(height: 16),
            ...(
                _estadoViaje != 'cancelado'
                    ? [
                  MapaWidget(
                    markers: _markers,
                    polylines: _polylines,
                    posicionInicial: LatLng(
                      _ubicacionConductor?.latitude ?? -0.1807,
                      _ubicacionConductor?.longitude ?? -78.4678,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      Future.delayed(Duration(milliseconds: 500), _cargarRutaOptimizada);
                    },
                  ),
                  SizedBox(height: 20),
                ]
                    : []
            ),
            AccionesBotones(
              estadoViaje: _estadoViaje,
              enviandoAccion: _enviandoAccion,
              onLlegando: _marcarLlegando,
              onVerificarCodigo: _mostrarDialogoCodigoSeguridad,
              onFinalizarViaje: _finalizarViaje,
              onCancelarViaje: _cancelarViaje,
            ),
          ],
        ),
      ),
    );
  }
}