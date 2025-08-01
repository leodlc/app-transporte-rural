import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/config/api_config.dart';
import 'package:mobile/utils/maps_utils.dart';
import 'package:mobile/views/cliente/cliente_styles.dart';
import 'package:mobile/views/cliente/main_cliente.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/notificacion_controller.dart';

class ViajeCliente extends StatefulWidget {
  final Map<String, dynamic> viajeData;       // debe contener _id y solicitudId
  final Map<String, dynamic> conductorData;   // datos básicos del conductor

  const ViajeCliente({
    super.key,
    required this.viajeData,
    required this.conductorData,
  });

  @override
  State<ViajeCliente> createState() => _ViajeClienteState();
}

class _ViajeClienteState extends State<ViajeCliente> {
  // — Constantes para seguimiento de ruta
  static const int _intervaloActualizacionRuta = 60; // segundos
  static const int _distanciaActualizacionRuta = 100; // metros
  static const String _googleMapsApiKey = ApiConfig.googleMapsApiKey; // Reemplazar con tu API key

  // — WebSocket y notificaciones
  final SocketManager _socket = SocketManager.instance;
  final NotificacionController _noti = NotificacionController();

  // — Identificadores y estado
  String? _clienteId;
  String? _viajeId;
  String _estado = 'iniciado';
  String? _codigoSeguridad;

  // — Mapa y ubicaciones
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _ubicacionOrigen;
  LatLng? _ubicacionDestino;
  LatLng? _ubicacionConductor;

  // — Seguimiento de ubicación
  DateTime? _ultimaActualizacionRuta;
  LatLng? _ultimaUbicacionRuta;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // 1) cargar IDs
    final prefs = await SharedPreferences.getInstance();
    _clienteId = prefs.getString('id');
    _viajeId = widget.viajeData['_id'] as String?;
    _estado = widget.viajeData['estado'] as String? ?? 'iniciado';

    // 2) extraer origen/destino
    final sol = widget.viajeData['solicitudId'];
    if (sol != null) {
      _ubicacionOrigen = LatLng(
        (sol['origen']['latitud'] as num).toDouble(),
        (sol['origen']['longitud'] as num).toDouble(),
      );
      _ubicacionDestino = LatLng(
        (sol['destino']['latitud'] as num).toDouble(),
        (sol['destino']['longitud'] as num).toDouble(),
      );
    }

    // 3) configurar listeners
    _socket.on('viaje:iniciado', _onIniciado);
    _socket.on('viaje:unido', _onUnido);
    _socket.on('viaje:ubicacion-recibida', _onUbicacion);
    _socket.on('viaje:conductor-llegando', _onLlegando);
    _socket.on('viaje:comenzado', _onComenzado);
    _socket.on('viaje:cancelado', _onCancelado);
    _socket.on('viaje:finalizado', _onFinalizado);
    _socket.on('viaje:error', _onError);

    // 4) unirse a la sala del viaje
    _socket.emit('viaje:unirse', {
      'viajeId': _viajeId,
      'usuarioId': _clienteId,
      'tipoUsuario': 'cliente',
    });

