import 'package:flutter/material.dart';
import '../../controllers/solicitud_controller.dart';
import '../../controllers/notificacion_controller.dart';

class InfoSolicitud extends StatefulWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onUpdate;

  const InfoSolicitud({super.key, required this.solicitud, required this.onUpdate});

  @override
  State<InfoSolicitud> createState() => _InfoSolicitudState();
}

class _InfoSolicitudState extends State<InfoSolicitud> {
  final SolicitudController _solicitudController = SolicitudController();
  final NotificacionController _notificacionController = NotificacionController();

  @override
  void initState() {
    super.initState();
    _imprimirDatosDebug();
  }

  void _imprimirDatosDebug() {
    final cliente = widget.solicitud['clienteId'];
    final tokens = cliente['tokenFCM'] as List<dynamic>?;

    final emisorId = widget.solicitud['conductorId'];
    final receptorId = cliente['_id'];
    final tokenList = tokens ?? [];
    final ultimoToken = tokenList.isNotEmpty ? tokenList.last : 'Sin token disponible';

    print('🔵 Emisor (conductor): $emisorId');
    print('🟢 Receptor (cliente): $receptorId');
    print('📨 Tokens FCM del cliente: $tokenList');
    print('📍 Último token FCM del cliente (para enviar): $ultimoToken');
  }

  void _cambiarEstado(BuildContext context, String nuevoEstado) async {
    try {
      await _solicitudController.actualizarEstadoSolicitud(
        solicitudId: widget.solicitud['_id'],
        nuevoEstado: nuevoEstado,
      );

      final cliente = widget.solicitud['clienteId'];
      final tokenFCMList = cliente['tokenFCM'] as List<dynamic>?;

      if (tokenFCMList == null || tokenFCMList.isEmpty) {
        throw Exception('El cliente no tiene tokens FCM registrados');
      }

      final ultimoToken = tokenFCMList.last;

      await _notificacionController.enviarNotificacion(
        emisorId: widget.solicitud['conductorId'],
        rolEmisor: 'conductor',
        usuarioId: cliente['_id'],
        rol: 'cliente',
        titulo: 'Solicitud $nuevoEstado',
        cuerpo: 'Tu solicitud fue $nuevoEstado por el conductor.',
        // tokenFCM: ultimoToken, // si el backend lo usara directamente
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud $nuevoEstado exitosamente')),
      );

      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.solicitud['clienteId'];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Solicitud')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cliente: ${cliente['nombre']}", style: const TextStyle(fontSize: 18)),
            Text("Teléfono: ${cliente['telefono']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _cambiarEstado(context, 'aceptada'),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Aceptar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => _cambiarEstado(context, 'rechazada'),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Rechazar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
