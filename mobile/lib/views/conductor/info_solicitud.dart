import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';
import 'package:mobile/ws/SocketManager.dart';
import '../../controllers/notificacion_controller.dart';

class InfoSolicitud extends StatefulWidget {
  final Map<String, dynamic> solicitud;

  const InfoSolicitud({super.key, required this.solicitud});

  @override
  State<InfoSolicitud> createState() => _InfoSolicitudState();
}

class _InfoSolicitudState extends State<InfoSolicitud> {
  final SocketManager _socketManager = SocketManager.instance;
  final NotificacionController _notificacionController = NotificacionController();
  String? _conductorId;

  @override
  void initState() {
    super.initState();
    _imprimirDatosDebug();
    _conductorId = widget.solicitud['conductorId'];
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
    final cliente = widget.solicitud['clienteId'];

    void _onSolicitudError(error) {
      _socketManager.off('solicitud:error', _onSolicitudError);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al $nuevoEstado solicitud: $error'),
            backgroundColor: ConductorStyles.errorColor,
          ),
        );
      }
    }

    void _onSolicitudActualizar(data) {
      _socketManager.off('solicitud:estadoActualizado', _onSolicitudActualizar);
      _socketManager.off('solicitud:error', _onSolicitudError);


      // Notificación push (opcional)
      _notificacionController.enviarNotificacion(
        emisorId: widget.solicitud['conductorId'],
        rolEmisor: 'conductor',
        usuarioId: cliente['_id'],
        rol: 'cliente',
        titulo: 'Solicitud $nuevoEstado',
        cuerpo: 'Tu solicitud fue $nuevoEstado por el conductor.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud $nuevoEstado exitosamente')),
        );
      }

      _socketManager.emit('solicitud:obtener', {'conductorId': _conductorId});

      Navigator.pop(context);
    }

    _socketManager.on('solicitud:estadoActualizado', _onSolicitudActualizar);
    _socketManager.on('solicitud:error', _onSolicitudError);

    _socketManager.emit('solicitud:actualizar', {'solicitudId': widget.solicitud['_id'],
        'estado': nuevoEstado});

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
