import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../controllers/cliente_controller.dart';

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

class _InfoConductorClienteState extends State<InfoConductorCliente> {
  final ClienteController _clienteController = ClienteController();
  Map<String, dynamic>? _infoConductor;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarInfo();
    widget.socket.on('ubicacion-conductor-desactivada', _handleUbicacionDesactivada);
  }

  void _handleUbicacionDesactivada(dynamic data) {
    final conductorId = data['conductorId'];
    if (conductorId == widget.conductorData['conductorId']) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El conductor ha desactivado su ubicación.')),
        );
      }
    }
  }

  Future<void> _cargarInfo() async {
    final id = widget.conductorData['conductorId'];
    final data = await _clienteController.fetchConductorDataSinShared(id);
    setState(() {
      _infoConductor = data;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    widget.socket.off('ubicacion-conductor-desactivada', _handleUbicacionDesactivada);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información del Conductor')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _infoConductor == null
              ? const Center(child: Text("No se pudo cargar la información."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nombre: ${_infoConductor!['nombre']}", style: const TextStyle(fontSize: 18)),
                      Text("Email: ${_infoConductor!['email']}", style: const TextStyle(fontSize: 16)),
                      Text("Teléfono: ${_infoConductor!['telefono']}", style: const TextStyle(fontSize: 16)),
                      Text("Vehículo: ${_infoConductor!['vehiculo'] ?? 'Sin asignar'}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funcionalidad en desarrollo')),
                            );
                          },
                          icon: const Icon(Icons.directions_car),
                          label: const Text("Solicitar Transporte"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}
