import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/bloc/notifications_bloc.dart';
import '../../controllers/solicitud_controller.dart';
import 'info_solicitud.dart';

class SolicitudesConductor extends StatefulWidget {
  const SolicitudesConductor({super.key});

  @override
  _SolicitudesConductorState createState() => _SolicitudesConductorState();
}

class _SolicitudesConductorState extends State<SolicitudesConductor> {
  late NotificationsBloc _notificationsBloc;
  final SolicitudController _solicitudController = SolicitudController();

  List<Map<String, dynamic>> _solicitudes = [];
  bool _isLoading = true;

  String? _conductorId;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = context.read<NotificationsBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notificationsBloc.add(RequestPermissions());
      await _obtenerConductorId();
      if (_conductorId != null) {
        await _cargarSolicitudes();
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

  Future<void> _obtenerConductorId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    setState(() {
      _conductorId = id;
    });
  }

  Future<void> _cargarSolicitudes() async {
    if (_conductorId == null) return;

    try {
      final solicitudes = await _solicitudController.getSolicitudesPorConductor(_conductorId!);
      setState(() {
        _solicitudes = solicitudes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando solicitudes: $e')),
      );
    }
  }

  void _refrescar() => _cargarSolicitudes();

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
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _cargarSolicitudes();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _solicitudes.isEmpty
                ? const Center(child: Text('No hay solicitudes pendientes'))
                : RefreshIndicator(
                    onRefresh: _cargarSolicitudes,
                    child: ListView.builder(
                      itemCount: _solicitudes.length,
                      itemBuilder: (context, index) {
                        final solicitud = _solicitudes[index];
                        final cliente = solicitud['clienteId'];

                        return ListTile(
                          title: Text(cliente['nombre'] ?? 'Sin nombre'),
                          subtitle: Text(cliente['telefono'] ?? 'Sin teléfono'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InfoSolicitud(
                                  solicitud: solicitud,
                                  onUpdate: _refrescar,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
