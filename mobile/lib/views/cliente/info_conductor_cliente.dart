import 'package:flutter/material.dart';
import 'package:mobile/utils/maps_utils.dart';
import 'package:mobile/views/cliente/viaje_cliente.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/api_config.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/notificacion_controller.dart';
import 'cliente_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class InfoConductorCliente extends StatefulWidget {
  final Map<String, dynamic> conductorData;
  final IO.Socket socket;

  const InfoConductorCliente({
    super.key,
    required this.conductorData,
    required this.socket,
  });

  @override
  State<InfoConductorCliente> createState() => _InfoConductorClienteState();
}

class _InfoConductorClienteState extends State<InfoConductorCliente>
    with SingleTickerProviderStateMixin {
  final NotificacionController _notificacionController = NotificacionController();
  final ClienteController _clienteController = ClienteController();
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();

  Map<String, dynamic>? _infoConductor;
  bool _cargando = true;
  bool _solicitudEnviada = false;
  bool _enviandoSolicitud = false;
  bool _buscandoDestinos = false;
  bool _buscandoOrigenes = false;
  bool _mostrandoMapa = false;
  bool _obteniendoUbicacion = false;

  // Variables para origen y destino
  Map<String, dynamic>? _origenSeleccionado;
  Map<String, dynamic>? _destinoSeleccionado;
  List<Map<String, dynamic>> _sugerenciasOrigen = [];
  List<Map<String, dynamic>> _sugerenciasDestino = [];

  // Variables para el mapa
  GoogleMapController? _mapController;
  LatLng _ubicacionActual = const LatLng(-0.1807, -78.4678); // Quito por defecto
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // NUEVO: Para dibujar la ruta
  LatLng? _ubicacionCentralMapa; // NUEVO: Para el marcador central

  // Control de pestañas
  late TabController _tabController;
  int _tabActual = 0; // 0: Origen, 1: Destino

  // Modo de selección en mapa
  String _modoSeleccionMapa = 'origen'; // 'origen' o 'destino'


  // Reemplaza con tu API Key de Google Places
  static const String _googlePlacesApiKey = ApiConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _tabActual = _tabController.index;
        _modoSeleccionMapa = _tabActual == 0 ? 'origen' : 'destino';
      });
    });
    _cargarInfo();
    _obtenerUbicacionActual();
    widget.socket.on('ubicacion-conductor-desactivada', _handleUbicacionDesactivada);
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _ubicacionActual = LatLng(position.latitude, position.longitude);
      });

      // Sugerir ubicación actual como origen
      if (_origenSeleccionado == null) {
        final detallesUbicacionActual = await _obtenerDireccionDeCoordinadas(_ubicacionActual);
        if (detallesUbicacionActual != null) {
          setState(() {
            _origenSeleccionado = detallesUbicacionActual;
            _origenController.text = detallesUbicacionActual['nombre'];
          });
        }
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  void _handleUbicacionDesactivada(dynamic data) {
    final conductorId = data['conductorId'];
    if (conductorId == widget.conductorData['conductorId']) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El conductor ha desactivado su ubicación.'),
            backgroundColor: ClienteStyles.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _cargarInfo() async {
    final id = widget.conductorData['conductorId'];
    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('id');

    if (clienteId == null) {
      setState(() {
        _cargando = false;
      });
      return;
    }

    final data = await _clienteController.fetchConductorDataSinShared(id);

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/existe-pendiente?clienteId=$clienteId&conductorId=$id'),
    );

    final json = jsonDecode(response.body);
    final solicitudPendiente = json['existe'] == true;

    setState(() {
      _infoConductor = data;
      _solicitudEnviada = solicitudPendiente;
      _cargando = false;
    });
  }

  Future<void> _buscarUbicaciones(String query, bool esOrigen) async {
    if (query.length < 3) {
      setState(() {
        if (esOrigen) {
          _sugerenciasOrigen = [];
        } else {
          _sugerenciasDestino = [];
        }
      });
      return;
    }

    setState(() {
      if (esOrigen) {
        _buscandoOrigenes = true;
      } else {
        _buscandoDestinos = true;
      }
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&key=$_googlePlacesApiKey'
            '&types=establishment|geocode'
            '&language=es'
            '&components=country:ec',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final List<Map<String, dynamic>> sugerencias = [];

          for (var prediction in data['predictions']) {
            sugerencias.add({
              'placeId': prediction['place_id'],
              'descripcion': prediction['description'],
              'nombrePrincipal': prediction['structured_formatting']['main_text'],
              'nombreSecundario': prediction['structured_formatting']['secondary_text'] ?? '',
            });
          }

          setState(() {
            if (esOrigen) {
              _sugerenciasOrigen = sugerencias;
            } else {
              _sugerenciasDestino = sugerencias;
            }
          });
        }
      }
    } catch (e) {
      print('Error al buscar ubicaciones: $e');
    } finally {
      setState(() {
        if (esOrigen) {
          _buscandoOrigenes = false;
        } else {
          _buscandoDestinos = false;
        }
      });
    }
  }

  Future<Map<String, dynamic>?> _obtenerDetallesLugar(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&key=$_googlePlacesApiKey'
            '&fields=name,formatted_address,geometry'
            '&language=es',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];

          return {
            'nombre': result['name'],
            'direccion': result['formatted_address'],
            'latitud': geometry['lat'],
            'longitud': geometry['lng'],
            'placeId': placeId,
          };
        }
      }
    } catch (e) {
      print('Error al obtener detalles del lugar: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> _obtenerDireccionDeCoordinadas(LatLng coordenadas) async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
            '?latlng=${coordenadas.latitude},${coordenadas.longitude}'
            '&key=$_googlePlacesApiKey'
            '&language=es',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];

          return {
            'nombre': result['formatted_address'].split(',')[0],
            'direccion': result['formatted_address'],
            'latitud': coordenadas.latitude,
            'longitud': coordenadas.longitude,
            'placeId': result['place_id'] ?? '',
          };
        }
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
    } finally {
      setState(() {
        _obteniendoUbicacion = false;
      });
    }

    return null;
  }

  void _seleccionarUbicacion(Map<String, dynamic> sugerencia, bool esOrigen) async {
    final detalles = await _obtenerDetallesLugar(sugerencia['placeId']);

    if (detalles != null) {
      setState(() {
        if (esOrigen) {
          _origenSeleccionado = detalles;
          _origenController.text = detalles['nombre'];
          _sugerenciasOrigen = [];
        } else {
          _destinoSeleccionado = detalles;
          _destinoController.text = detalles['nombre'];
          _sugerenciasDestino = [];
        }
        _actualizarMarcadores();
      });
    }
  }

  void _actualizarMarcadores() {
    Set<Marker> nuevosMarkers = {};

    if (_origenSeleccionado != null) {
      nuevosMarkers.add(
        Marker(
          markerId: const MarkerId('origen'),
          position: LatLng(_origenSeleccionado!['latitud'], _origenSeleccionado!['longitud']),
          infoWindow: InfoWindow(
            title: 'Origen',
            snippet: _origenSeleccionado!['nombre'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_destinoSeleccionado != null) {
      nuevosMarkers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: LatLng(_destinoSeleccionado!['latitud'], _destinoSeleccionado!['longitud']),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: _destinoSeleccionado!['nombre'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    setState(() {
      _markers = nuevosMarkers;
    });
  }

  void _toggleMapa() {
    setState(() {
      _mostrandoMapa = !_mostrandoMapa;
    });
  }

  void _usarUbicacionActual() async {
    final detallesUbicacionActual = await _obtenerDireccionDeCoordinadas(_ubicacionActual);
    if (detallesUbicacionActual != null) {
      setState(() {
        _origenSeleccionado = detallesUbicacionActual;
        _origenController.text = detallesUbicacionActual['nombre'];
        _sugerenciasOrigen = [];
        _actualizarMarcadores();
      });
    }
  }

  @override
  void dispose() {
    widget.socket.off('ubicacion-conductor-desactivada', _handleUbicacionDesactivada);
    _origenController.dispose();
    _destinoController.dispose();
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (_origenSeleccionado == null || _destinoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_origenSeleccionado == null
              ? 'Por favor selecciona un punto de partida'
              : 'Por favor selecciona un destino'),
          backgroundColor: ClienteStyles.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _enviandoSolicitud = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('id');
    final nombreCliente = prefs.getString('nombre') ?? 'Cliente Desconocido';
    final conductorId = widget.conductorData['conductorId'];

    if (clienteId == null) {
      setState(() {
        _enviandoSolicitud = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se ha iniciado sesión.'),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
      }
      return;
    }

    void _onSolicitudError(error) {
      widget.socket.off('solicitud:error', _onSolicitudError);

      setState(() {
        _enviandoSolicitud = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $error'),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
      }
    }

    void _onSolicitudCreada(data) {
      widget.socket.off('solicitud:creada', _onSolicitudCreada);
      widget.socket.off('solicitud:error', _onSolicitudError);

      setState(() {
        _solicitudEnviada = true;
        _enviandoSolicitud = false;
      });

      _notificacionController.enviarNotificacion(
        emisorId: clienteId,
        rolEmisor: 'cliente',
        usuarioId: conductorId,
        rol: 'conductor',
        titulo: 'Nueva solicitud de transporte',
        cuerpo: 'El cliente $nombreCliente ha solicitado un viaje desde ${_origenSeleccionado!['nombre']} a ${_destinoSeleccionado!['nombre']}.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Solicitud enviada. Se notificó al conductor.'),
            backgroundColor: ClienteStyles.successColor,
          ),
        );
      }
    }

    void _onSolicitudEstadoActualizado(data) {
      widget.socket.off('solicitud:estadoActualizado', _onSolicitudEstadoActualizado);
      widget.socket.off('solicitud:error', _onSolicitudError);

      print('Estado de solicitud actualizado: $data');

      final estado = data['estado'];

      if (estado == 'aceptada') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Solicitud aceptada! Iniciando viaje...'),
              backgroundColor: ClienteStyles.successColor,
            ),
          );
        }

        print("escuchando viaje:iniciado");
        widget.socket.on('viaje:iniciado', (viajeData) {
          widget.socket.off('viaje:iniciado');

          print("viaje iniciado entro al metodo");

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ViajeCliente(
                  viajeData: viajeData['viaje'],
                  conductorData: _infoConductor!,
                ),
              ),
            );
          }
        });
      } else if (estado == 'rechazada') {
        setState(() {
          _solicitudEnviada = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Solicitud rechazada. Puedes intentar con otro conductor.'),
              backgroundColor: ClienteStyles.warningColor,
            ),
          );
        }
      }
    }

    widget.socket.on('solicitud:creada', _onSolicitudCreada);
    widget.socket.on('solicitud:error', _onSolicitudError);
    widget.socket.on('solicitud:estadoActualizado', _onSolicitudEstadoActualizado);

    // Emitir la solicitud con información del origen y destino
    widget.socket.emit('solicitud:crear', {
      'clienteId': clienteId,
      'conductorId': conductorId,
      'origen': {
        'nombre': _origenSeleccionado!['nombre'],
        'direccion': _origenSeleccionado!['direccion'],
        'latitud': _origenSeleccionado!['latitud'],
        'longitud': _origenSeleccionado!['longitud'],
        'placeId': _origenSeleccionado!['placeId'],
      },
      'destino': {
        'nombre': _destinoSeleccionado!['nombre'],
        'direccion': _destinoSeleccionado!['direccion'],
        'latitud': _destinoSeleccionado!['latitud'],
        'longitud': _destinoSeleccionado!['longitud'],
        'placeId': _destinoSeleccionado!['placeId'],
      },
    });
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClienteStyles.spacing8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ClienteStyles.spacing8),
            decoration: BoxDecoration(
              color: ClienteStyles.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ClienteStyles.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: ClienteStyles.primaryGreen,
            ),
          ),
          SizedBox(width: ClienteStyles.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ClienteStyles.labelText,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: ClienteStyles.bodyText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoUbicacion({
    required String titulo,
    required TextEditingController controller,
    required List<Map<String, dynamic>> sugerencias,
    required Map<String, dynamic>? ubicacionSeleccionada,
    required bool buscando,
    required bool esOrigen,
    required IconData icono,
    required Color color,
    String? hintText,
    Widget? botonExtra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: color),
            SizedBox(width: ClienteStyles.spacing8),
            Text(
              titulo,
              style: ClienteStyles.cardTitle.copyWith(fontSize: 16),
            ),
            if (botonExtra != null) ...[
              Spacer(),
              botonExtra,
            ],
          ],
        ),
        SizedBox(height: ClienteStyles.spacing16),

        // Campo de búsqueda
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText ?? 'Buscar $titulo...',
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: ubicacionSeleccionada != null
                ? IconButton(
              icon: Icon(Icons.clear_rounded),
              onPressed: () => _limpiarUbicacion(esOrigen),
            )
                : buscando
                ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          onChanged: (value) {
            if (ubicacionSeleccionada == null) {
              _buscarUbicaciones(value, esOrigen);
            }
          },
          readOnly: ubicacionSeleccionada != null,
        ),

        // Sugerencias
        if (sugerencias.isNotEmpty && ubicacionSeleccionada == null) ...[
          SizedBox(height: ClienteStyles.spacing8),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sugerencias.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: color.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final sugerencia = sugerencias[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: color,
                    size: 20,
                  ),
                  title: Text(
                    sugerencia['nombrePrincipal'],
                    style: ClienteStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: sugerencia['nombreSecundario'].isNotEmpty
                      ? Text(
                    sugerencia['nombreSecundario'],
                    style: ClienteStyles.bodyText.copyWith(
                      fontSize: 12,
                      color: ClienteStyles.textSecondary,
                    ),
                  )
                      : null,
                  onTap: () => _seleccionarUbicacion(sugerencia, esOrigen),
                  dense: true,
                );
              },
            ),
          ),
        ],

        // Ubicación seleccionada
        if (ubicacionSeleccionada != null) ...[
          SizedBox(height: ClienteStyles.spacing16),
          Container(
            padding: const EdgeInsets.all(ClienteStyles.spacing16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: color,
                      size: 20,
                    ),
                    SizedBox(width: ClienteStyles.spacing8),
                    Text(
                      '$titulo seleccionado',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ClienteStyles.spacing8),
                Text(
                  ubicacionSeleccionada['nombre'],
                  style: ClienteStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  ubicacionSeleccionada['direccion'],
                  style: ClienteStyles.bodyText.copyWith(
                    fontSize: 14,
                    color: ClienteStyles.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUbicacionesSelector() {
    return Container(
      padding: const EdgeInsets.only(bottom: ClienteStyles.spacing16),
      decoration: ClienteStyles.cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.route_rounded, color: ClienteStyles.primaryGreen),
                    SizedBox(width: ClienteStyles.spacing8),
                    Text('Seleccionar ruta', style: ClienteStyles.cardTitle.copyWith(fontSize: 18)),
                  ],
                ),
                TextButton.icon(
                  onPressed: _toggleMapa,
                  icon: Icon(_mostrandoMapa ? Icons.list_rounded : Icons.map_rounded, size: 20),
                  label: Text(_mostrandoMapa ? 'Lista' : 'Mapa'),
                  style: TextButton.styleFrom(foregroundColor: ClienteStyles.primaryGreen),
                ),
              ],
            ),
          ),
          if (_mostrandoMapa)
            _buildInterfazMapa() // NUEVO: Lógica del mapa extraída a su propia función
          else
            _buildInterfazLista(), // NUEVO: Lógica de la lista extraída
        ],
      ),
    );
  }

  Widget _buildInterfazLista() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClienteStyles.spacing16),
      child: Column(
        children: [
          _buildCampoUbicacion(
            titulo: 'Punto de partida',
            controller: _origenController,
            sugerencias: _sugerenciasOrigen,
            ubicacionSeleccionada: _origenSeleccionado,
            buscando: _buscandoOrigenes,
            esOrigen: true,
            icono: Icons.my_location,
            color: ClienteStyles.primaryGreen,
            botonExtra: TextButton.icon(
              onPressed: _usarUbicacionActual,
              icon: Icon(Icons.gps_fixed, size: 16, color: ClienteStyles.primaryColor,),
              label: Text('Actual', style: TextStyle(color: ClienteStyles.primaryColor,),),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          SizedBox(height: ClienteStyles.spacing16),
          _buildCampoUbicacion(
            titulo: 'Destino',
            controller: _destinoController,
            sugerencias: _sugerenciasDestino,
            ubicacionSeleccionada: _destinoSeleccionado,
            buscando: _buscandoDestinos,
            esOrigen: false,
            icono: Icons.location_on,
            color: ClienteStyles.accentBlue,
          ),
        ],
      ),
    );
  }

