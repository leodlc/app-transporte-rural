import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/notificacion_controller.dart';

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
  final NotificacionController _notificacionController = NotificacionController();
  final ClienteController _clienteController = ClienteController();
  Map<String, dynamic>? _infoConductor;
  bool _cargando = true;
  bool _solicitudEnviada = false;

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
    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('id');

    if (clienteId == null) {
      setState(() {
        _cargando = false;
      });
      return;
    }

    final data = await _clienteController.fetchConductorDataSinShared(id);

    // Nueva lógica: verificar si ya hay solicitud pendiente
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


  @override
  void dispose() {
    widget.socket.off('ubicacion-conductor-desactivada', _handleUbicacionDesactivada);
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clienteId = prefs.getString('id');
      final nombreCliente = prefs.getString('nombre') ?? 'Cliente Desconocido';
      final conductorId = widget.conductorData['conductorId'];

      if (clienteId == null) throw Exception("Cliente no logueado");

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/crear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clienteId': clienteId,
          'conductorId': conductorId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Error creando solicitud: ${response.body}");
      }

      // Enviar notificación
      await _notificacionController.enviarNotificacion(
        emisorId: clienteId!,
        rolEmisor: 'cliente',
        usuarioId: conductorId,
        rol: 'conductor',
        titulo: 'Nueva solicitud de transporte',
        cuerpo: 'El cliente $nombreCliente ha solicitado un viaje.',
      );


      // ✅ Confirmar con backend que ya existe la solicitud pendiente
      final check = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/existe-pendiente?clienteId=$clienteId&conductorId=$conductorId'),
      );
      final json = jsonDecode(check.body);
      final existe = json['existe'] == true;

      setState(() {
        _solicitudEnviada = existe;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada. Se notificó al conductor.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar solicitud: $e')),
        );
      }
    }
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
                      if (_infoConductor!['vehiculo'] != null) ...[
                        Text("Vehículo: ${_infoConductor!['vehiculo']['modelo']}", style: const TextStyle(fontSize: 16)),
                        Text("Placa: ${_infoConductor!['vehiculo']['placa']}", style: const TextStyle(fontSize: 16)),
                        Text("RMT: ${_infoConductor!['vehiculo']['rmt']}", style: const TextStyle(fontSize: 16)),
                      ] else ...[
                        const Text("Vehículo: Sin asignar", style: TextStyle(fontSize: 16)),
                      ],

                      const SizedBox(height: 24),
                      _solicitudEnviada
                        ? Text(
                            "Notificación enviada al conductor ${_infoConductor!['nombre']}, esperando su respuesta. Puede tardar hasta 5 minutos.",
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          )
                        : Center(
                            child: ElevatedButton.icon(
                              onPressed: _enviarSolicitud,
                              icon: const Icon(Icons.directions_car),
                              label: const Text("Solicitar Transporte"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }
}
