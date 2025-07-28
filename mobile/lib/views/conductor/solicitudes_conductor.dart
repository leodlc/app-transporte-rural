import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _isConnected = _socketManager.socket != null;
    _notificationsBloc = context.read<NotificationsBloc>();
    _inicializarSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notificationsBloc.add(RequestPermissions());
      await _obtenerConductorId();
      if (_conductorId != null) {
        // Emitir solicitud después de obtener el ID
        _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró ID de conductor')),
        );
      }
    });
  }

  void _inicializarSocket() {
    _socketManager.on('solicitud:lista', (data) {
      print('solicitud:lista recibida:');
      print(data);

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
        print('Error al procesar solicitudes: $e');
        setState(() {
          _isLoading = false;
        });
      }
    });

    _socketManager.on('solicitud:nueva', (data) {
      print('Nueva solicitud recibida: $data');

      if (data is Map<String, dynamic>) {
        setState(() {
          _solicitudes.add(data);
        });
      }
    });
  }

  Future<void> _obtenerConductorId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    setState(() {
      _conductorId = id;
    });
  }

  // Método para obtener información del cliente de forma segura
  Map<String, String> _obtenerInfoCliente(Map<String, dynamic> solicitud) {
    // Opción 1: Si clienteId es un objeto completo
    if (solicitud['clienteId'] is Map<String, dynamic>) {
      final cliente = solicitud['clienteId'] as Map<String, dynamic>;
      return {
        'nombre': cliente['nombre']?.toString() ?? 'Sin nombre',
        'telefono': cliente['telefono']?.toString() ?? 'Sin teléfono',
      };
    }

    // Opción 2: Si tienes los datos directamente en la solicitud
    else if (solicitud.containsKey('clienteNombre') || solicitud.containsKey('nombre')) {
      return {
        'nombre': solicitud['clienteNombre']?.toString() ??
            solicitud['nombre']?.toString() ?? 'Sin nombre',
        'telefono': solicitud['clienteTelefono']?.toString() ??
            solicitud['telefono']?.toString() ?? 'Sin teléfono',
      };
    }

    // Opción 3: Si solo tienes el ID del cliente
    else {
      return {
        'nombre': 'Cliente ID: ${solicitud['clienteId'] ?? 'Desconocido'}',
        'telefono': 'Sin información disponible',
      };
    }
  }

  Widget _buildSolicitudItem(Map<String, dynamic> solicitud, int index) {
    final infoCliente = _obtenerInfoCliente(solicitud);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          infoCliente['nombre']!,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(infoCliente['telefono']!),
            if (solicitud['origen'] != null)
              Text(
                'Origen: ${solicitud['origen']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (solicitud['destino'] != null)
              Text(
                'Destino: ${solicitud['destino']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InfoSolicitud(
                solicitud: solicitud,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listener: (context, state) {
        if (state is NotificationsPermissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de notificaciones concedidos')),
          );
        } else if (state is NotificationsPermissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de notificaciones denegados')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solicitudes pendientes'),
          actions: [
            IconButton(
              icon: const Icon(
                  Icons.refresh,
                color: Colors.green,
              ),
              tooltip: 'Recargar',
              onPressed: () {
                if (_conductorId != null) {
                  setState(() {
                    _isLoading = true;
                  });
                  _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID de conductor no disponible')),
                  );
                }
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _solicitudes.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay solicitudes pendientes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _solicitudes.length,
          itemBuilder: (context, index) {
            final solicitud = _solicitudes[index];
            final cliente = solicitud['clienteId'];

            return _buildSolicitudItem(solicitud, index);

          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar listeners del socket si es necesario
    _socketManager.off('solicitud:lista');
    _socketManager.off('solicitud:nueva');
    super.dispose();
  }
}