    // 5) inicializar seguimiento de ubicación del cliente
    await _iniciarSeguimientoUbicacion();
  }

  // — Seguimiento de ubicación del cliente —
  Future<void> _iniciarSeguimientoUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _actualizarMarcadores();
      _actualizarUbicacionCliente();

    } catch (e) {
      print('Error al iniciar seguimiento de ubicación: $e');
    }
  }

  void _actualizarUbicacionCliente() {
    if (_estado == 'en_curso') {
      _actualizarRuta();
    }
  }


  // — Actualizar ruta en el mapa usando Google Directions API —
  Future<void> _actualizarRuta() async {
    if (_ubicacionConductor == null || _ubicacionDestino == null || _estado != 'en_curso') {
      return;
    }

    try {
      final polylinePoints = await _obtenerRutaGoogleDirections(
        _ubicacionConductor!,
        _ubicacionDestino!,
      );

      if (polylinePoints.isNotEmpty) {
        final polyline = Polyline(
          polylineId: PolylineId('ruta_cliente'),
          points: polylinePoints,
          color: ClienteStyles.accentBlue,
          width: 5,
        );

        setState(() {
          _polylines = {polyline};
        });
      }
    } catch (e) {
      print('Error al obtener ruta: $e');
    }
  }

  // — Obtener ruta real usando Google Directions API —
  Future<List<LatLng>> _obtenerRutaGoogleDirections(
      LatLng origen,
      LatLng destino,
      ) async {
    print('Obteniendo ruta de google maps $origen a $destino');
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origen.latitude},${origen.longitude}&'
        'destination=${destino.latitude},${destino.longitude}&'
        'key=$_googleMapsApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polylineEncoded = route['overview_polyline']['points'];

        return MapsUtils.decodificarPolyline(polylineEncoded);
      }
    }

    throw Exception('Error al obtener ruta de Google Directions');
  }


  // — Handlers WebSocket —
  void _onIniciado(dynamic data) {
    setState(() {
      _codigoSeguridad = data['codigoSeguridad'] as String?;
    });
    if (_codigoSeguridad != null) {
      _mostrarCodigo(_codigoSeguridad!);
    }
  }

  void _onUnido(dynamic data) {
    setState(() {
      _estado = data['viaje']['estado'] as String? ?? _estado;
      if (data.containsKey('codigoSeguridad')) {
        _codigoSeguridad = data['codigoSeguridad'] as String;
        _mostrarCodigo(_codigoSeguridad!);
      }
    });
  }

  void _onUbicacion(dynamic data) {
    if (data['tipoUsuario'] == 'conductor') {
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      setState(() => _ubicacionConductor = LatLng(lat, lng));

      final ubicacionActual = LatLng(lat, lng);
      final ahora = DateTime.now();

      _actualizarMarcadores();

      bool necesitaActualizarRuta = false;

      if (_ultimaActualizacionRuta == null ||
          ahora.difference(_ultimaActualizacionRuta!).inSeconds >= _intervaloActualizacionRuta) {
        necesitaActualizarRuta = true;
      } else if (_ultimaUbicacionRuta != null &&
          _distanciaEnMetros(_ultimaUbicacionRuta!, ubicacionActual) > _distanciaActualizacionRuta) {
        necesitaActualizarRuta = true;
      }

      if (necesitaActualizarRuta) {
        _actualizarUbicacionCliente();
        _ultimaUbicacionRuta = ubicacionActual;
        _ultimaActualizacionRuta = ahora;
      }

    }
  }

  double _distanciaEnMetros(LatLng punto1, LatLng punto2) {
    return Geolocator.distanceBetween(
        punto1.latitude, punto1.longitude,
        punto2.latitude, punto2.longitude
    );
  }

  void _onLlegando(dynamic data) {
    setState(() => _estado = 'llegando');
    if (data.containsKey('codigoSeguridad')) {
      _codigoSeguridad = data['codigoSeguridad'] as String;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['mensaje'] as String? ?? 'El conductor está llegando'),
        backgroundColor: ClienteStyles.accentBlue,
      ),
    );
  }

  void _onComenzado(dynamic data) {
    setState(() => _estado = 'en_curso');
    _actualizarRuta(); // Iniciar seguimiento de ruta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Tu viaje ha comenzado!'),
        backgroundColor: ClienteStyles.successColor,
      ),
    );
  }

  void _onCancelado(dynamic data) {
    setState(() => _estado = 'cancelado');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viaje cancelado: ${data['motivo']}'),
        backgroundColor: ClienteStyles.errorColor,
      ),
    );
  }

  void _onFinalizado(dynamic data) {
    setState(() => _estado = 'finalizado');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viaje finalizado. ¡Gracias!'),
        backgroundColor: ClienteStyles.successColor,
      ),
    );
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) _regresarAInicio();
    });
  }

  void _onError(dynamic msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $msg'), backgroundColor: ClienteStyles.errorColor),
    );
  }

  // — Muestra diálogo con el código de seguridad (arreglado overflow) —
  void _mostrarCodigo(String codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: ClienteStyles.accentBlue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Código de Seguridad',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este es tu código. Verifícalo con el conductor al abordar:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClienteStyles.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClienteStyles.accentBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  codigo,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: ClienteStyles.accentBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClienteStyles.accentBlue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // — Regresar a inicio —
  void _regresarAInicio() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainCliente()),
          (route) => false, // Elimina todas las rutas anteriores
    );
  }

  // — Mapa y marcadores —
  void _actualizarMarcadores() {
    final m = <Marker>{};

    if (_estado != 'en_curso' && _ubicacionOrigen != null) {
      m.add(Marker(
        markerId: MarkerId('origen'),
        position: _ubicacionOrigen!,
        infoWindow: InfoWindow(title: 'Punto de recogida'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_estado == 'en_curso' && _ubicacionDestino != null) {
      m.add(Marker(
        markerId: MarkerId('destino'),
        position: _ubicacionDestino!,
        infoWindow: InfoWindow(title: 'Destino'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    if (_estado != 'en_curso' && _ubicacionConductor != null) {
      m.add(Marker(
        markerId: MarkerId('conductor'),
        position: _ubicacionConductor!,
        infoWindow: InfoWindow(title: 'Conductor'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }

    if (_estado == 'en_curso' && _ubicacionConductor != null) {
      m.add(Marker(
        markerId: MarkerId('cliente'),
        position: _ubicacionConductor!,
        infoWindow: InfoWindow(title: 'Tu ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }

    setState(() => _markers = m);

    if (_mapCtrl != null && m.isNotEmpty) {
      final lats = m.map((z) => z.position.latitude).toList();
      final lngs = m.map((z) => z.position.longitude).toList();
      final bounds = LatLngBounds(
        southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
        northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
      );
      _mapCtrl!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Widget _buildMapa() {
    // Ocultar mapa si el viaje está cancelado
    if (_estado == 'cancelado') {
      return SizedBox.shrink();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _ubicacionOrigen ?? LatLng(-0.1807, -78.4678),
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          mapType: MapType.normal,
          onMapCreated: (c) {
            _mapCtrl = c;
            _actualizarMarcadores();
          },
          myLocationEnabled: _estado == 'en_curso',
          myLocationButtonEnabled: _estado == 'en_curso',
        ),
      ),
    );
  }

  Widget _buildEstadoCard() {
    IconData icon;
    Color color;
    String title, desc;

    switch (_estado) {
      case 'iniciado':
        icon = Icons.schedule;
        color = ClienteStyles.accentBlue;
        title = 'En camino';
        desc = 'El conductor va hacia ti';
        break;
      case 'llegando':
        icon = Icons.location_on;
        color = ClienteStyles.warningColor;
        title = 'Casi llegó';
        desc = 'Verifica el código de seguridad';
        break;
      case 'en_curso':
        icon = Icons.directions_car;
        color = ClienteStyles.successColor;
        title = 'Viaje activo';
        desc = 'Disfruta tu viaje';
        break;
      case 'finalizado':
        icon = Icons.check_circle;
        color = ClienteStyles.successColor;
        title = 'Completado';
        desc = '¡Has llegado a tu destino!';
        break;
      default:
        icon = Icons.cancel;
        color = ClienteStyles.errorColor;
        title = 'Cancelado';
        desc = 'El viaje fue cancelado';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: ClienteStyles.cardDecoration.copyWith(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ClienteStyles.cardTitle.copyWith(color: color)),
                SizedBox(height: 4),
                Text(desc, style: ClienteStyles.bodyText.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConductorInfo() {
    final nombre = widget.conductorData['nombre'] as String? ?? '';
    final email = widget.conductorData['email'] as String? ?? '';
    final telefono = widget.conductorData['telefono'] as String? ?? '';
    final vehiculo = widget.conductorData['vehiculo'] as Map<String, dynamic>?;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Container(
      decoration: ClienteStyles.cardDecoration,
      child: Column(
        children: [
          // Header con avatar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ClienteStyles.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: ClienteStyles.primaryGreen,
                  child: Text(
                    inicial,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  nombre,
                  style: ClienteStyles.cardTitle,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ClienteStyles.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ClienteStyles.accentBlue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Conductor Verificado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ClienteStyles.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información de contacto
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de contacto',
                  style: ClienteStyles.cardTitle.copyWith(fontSize: 16),
                ),
                SizedBox(height: 16),
                _buildInfoRow('Correo electrónico', email, Icons.email_outlined),
                _buildInfoRow('Teléfono', telefono, Icons.phone_outlined),
              ],
            ),
          ),

          // Información del vehículo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ClienteStyles.backgroundLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: ClienteStyles.primaryGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Información del vehículo',
                      style: ClienteStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (vehiculo != null) ...[
                  _buildInfoRow(
                    'Modelo',
                    vehiculo['modelo'] ?? 'No especificado',
                    Icons.directions_car_outlined,
                  ),
                  _buildInfoRow(
                    'Placa',
                    vehiculo['placa'] ?? 'No especificada',
                    Icons.pin_outlined,
                  ),
                  _buildInfoRow(
                    'RMT',
                    vehiculo['rmt'] ?? 'No especificado',
                    Icons.verified_outlined,
                  ),
                  if (vehiculo['color'] != null)
                    _buildInfoRow(
                      'Color',
                      vehiculo['color'],
                      Icons.palette_outlined,
                    ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ClienteStyles.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: ClienteStyles.warningColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Vehículo sin asignar',
                          style: TextStyle(
                            color: ClienteStyles.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ClienteStyles.textSecondary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: ClienteStyles.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'No especificado' : value,
                  style: ClienteStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    if (_estado == 'finalizado') return SizedBox.shrink();

    if (_estado == 'cancelado') {
      return ElevatedButton.icon(
        onPressed: _regresarAInicio,
        icon: Icon(Icons.home, color: Colors.white),
        label: Text('Regresar a Inicio', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ClienteStyles.primaryGreen,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _cancelar,
      icon: Icon(Icons.cancel, color: ClienteStyles.errorColor),
      label: Text('Cancelar Viaje', style: TextStyle(color: ClienteStyles.errorColor)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: ClienteStyles.errorColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildBotonCodigo() {
    // Ocultar botón si el viaje está cancelado
    if (_codigoSeguridad == null || _estado == 'cancelado') {
      return SizedBox.shrink();
    }

    return ElevatedButton.icon(
      icon: Icon(Icons.lock_outline, color: Colors.white),
      label: Text('Ver código de seguridad', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: ClienteStyles.accentBlue,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _mostrarCodigo(_codigoSeguridad!),
    );
  }

  void _cancelar() {
    showDialog(
      context: context,
      builder: (_) {
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
                    borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                    borderSide: BorderSide(color: Colors.black54.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                    borderSide: BorderSide(color: Colors.black54, width: 2),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: Text('No', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _socket.emit('viaje:cancelar', {
                  'viajeId': _viajeId,
                  'usuarioId': _clienteId,
                  'tipoUsuario': 'cliente',
                  'motivo': motivo.isEmpty ? 'Cancelado por el cliente' : motivo,
                });
                _noti.enviarNotificacion(
                  emisorId: _clienteId!,
                  rolEmisor: 'cliente',
                  usuarioId: widget.conductorData['_id'] as String,
                  rol: 'conductor',
                  titulo: 'Viaje cancelado',
                  cuerpo: 'El cliente ha cancelado el viaje',
                );
              },

              child: Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();

    for (final ev in [
      'viaje:iniciado',
      'viaje:unido',
      'viaje:ubicacion-recibida',
      'viaje:conductor-llegando',
      'viaje:comenzado',
      'viaje:cancelado',
      'viaje:finalizado',
      'viaje:error',
    ]) {
      _socket.off(ev);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: Text('Tu Viaje', style: ClienteStyles.appBarTitle),
        leading: ['finalizado', 'cancelado'].contains(_estado)
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: ClienteStyles.textPrimary),
          onPressed: () => _regresarAInicio(),
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEstadoCard(),
            SizedBox(height: 16),
            _buildConductorInfo(),
            SizedBox(height: 16),
            _buildBotonCodigo(),
            if (_codigoSeguridad != null && _estado != 'cancelado')
              SizedBox(height: 16),
            _buildMapa(),
            SizedBox(height: 16),
            _buildAcciones(),
          ],
        ),
      ),
    );
  }
}