// NUEVA FUNCIÓN para la interfaz del mapa (aquí está la magia)
  Widget _buildInterfazMapa() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: ClienteStyles.spacing16),
          decoration: BoxDecoration(
            color: ClienteStyles.backgroundLight,
            borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.my_location, size: 16), SizedBox(width: 4), Text('Origen')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.flag_rounded, size: 16), SizedBox(width: 4), Text('Destino')])),
            ],
            labelColor: _tabActual == 0 ? ClienteStyles.primaryGreen : ClienteStyles.accentBlue,
            unselectedLabelColor: ClienteStyles.textSecondary,
            indicator: BoxDecoration(
              color: (_tabActual == 0 ? ClienteStyles.primaryGreen : ClienteStyles.accentBlue).withAlpha(25),
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
            ),
          ),
        ),
        SizedBox(height: ClienteStyles.spacing16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClienteStyles.spacing16),
          child: Container(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // El Mapa
                ClipRRect(
                  borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(target: _ubicacionActual, zoom: 15.0),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onCameraMove: (CameraPosition position) {
                      // Actualiza la ubicación central mientras se mueve el mapa
                      _ubicacionCentralMapa = position.target;
                    },
                    onCameraIdle: () async {
                      // Cuando el usuario deja de mover el mapa, obtenemos la dirección
                      if (_ubicacionCentralMapa != null) {
                        final detalles = await _obtenerDireccionDeCoordinadas(_ubicacionCentralMapa!);
                        if (detalles != null) {
                          final controller = _modoSeleccionMapa == 'origen' ? _origenController : _destinoController;
                          controller.text = detalles['nombre'];
                        }
                      }
                    },
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<EagerGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                ),
                // El Pin Central Fijo
                IgnorePointer(
                  child: Icon(
                    Icons.location_pin,
                    size: 50,
                    color: _modoSeleccionMapa == 'origen' ? ClienteStyles.primaryGreen : ClienteStyles.accentBlue,
                  ),
                ),
                // Botón de Confirmación
                Positioned(
                  bottom: 16,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      _modoSeleccionMapa == 'origen' ? 'Confirmar Origen' : 'Confirmar Destino',
                    ),
                    onPressed: () {
                      if (_ubicacionCentralMapa != null) {
                        _seleccionarUbicacionEnMapa(_ubicacionCentralMapa!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _modoSeleccionMapa == 'origen' ? ClienteStyles.primaryGreen : ClienteStyles.accentBlue,
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        SizedBox(height: ClienteStyles.spacing12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClienteStyles.spacing16),
          child: _obteniendoUbicacion
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Obteniendo dirección...'),
            ],
          )
              : Text(
            'Mueve el mapa para seleccionar el punto',
            style: ClienteStyles.bodyText.copyWith(color: ClienteStyles.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // En tu _InfoConductorClienteState

  void _seleccionarUbicacionEnMapa(LatLng ubicacion) async {
    final detalles = await _obtenerDireccionDeCoordinadas(ubicacion);
    if (detalles != null) {
      setState(() {
        if (_modoSeleccionMapa == 'origen') {
          _origenSeleccionado = detalles;
          _origenController.text = detalles['nombre'];
        } else {
          _destinoSeleccionado = detalles;
          _destinoController.text = detalles['nombre'];
        }
        _actualizarMarcadores();
        // NUEVO: Intenta dibujar la ruta si ya tenemos ambos puntos
        if (_origenSeleccionado != null && _destinoSeleccionado != null) {
          _obtenerRuta();
        }
      });
    }
  }

// NUEVA FUNCIÓN para obtener y dibujar la ruta
  Future<void> _obtenerRuta() async {
    if (_origenSeleccionado == null || _destinoSeleccionado == null) return;

    final LatLng origen = LatLng(_origenSeleccionado!['latitud'], _origenSeleccionado!['longitud']);
    final LatLng destino = LatLng(_destinoSeleccionado!['latitud'], _destinoSeleccionado!['longitud']);

    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origen.latitude},${origen.longitude}'
        '&destination=${destino.latitude},${destino.longitude}'
        '&key=$_googlePlacesApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('ruta'),
                points: MapsUtils.decodificarPolyline(points),
                color: ClienteStyles.accentBlue,
                width: 5,
              ),
            };
          });
          _ajustarCamaraARuta();
        }
      }
    } catch (e) {
      print('Error obteniendo ruta: $e');
    }
  }

