import 'package:flutter/material.dart';
import 'package:mobile/views/cliente/cliente_styles.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../controllers/notificacion_controller.dart';

class ViajeCliente extends StatefulWidget {
  final Map<String, dynamic> viajeData;
  final Map<String, dynamic> conductorData;

  const ViajeCliente({
    super.key,
    required this.viajeData,
    required this.conductorData,
  });

  @override
  State<ViajeCliente> createState() => _ViajeClienteState();
}

class _ViajeClienteState extends State<ViajeCliente> {
  final SocketManager _socketManager = SocketManager.instance;
  final NotificacionController _notificacionController = NotificacionController();

  String? _clienteId;
  String? _viajeId;
  String? _salaViaje;
  String _estadoViaje = 'iniciado';
  Map<String, dynamic>? _ubicacionConductor;
  Timer? _locationTimer;
  bool _compartiendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _inicializarViaje();
    _configurarEventosSocket();
    _iniciarCompartirUbicacion();
  }

  void _inicializarViaje() async {
    final prefs = await SharedPreferences.getInstance();
    _clienteId = prefs.getString('id');
    _viajeId = widget.viajeData['_id'];
    _salaViaje = 'viaje_$_viajeId';
    _estadoViaje = widget.viajeData['estado'] ?? 'iniciado';

    // Unirse a la sala del viaje
    _socketManager.emit('viaje:unirse', {
      'viajeId': _viajeId,
      'usuarioId': _clienteId,
      'tipoUsuario': 'cliente'
    });
  }

  void _configurarEventosSocket() {
    _socketManager.on('viaje:unido', _onViajeUnido);
    _socketManager.on('viaje:ubicacion-recibida', _onUbicacionRecibida);
    _socketManager.on('viaje:conductor-llegando', _onConductorLlegando);
    _socketManager.on('viaje:comenzado', _onViajeComenzado);
    _socketManager.on('viaje:finalizado', _onViajeFinalized);
    _socketManager.on('viaje:cancelado', _onViajeCancelado);
    _socketManager.on('viaje:error', _onViajeError);
  }

  void _iniciarCompartirUbicacion() async {
    setState(() {
      _compartiendoUbicacion = true;
    });

    // Verificar permisos de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        _compartiendoUbicacion = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se necesitan permisos de ubicación para el viaje'),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
      }
      return;
    }

    // Compartir ubicación cada 5 segundos
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition();
        _socketManager.emit('viaje:ubicacion-actualizar', {
          'viajeId': _viajeId,
          'usuarioId': _clienteId,
          'tipoUsuario': 'cliente',
          'lat': position.latitude,
          'lng': position.longitude,
        });
      } catch (e) {
        print('Error obteniendo ubicación: $e');
      }
    });
  }

  void _onViajeUnido(dynamic data) {
    print('👤 Cliente unido al viaje: $data');
    setState(() {
      _salaViaje = data['salaViaje'];
    });
  }

  void _onUbicacionRecibida(dynamic data) {
    if (data['tipoUsuario'] == 'conductor') {
      setState(() {
        _ubicacionConductor = {
          'lat': data['lat'],
          'lng': data['lng'],
          'timestamp': data['timestamp']
        };
      });
      print('🚗 Ubicación del conductor actualizada: ${data['lat']}, ${data['lng']}');
    }
  }

  void _onConductorLlegando(dynamic data) {
    setState(() {
      _estadoViaje = 'llegando';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['mensaje'] ?? 'El conductor está llegando'),
          backgroundColor: ClienteStyles.accentBlue,
        ),
      );
    }
  }

  void _onViajeComenzado(dynamic data) {
    setState(() {
      _estadoViaje = 'en_curso';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Tu viaje ha comenzado!'),
          backgroundColor: ClienteStyles.successColor,
        ),
      );
    }
  }

  void _onViajeFinalized(dynamic data) {
    setState(() {
      _estadoViaje = 'finalizado';
    });
    _locationTimer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje finalizado. ¡Gracias por usar nuestro servicio!'),
          backgroundColor: ClienteStyles.successColor,
        ),
      );
      // Regresar a la pantalla anterior después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _onViajeCancelado(dynamic data) {
    setState(() {
      _estadoViaje = 'cancelado';
    });
    _locationTimer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje cancelado: ${data['motivo']}'),
          backgroundColor: ClienteStyles.warningColor,
        ),
      );
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _onViajeError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: ClienteStyles.errorColor,
        ),
      );
    }
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
              Text('¿Estás seguro de que quieres cancelar este viaje?'),
              SizedBox(height: 16),
              TextField(
                onChanged: (value) => motivo = value,
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _socketManager.emit('viaje:cancelar', {
                  'viajeId': _viajeId,
                  'usuarioId': _clienteId,
                  'tipoUsuario': 'cliente',
                  'motivo': motivo.isEmpty ? 'Cancelado por el cliente' : motivo,
                });

                // Notificar al conductor
                _notificacionController.enviarNotificacion(
                  emisorId: _clienteId!,
                  rolEmisor: 'cliente',
                  usuarioId: widget.conductorData['_id'],
                  rol: 'conductor',
                  titulo: 'Viaje cancelado',
                  cuerpo: 'El cliente ha cancelado el viaje',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Sí, Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstadoCard() {
    IconData icon;
    Color color;
    String titulo;
    String descripcion;

    switch (_estadoViaje) {
      case 'iniciado':
        icon = Icons.schedule_rounded;
        color = ClienteStyles.accentBlue;
        titulo = 'Conductor en camino';
        descripcion = 'El conductor se está dirigiendo hacia ti';
        break;
      case 'llegando':
        icon = Icons.location_on_rounded;
        color = ClienteStyles.warningColor;
        titulo = 'Conductor llegando';
        descripcion = 'El conductor está cerca de tu ubicación';
        break;
      case 'en_curso':
        icon = Icons.directions_car_rounded;
        color = ClienteStyles.successColor;
        titulo = 'Viaje en curso';
        descripcion = 'Disfruta tu viaje';
        break;
      case 'finalizado':
        icon = Icons.check_circle_rounded;
        color = ClienteStyles.successColor;
        titulo = 'Viaje completado';
        descripcion = '¡Has llegado a tu destino!';
        break;
      case 'cancelado':
        icon = Icons.cancel_rounded;
        color = ClienteStyles.errorColor;
        titulo = 'Viaje cancelado';
        descripcion = 'El viaje fue cancelado';
        break;
      default:
        icon = Icons.help_rounded;
        color = ClienteStyles.textSecondary;
        titulo = 'Estado desconocido';
        descripcion = '';
    }

    return Container(
      padding: EdgeInsets.all(24),
      decoration: ClienteStyles.cardDecoration.copyWith(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          SizedBox(height: ClienteStyles.spacing16),
          Text(
            titulo,
            style: ClienteStyles.cardTitle.copyWith(color: color, fontSize: 20),
          ),
          SizedBox(height: ClienteStyles.spacing8),
          Text(
            descripcion,
            style: ClienteStyles.bodyText.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConductorInfo() {
    return Container(
      decoration: ClienteStyles.cardDecoration,
      padding: EdgeInsets.all(ClienteStyles.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Tu Conductor',
              style: ClienteStyles.cardTitle.copyWith(fontSize: 16)
          ),
          SizedBox(height: ClienteStyles.spacing16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ClienteStyles.primaryGreen,
                child: Text(
                  widget.conductorData['nombre'][0].toUpperCase(),
                  style: TextStyle(
                    color: ClienteStyles.surfaceWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: ClienteStyles.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conductorData['nombre'],
                      style: ClienteStyles.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.conductorData['telefono'],
                      style: ClienteStyles.bodyText.copyWith(
                        color: ClienteStyles.textSecondary,
                      ),
                    ),
                    if (widget.conductorData['vehiculo'] != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 16,
                            color: ClienteStyles.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${widget.conductorData['vehiculo']['modelo']} - ${widget.conductorData['vehiculo']['placa']}',
                            style: ClienteStyles.bodyText.copyWith(
                              color: ClienteStyles.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionConductor() {
    if (_ubicacionConductor == null && _estadoViaje == 'iniciado') {
      return Container(
        padding: EdgeInsets.all(ClienteStyles.spacing16),
        decoration: BoxDecoration(
          color: ClienteStyles.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_searching_rounded,
              color: ClienteStyles.textSecondary,
            ),
            SizedBox(width: ClienteStyles.spacing12),
            Expanded(
              child: Text(
                'Esperando ubicación del conductor...',
                style: ClienteStyles.bodyText.copyWith(
                  color: ClienteStyles.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_ubicacionConductor == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(ClienteStyles.spacing16),
      decoration: BoxDecoration(
        color: ClienteStyles.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        border: Border.all(
          color: ClienteStyles.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: ClienteStyles.primaryGreen,
              ),
              SizedBox(width: ClienteStyles.spacing8),
              Text(
                'Ubicación del Conductor',
                style: ClienteStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ClienteStyles.primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: ClienteStyles.spacing8),
          Text(
            'Lat: ${_ubicacionConductor!['lat'].toStringAsFixed(6)}',
            style: ClienteStyles.bodyText.copyWith(fontSize: 14),
          ),
          Text(
            'Lng: ${_ubicacionConductor!['lng'].toStringAsFixed(6)}',
            style: ClienteStyles.bodyText.copyWith(fontSize: 14),
          ),
          Text(
            'Actualizado: ${_ubicacionConductor!['timestamp']}',
            style: ClienteStyles.bodyText.copyWith(
              fontSize: 12,
              color: ClienteStyles.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoUbicacion() {
    return Container(
      padding: EdgeInsets.all(ClienteStyles.spacing16),
      decoration: BoxDecoration(
        color: _compartiendoUbicacion
            ? ClienteStyles.successColor.withValues(alpha: 0.1)
            : ClienteStyles.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        border: Border.all(
          color: (_compartiendoUbicacion
              ? ClienteStyles.successColor
              : ClienteStyles.warningColor).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _compartiendoUbicacion
                ? Icons.gps_fixed_rounded
                : Icons.gps_off_rounded,
            color: _compartiendoUbicacion
                ? ClienteStyles.successColor
                : ClienteStyles.warningColor,
          ),
          SizedBox(width: ClienteStyles.spacing12),
          Expanded(
            child: Text(
              _compartiendoUbicacion
                  ? 'Compartiendo tu ubicación con el conductor'
                  : 'No se está compartiendo ubicación',
              style: ClienteStyles.bodyText.copyWith(
                color: _compartiendoUbicacion
                    ? ClienteStyles.successColor
                    : ClienteStyles.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    // Solo mostrar el botón de cancelar si el viaje no ha terminado
    if (['finalizado', 'cancelado'].contains(_estadoViaje)) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _cancelarViaje,
        icon: Icon(
          Icons.cancel_rounded,
          color: ClienteStyles.errorColor,
        ),
        label: Text(
          'Cancelar Viaje',
          style: TextStyle(
            color: ClienteStyles.errorColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ClienteStyles.errorColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildInstrucciones() {
    String instruccion = '';
    IconData icon = Icons.info_outline_rounded;
    Color color = ClienteStyles.accentBlue;

    switch (_estadoViaje) {
      case 'iniciado':
        instruccion = 'El conductor está en camino. Puedes ver su ubicación en tiempo real.';
        icon = Icons.directions_car_rounded;
        break;
      case 'llegando':
        instruccion = 'El conductor está llegando. Prepárate para abordar.';
        icon = Icons.notification_important_rounded;
        color = ClienteStyles.warningColor;
        break;
      case 'en_curso':
        instruccion = 'Disfruta tu viaje. El conductor te llevará a tu destino de forma segura.';
        icon = Icons.airline_seat_recline_normal_rounded;
        color = ClienteStyles.successColor;
        break;
      case 'finalizado':
        instruccion = '¡Viaje completado! Gracias por usar nuestro servicio.';
        icon = Icons.celebration_rounded;
        color = ClienteStyles.successColor;
        break;
      case 'cancelado':
        instruccion = 'El viaje ha sido cancelado. Puedes solicitar otro conductor.';
        icon = Icons.info_outline_rounded;
        color = ClienteStyles.errorColor;
        break;
      default:
        return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(ClienteStyles.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: ClienteStyles.spacing12),
          Expanded(
            child: Text(
              instruccion,
              style: ClienteStyles.bodyText.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socketManager.off('viaje:unido');
    _socketManager.off('viaje:ubicacion-recibida');
    _socketManager.off('viaje:conductor-llegando');
    _socketManager.off('viaje:comenzado');
    _socketManager.off('viaje:finalizado');
    _socketManager.off('viaje:cancelado');
    _socketManager.off('viaje:error');
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
          'Tu Viaje',
          style: ClienteStyles.appBarTitle,
        ),
        leading: ['finalizado', 'cancelado'].contains(_estadoViaje)
            ? IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: ClienteStyles.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        automaticallyImplyLeading: ['finalizado', 'cancelado'].contains(_estadoViaje),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ClienteStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEstadoCard(),
            SizedBox(height: ClienteStyles.spacing20),
            _buildInstrucciones(),
            SizedBox(height: ClienteStyles.spacing20),
            _buildConductorInfo(),
            SizedBox(height: ClienteStyles.spacing16),
            _buildEstadoUbicacion(),
            SizedBox(height: ClienteStyles.spacing16),
            _buildUbicacionConductor(),
            SizedBox(height: ClienteStyles.spacing24),
            _buildAcciones(),
            SizedBox(height: ClienteStyles.spacing32),
          ],
        ),
      ),
    );
  }
}