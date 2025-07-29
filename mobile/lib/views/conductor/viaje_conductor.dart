import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../controllers/notificacion_controller.dart';

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

  String? _conductorId;
  String? _viajeId;
  String? _salaViaje;
  String _estadoViaje = 'iniciado';
  Map<String, dynamic>? _ubicacionCliente;
  bool _enviandoAccion = false;
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
    _conductorId = prefs.getString('id');
    _viajeId = widget.viajeData['_id'];
    _salaViaje = 'viaje_$_viajeId';
    _estadoViaje = widget.viajeData['estado'] ?? 'iniciado';

    // Unirse a la sala del viaje
    _socketManager.emit('viaje:unirse', {
      'viajeId': _viajeId,
      'usuarioId': _conductorId,
      'tipoUsuario': 'conductor'
    });
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
            backgroundColor: ConductorStyles.errorColor,
          ),
        );
      }
      return;
    }

    // Compartir ubicación cada 3 segundos (más frecuente para conductor)
    _locationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _socketManager.emit('viaje:ubicacion-actualizar', {
          'viajeId': _viajeId,
          'usuarioId': _conductorId,
          'tipoUsuario': 'conductor',
          'lat': position.latitude,
          'lng': position.longitude,
        });

        print('🚗 Ubicación del conductor enviada: ${position.latitude}, ${position.longitude}');

        // También actualizar la ubicación en el socket general de conductores
        _socketManager.emit('ubicacion:actualizar', {
          'conductorId': _conductorId,
          'lat': position.latitude,
          'lng': position.longitude,
        });

      } catch (e) {
        print('Error obteniendo ubicación del conductor: $e');
      }
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

  void _onViajeUnido(dynamic data) {
    print('🚗 Conductor unido al viaje: $data');
    setState(() {
      _salaViaje = data['salaViaje'];
    });
  }

  void _onUbicacionRecibida(dynamic data) {
    if (data['tipoUsuario'] == 'cliente') {
      setState(() {
        _ubicacionCliente = {
          'lat': data['lat'],
          'lng': data['lng'],
          'timestamp': data['timestamp']
        };
      });
      print('📍 Ubicación del cliente actualizada: ${data['lat']}, ${data['lng']}');
    }
  }

  void _onConductorLlegando(dynamic data) {
    setState(() {
      _estadoViaje = 'llegando';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Has indicado que estás llegando'),
          backgroundColor: ConductorStyles.successColor,
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
          content: Text('¡Viaje iniciado!'),
          backgroundColor: ConductorStyles.successColor,
        ),
      );
    }
  }

  void _onViajeFinalized(dynamic data) {
    setState(() {
      _estadoViaje = 'finalizado';
    });
    _locationTimer?.cancel(); // Detener el compartir ubicación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje finalizado exitosamente'),
          backgroundColor: ConductorStyles.successColor,
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
    _locationTimer?.cancel(); // Detener el compartir ubicación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje cancelado: ${data['motivo']}'),
          backgroundColor: ConductorStyles.warningColor,
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

    // Notificar al cliente
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

  void _comenzarViaje() {
    setState(() {
      _enviandoAccion = true;
    });

    _socketManager.emit('viaje:comenzar', {
      'viajeId': _viajeId,
      'conductorId': _conductorId,
    });

    // Notificar al cliente
    _notificacionController.enviarNotificacion(
      emisorId: _conductorId!,
      rolEmisor: 'conductor',
      usuarioId: widget.clienteData['_id'],
      rol: 'cliente',
      titulo: 'Viaje iniciado',
      cuerpo: '¡Tu viaje ha comenzado!',
    );

    setState(() {
      _enviandoAccion = false;
    });
  }

  void _finalizarViaje() {
    setState(() {
      _enviandoAccion = true;
    });

    _socketManager.emit('viaje:terminar', {
      'viajeId': _viajeId,
      'conductorId': _conductorId,
      'ubicacionFinal': _ubicacionCliente,
    });

    // Notificar al cliente
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
                  'usuarioId': _conductorId,
                  'tipoUsuario': 'conductor',
                  'motivo': motivo.isEmpty ? 'Cancelado por el conductor' : motivo,
                });

                // Notificar al cliente
                _notificacionController.enviarNotificacion(
                  emisorId: _conductorId!,
                  rolEmisor: 'conductor',
                  usuarioId: widget.clienteData['_id'],
                  rol: 'cliente',
                  titulo: 'Viaje cancelado',
                  cuerpo: 'El conductor ha cancelado el viaje',
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
        icon = Icons.navigation_rounded;
        color = ConductorStyles.primaryColor;
        titulo = 'Dirigiéndose al cliente';
        descripcion = 'Navega hacia la ubicación del cliente';
        break;
      case 'llegando':
        icon = Icons.location_on_rounded;
        color = ConductorStyles.warningColor;
        titulo = 'Llegando';
        descripcion = 'Has notificado que estás llegando';
        break;
      case 'en_curso':
        icon = Icons.directions_car_rounded;
        color = ConductorStyles.successColor;
        titulo = 'Viaje en curso';
        descripcion = 'El viaje está en progreso';
        break;
      case 'finalizado':
        icon = Icons.check_circle_rounded;
        color = ConductorStyles.successColor;
        titulo = 'Finalizado';
        descripcion = 'El viaje ha terminado exitosamente';
        break;
      case 'cancelado':
        icon = Icons.cancel_rounded;
        color = ConductorStyles.errorColor;
        titulo = 'Cancelado';
        descripcion = 'El viaje fue cancelado';
        break;
      default:
        icon = Icons.help_rounded;
        color = ConductorStyles.textSecondary;
        titulo = 'Estado desconocido';
        descripcion = '';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          SizedBox(height: 12),
          Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(descripcion, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildClienteInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información del Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ConductorStyles.primaryColor,
                child: Text(widget.clienteData['nombre'][0].toUpperCase(), style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.clienteData['nombre'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(widget.clienteData['telefono'], style: TextStyle(fontSize: 14, color: ConductorStyles.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionCliente() {
    if (_ubicacionCliente == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: ConductorStyles.textSecondary),
            SizedBox(width: 12),
            Text('Esperando ubicación del cliente...', style: TextStyle(color: ConductorStyles.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ConductorStyles.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: ConductorStyles.successColor),
              SizedBox(width: 8),
              Text('Ubicación del Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 8),
          Text('Lat: ${_ubicacionCliente!['lat'].toStringAsFixed(6)}'),
          Text('Lng: ${_ubicacionCliente!['lng'].toStringAsFixed(6)}'),
          Text('Actualizado: ${_ubicacionCliente!['timestamp']}', style: TextStyle(fontSize: 12, color: ConductorStyles.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEstadoUbicacion() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _compartiendoUbicacion
            ? ConductorStyles.successColor.withOpacity(0.1)
            : ConductorStyles.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_compartiendoUbicacion
              ? ConductorStyles.successColor
              : ConductorStyles.warningColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _compartiendoUbicacion
                ? Icons.gps_fixed_rounded
                : Icons.gps_off_rounded,
            color: _compartiendoUbicacion
                ? ConductorStyles.successColor
                : ConductorStyles.warningColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _compartiendoUbicacion
                      ? 'Compartiendo ubicación con el cliente'
                      : 'No se está compartiendo ubicación',
                  style: TextStyle(
                    color: _compartiendoUbicacion
                        ? ConductorStyles.successColor
                        : ConductorStyles.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _compartiendoUbicacion
                      ? 'Actualización cada 3 segundos'
                      : 'Verificar permisos de ubicación',
                  style: TextStyle(
                    fontSize: 12,
                    color: (_compartiendoUbicacion
                        ? ConductorStyles.successColor
                        : ConductorStyles.warningColor).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!_compartiendoUbicacion)
            IconButton(
              onPressed: _iniciarCompartirUbicacion,
              icon: Icon(
                Icons.refresh_rounded,
                color: ConductorStyles.warningColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    List<Widget> botones = [];

    switch (_estadoViaje) {
      case 'iniciado':
        botones.add(
          ElevatedButton.icon(
            onPressed: _enviandoAccion ? null : _marcarLlegando,
            icon: Icon(Icons.location_on),
            label: Text('Estoy llegando'),
            style: ElevatedButton.styleFrom(backgroundColor: ConductorStyles.warningColor),
          ),
        );
        break;
      case 'llegando':
        botones.add(
          ElevatedButton.icon(
            onPressed: _enviandoAccion ? null : _comenzarViaje,
            icon: Icon(Icons.play_arrow),
            label: Text('Comenzar Viaje'),
            style: ElevatedButton.styleFrom(backgroundColor: ConductorStyles.successColor),
          ),
        );
        break;
      case 'en_curso':
        botones.add(
          ElevatedButton.icon(
            onPressed: _enviandoAccion ? null : _finalizarViaje,
            icon: Icon(Icons.flag),
            label: Text('Finalizar Viaje'),
            style: ElevatedButton.styleFrom(backgroundColor: ConductorStyles.successColor),
          ),
        );
        break;
    }

    // Botón de cancelar (excepto si ya está finalizado o cancelado)
    if (!['finalizado', 'cancelado'].contains(_estadoViaje)) {
      botones.add(
        OutlinedButton.icon(
          onPressed: _enviandoAccion ? null : _cancelarViaje,
          icon: Icon(Icons.cancel, color: ConductorStyles.errorColor),
          label: Text('Cancelar Viaje', style: TextStyle(color: ConductorStyles.errorColor)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: ConductorStyles.errorColor),
          ),
        ),
      );
    }

    return Column(
      children: botones.map((boton) =>
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SizedBox(width: double.infinity, height: 48, child: boton),
          )
      ).toList(),
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
            _buildEstadoCard(),
            SizedBox(height: 20),
            _buildEstadoUbicacion(),
            SizedBox(height: 20),
            _buildClienteInfo(),
            SizedBox(height: 20),
            _buildUbicacionCliente(),
            SizedBox(height: 20),
            _buildAcciones(),
          ],
        ),
      ),
    );
  }
}