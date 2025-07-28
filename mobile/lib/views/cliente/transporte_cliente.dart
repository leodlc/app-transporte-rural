import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/services/bloc/notifications_bloc.dart';
import 'package:mobile/ws/SocketManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cliente/info_conductor_cliente.dart';
import 'cliente_styles.dart';

class TransporteCliente extends StatefulWidget {
  const TransporteCliente({super.key});

  @override
  State<TransporteCliente> createState() => _TransporteClienteState();
}

class _TransporteClienteState extends State<TransporteCliente> {
  late NotificationsBloc _notificationsBloc;
  final SocketManager _socketManager = SocketManager.instance;
  bool _isConnected = false;
  List<Map<String, dynamic>> _conductores = [];
  String _mensajeEstado = "Cargando conductores...";
  String? _clienteId;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = context.read<NotificationsBloc>();
    _inicializarSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notificationsBloc.add(RequestPermissions());
      await _obtenerConductorId();
      if (_clienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró ID de cliente')),
        );
      }
    });
  }

  Future<void> _obtenerConductorId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    setState(() {
      _clienteId = id;
    });
  }

  void _inicializarSocket() {
    _socketManager.on('conductores-activos', (data) {
      setState(() {
        _conductores = List<Map<String, dynamic>>.from(data);
        _actualizarMensaje();
      });
    });

    _socketManager.on('ubicacion-conductor-actualizada', (data) {
      setState(() {
        final index = _conductores.indexWhere((c) => c['conductorId'] == data['conductorId']);
        if (index != -1) {
          _conductores[index]['lat'] = data['lat'];
          _conductores[index]['lng'] = data['lng'];
        } else {
          _conductores.add(data);
        }
        _actualizarMensaje();
      });
    });

    _socketManager.on('ubicacion-conductor-desactivada', (data) {
      setState(() {
        _conductores.removeWhere((c) => c['conductorId'] == data['conductorId']);
        _actualizarMensaje();
      });
    });

    setState(() {
      _isConnected = _socketManager.isConnected;
    });

    _socketManager.emit('solicitar-conductores');
  }

  void _actualizarMensaje() {
    _mensajeEstado = _conductores.isEmpty ? "No hay conductores activos" : "";
  }

  @override
  void dispose() {
    _socketManager.off('conductores-activos');
    _socketManager.off('ubicacion-conductor-actualizada');
    _socketManager.off('ubicacion-conductor-desactivada');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Conductores disponibles',
          style: ClienteStyles.appBarTitle,
        ),
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
            color: ClienteStyles.primaryColor,
            onPressed: () {
              _socketManager.emit('solicitar-conductores');
            },
          ),
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!_isConnected) {
                _socketManager.reconnect().then((success) {
                  setState(() {
                    _isConnected = _socketManager.isConnected;
                  });
                });
              }
            },
          ),
        ],
      ),
      body: _mensajeEstado.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(ClienteStyles.spacing16),
          child: Text(
            _mensajeEstado,
            style: ClienteStyles.bodyText.copyWith(
              color: ClienteStyles.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(ClienteStyles.spacing16),
        itemCount: _conductores.length,
        separatorBuilder: (_, __) => const SizedBox(height: ClienteStyles.spacing12),
        itemBuilder: (context, index) {
          final c = _conductores[index];
          final lat = (c['lat'] as num?)?.toDouble();
          final lng = (c['lng'] as num?)?.toDouble();
          final latStr = lat != null ? lat.toStringAsFixed(6) : '--';
          final lngStr = lng != null ? lng.toStringAsFixed(6) : '--';

          return InkWell(
            borderRadius: BorderRadius.circular(ClienteStyles.radiusLarge),
            onTap: () {
              if (_socketManager.socket != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoConductorCliente(
                      conductorData: c,
                      socket: _socketManager.socket!,
                    ),
                  ),
                );
              }
            },
            child: Container(
              decoration: ClienteStyles.cardDecoration,
              padding: const EdgeInsets.all(ClienteStyles.spacing16),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_rounded,
                    size: 36,
                    color: ClienteStyles.primaryColor,
                  ),
                  const SizedBox(width: ClienteStyles.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['nombre'] ?? 'Conductor',
                          style: ClienteStyles.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: $latStr, Lng: $lngStr',
                          style: ClienteStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ClienteStyles.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