// NUEVA FUNCIÓN para ajustar la cámara a la ruta
  void _ajustarCamaraARuta() {
    if (_mapController == null || _origenSeleccionado == null || _destinoSeleccionado == null) return;

    LatLng southwest = LatLng(
      _origenSeleccionado!['latitud'] < _destinoSeleccionado!['latitud'] ? _origenSeleccionado!['latitud'] : _destinoSeleccionado!['latitud'],
      _origenSeleccionado!['longitud'] < _destinoSeleccionado!['longitud'] ? _origenSeleccionado!['longitud'] : _destinoSeleccionado!['longitud'],
    );
    LatLng northeast = LatLng(
      _origenSeleccionado!['latitud'] > _destinoSeleccionado!['latitud'] ? _origenSeleccionado!['latitud'] : _destinoSeleccionado!['latitud'],
      _origenSeleccionado!['longitud'] > _destinoSeleccionado!['longitud'] ? _origenSeleccionado!['longitud'] : _destinoSeleccionado!['longitud'],
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(northeast: northeast, southwest: southwest),
        80.0, // padding
      ),
    );
  }

// MODIFICACIÓN en limpiarUbicacion para que también borre la ruta
  void _limpiarUbicacion(bool esOrigen) {
    setState(() {
      if (esOrigen) {
        _origenSeleccionado = null;
        _origenController.clear();
        _sugerenciasOrigen = [];
      } else {
        _destinoSeleccionado = null;
        _destinoController.clear();
        _sugerenciasDestino = [];
      }
      _actualizarMarcadores();
      _polylines = {}; // Limpiar la ruta
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: Text(
          'Información del Conductor',
          style: ClienteStyles.appBarTitle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: ClienteStyles.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _cargando
          ? Center(
        child: CircularProgressIndicator(
          color: ClienteStyles.primaryGreen,
        ),
      )
          : _infoConductor == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: ClienteStyles.textSecondary,
            ),
            SizedBox(height: ClienteStyles.spacing16),
            Text(
              "No se pudo cargar la información",
              style: ClienteStyles.bodyText,
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(ClienteStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de ubicaciones
            _buildUbicacionesSelector(),

            SizedBox(height: ClienteStyles.spacing16),

            // Tarjeta de información del conductor
            Container(
              decoration: ClienteStyles.cardDecoration,
              child: Column(
                children: [
                  // Header con avatar
                  Container(
                    padding: const EdgeInsets.all(ClienteStyles.spacing24),
                    decoration: BoxDecoration(
                      color: ClienteStyles.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ClienteStyles.radiusLarge),
                        topRight: Radius.circular(ClienteStyles.radiusLarge),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: ClienteStyles.primaryGreen,
                          child: Text(
                            _infoConductor!['nombre'][0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: ClienteStyles.surfaceWhite,
                            ),
                          ),
                        ),
                        SizedBox(height: ClienteStyles.spacing16),
                        Text(
                          _infoConductor!['nombre'],
                          style: ClienteStyles.cardTitle,
                        ),
                        SizedBox(height: ClienteStyles.spacing8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ClienteStyles.spacing12,
                            vertical: ClienteStyles.spacing8,
                          ),
                          decoration: ClienteStyles.chipDecoration(
                            color: ClienteStyles.primaryNavy,
                          ),
                          child: Text(
                            'Conductor Verificado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ClienteStyles.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información de contacto
                  Padding(
                    padding: const EdgeInsets.all(ClienteStyles.spacing24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de contacto',
                          style: ClienteStyles.cardTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: ClienteStyles.spacing16),
                        _buildInfoRow(
                          'Correo electrónico',
                          _infoConductor!['email'],
                          Icons.email_outlined,
                        ),
                        _buildInfoRow(
                          'Teléfono',
                          _infoConductor!['telefono'],
                          Icons.phone_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ClienteStyles.spacing16),

            // Tarjeta de información del vehículo
            Container(
              decoration: ClienteStyles.cardDecoration,
              padding: const EdgeInsets.all(ClienteStyles.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        color: ClienteStyles.primaryGreen,
                      ),
                      SizedBox(width: ClienteStyles.spacing8),
                      Text(
                        'Información del vehículo',
                        style: ClienteStyles.cardTitle.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ClienteStyles.spacing16),
                  if (_infoConductor!['vehiculo'] != null) ...[
                    _buildInfoRow(
                      'Modelo',
                      _infoConductor!['vehiculo']['modelo'],
                      Icons.directions_car_outlined,
                    ),
                    _buildInfoRow(
                      'Placa',
                      _infoConductor!['vehiculo']['placa'],
                      Icons.pin_outlined,
                    ),
                    _buildInfoRow(
                      'RMT',
                      _infoConductor!['vehiculo']['rmt'],
                      Icons.verified_outlined,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(ClienteStyles.spacing16),
                      decoration: BoxDecoration(
                        color: ClienteStyles.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: ClienteStyles.warningColor,
                            size: 20,
                          ),
                          SizedBox(width: ClienteStyles.spacing8),
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

            SizedBox(height: ClienteStyles.spacing24),

            // Estado de solicitud o botón
            if (_solicitudEnviada) ...[
              Container(
                padding: const EdgeInsets.all(ClienteStyles.spacing20),
                decoration: BoxDecoration(
                  color: ClienteStyles.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                  border: Border.all(
                    color: ClienteStyles.accentBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: ClienteStyles.accentBlue,
                      size: 48,
                    ),
                    SizedBox(height: ClienteStyles.spacing16),
                    Text(
                      'Solicitud enviada',
                      style: ClienteStyles.cardTitle.copyWith(
                        color: ClienteStyles.accentBlue,
                      ),
                    ),
                    SizedBox(height: ClienteStyles.spacing8),
                    Text(
                      'Solicitud enviada al conductor ${_infoConductor!['nombre']} '
                          'para ir desde ${_origenSeleccionado?['nombre'] ?? 'origen'} '
                          'hasta ${_destinoSeleccionado?['nombre'] ?? 'destino'}.\n'
                          'Esperando respuesta (puede tardar hasta 5 minutos).',
                      style: ClienteStyles.bodyText.copyWith(
                        fontSize: 14,
                        color: ClienteStyles.accentBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_enviandoSolicitud || _origenSeleccionado == null || _destinoSeleccionado == null)
                      ? null
                      : _enviarSolicitud,
                  icon: _enviandoSolicitud
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ClienteStyles.surfaceWhite,
                      ),
                    ),
                  )
                      : Icon(Icons.directions_car_rounded),
                  label: Text(
                    _enviandoSolicitud
                        ? 'Enviando...'
                        : (_origenSeleccionado == null || _destinoSeleccionado == null)
                        ? 'Selecciona origen y destino'
                        : 'Solicitar Transporte',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ClienteStyles.primaryButtonStyle.copyWith(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: ClienteStyles.spacing32),
          ],
        ),
      ),
    );
  }
}