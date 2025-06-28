import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/conductor_controller.dart';
import '../../config/api_config.dart';
import '../cliente/info_conductor_cliente.dart';
import 'cliente_styles.dart'; // Asegúrate de importar tu clase de estilos

class TransporteCliente extends StatefulWidget {
  const TransporteCliente({super.key});

  @override
  State<TransporteCliente> createState() => _TransporteClienteState();
}

class _TransporteClienteState extends State<TransporteCliente> {
  final ConductorController _conductorController = ConductorController();
  List<Map<String, dynamic>> _conductores = [];
  late IO.Socket _socket;
  StreamSubscription? _subscription;
  String _mensajeEstado = "Cargando conductores...";

  @override
  void initState() {
    super.initState();
    _inicializarSocket();
    _cargarConductores();
  }

  void _inicializarSocket() {
    _socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('Socket conectado');
    });

    _socket.on('ubicacion-conductor-actualizada', (data) {
      setState(() {
        final index = _conductores.indexWhere((c) => c['conductorId'] == data['conductorId']);
        if (index != -1) {
          _conductores[index]['lat'] = data['lat'];
          _conductores[index]['lng'] = data['lng'];
        } else {
          _conductores.add(data);
        }
        _mensajeEstado = _conductores.isEmpty ? "No hay conductores activos" : "";
      });
    });

    _socket.on('ubicacion-conductor-desactivada', (data) {
      setState(() {
        _conductores.removeWhere((c) => c['conductorId'] == data['conductorId']);
        _mensajeEstado = _conductores.isEmpty ? "No hay conductores activos" : "";
      });
    });
  }

  Future<void> _cargarConductores() async {
    try {
      final conductores = await _conductorController.getConductoresActivos();
      setState(() {
        _conductores = conductores;
        _mensajeEstado = _conductores.isEmpty ? "No hay conductores activos" : "";
      });
    } catch (e) {
      setState(() {
        _mensajeEstado = "Error de conexión. Intenta nuevamente.";
      });
    }
  }

  @override
  void dispose() {
    _socket.dispose();
    _subscription?.cancel();
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
            onPressed: _cargarConductores,
          ),
        ],
      ),
      body: _mensajeEstado.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(ClienteStyles.spacing16),
          child: Text(
            _mensajeEstado,
            style: ClienteStyles.bodyText.copyWith(color: ClienteStyles.textSecondary),
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
          return InkWell(
            borderRadius: BorderRadius.circular(ClienteStyles.radiusLarge),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InfoConductorCliente(
                    conductorData: c,
                    socket: _socket,
                  ),
                ),
              );
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
                          'Lat: ${c['lat']?.toStringAsFixed(6)}, Lng: ${c['lng']?.toStringAsFixed(6)}',
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
