import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/notificacion_controller.dart';
import 'cliente_styles.dart';

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
  bool _enviandoSolicitud = false;

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
          SnackBar(
            content: const Text('El conductor ha desactivado su ubicación.'),
            backgroundColor: ClienteStyles.warningColor,
          ),
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
    setState(() {
      _enviandoSolicitud = true;
    });

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

      await _notificacionController.enviarNotificacion(
        emisorId: clienteId!,
        rolEmisor: 'cliente',
        usuarioId: conductorId,
        rol: 'conductor',
        titulo: 'Nueva solicitud de transporte',
        cuerpo: 'El cliente $nombreCliente ha solicitado un viaje.',
      );

      final check = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/1.0/solicitudTransporte/existe-pendiente?clienteId=$clienteId&conductorId=$conductorId'),
      );
      final json = jsonDecode(check.body);
      final existe = json['existe'] == true;

      setState(() {
        _solicitudEnviada = existe;
        _enviandoSolicitud = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Solicitud enviada. Se notificó al conductor.'),
            backgroundColor: ClienteStyles.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _enviandoSolicitud = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClienteStyles.spacing8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ClienteStyles.spacing8),
            decoration: BoxDecoration(
              color: ClienteStyles.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ClienteStyles.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: ClienteStyles.primaryGreen,
            ),
          ),
          SizedBox(width: ClienteStyles.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ClienteStyles.labelText,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: ClienteStyles.bodyText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: Text(
          'Información del Conductor',
          style: ClienteStyles.appBarTitle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: ClienteStyles.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _cargando
          ? Center(
        child: CircularProgressIndicator(
          color: ClienteStyles.primaryGreen,
        ),
      )
          : _infoConductor == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: ClienteStyles.textSecondary,
            ),
            SizedBox(height: ClienteStyles.spacing16),
            Text(
              "No se pudo cargar la información",
              style: ClienteStyles.bodyText,
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(ClienteStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de información del conductor
            Container(
              decoration: ClienteStyles.cardDecoration,
              child: Column(
                children: [
                  // Header con avatar
                  Container(
                    padding: const EdgeInsets.all(ClienteStyles.spacing24),
                    decoration: BoxDecoration(
                      color: ClienteStyles.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ClienteStyles.radiusLarge),
                        topRight: Radius.circular(ClienteStyles.radiusLarge),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: ClienteStyles.primaryGreen,
                          child: Text(
                            _infoConductor!['nombre'][0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: ClienteStyles.surfaceWhite,
                            ),
                          ),
                        ),
                        SizedBox(height: ClienteStyles.spacing16),
                        Text(
                          _infoConductor!['nombre'],
                          style: ClienteStyles.cardTitle,
                        ),
                        SizedBox(height: ClienteStyles.spacing8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ClienteStyles.spacing12,
                            vertical: ClienteStyles.spacing8,
                          ),
                          decoration: ClienteStyles.chipDecoration(
                            color: ClienteStyles.primaryNavy,
                          ),
                          child: Text(
                            'Conductor Verificado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ClienteStyles.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información de contacto
                  Padding(
                    padding: const EdgeInsets.all(ClienteStyles.spacing24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de contacto',
                          style: ClienteStyles.cardTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: ClienteStyles.spacing16),
                        _buildInfoRow(
                          'Correo electrónico',
                          _infoConductor!['email'],
                          Icons.email_outlined,
                        ),
                        _buildInfoRow(
                          'Teléfono',
                          _infoConductor!['telefono'],
                          Icons.phone_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ClienteStyles.spacing16),

            // Tarjeta de información del vehículo
            Container(
              decoration: ClienteStyles.cardDecoration,
              padding: const EdgeInsets.all(ClienteStyles.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        color: ClienteStyles.primaryGreen,
                      ),
                      SizedBox(width: ClienteStyles.spacing8),
                      Text(
                        'Información del vehículo',
                        style: ClienteStyles.cardTitle.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ClienteStyles.spacing16),
                  if (_infoConductor!['vehiculo'] != null) ...[
                    _buildInfoRow(
                      'Modelo',
                      _infoConductor!['vehiculo']['modelo'],
                      Icons.directions_car_outlined,
                    ),
                    _buildInfoRow(
                      'Placa',
                      _infoConductor!['vehiculo']['placa'],
                      Icons.pin_outlined,
                    ),
                    _buildInfoRow(
                      'RMT',
                      _infoConductor!['vehiculo']['rmt'],
                      Icons.verified_outlined,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(ClienteStyles.spacing16),
                      decoration: BoxDecoration(
                        color: ClienteStyles.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: ClienteStyles.warningColor,
                            size: 20,
                          ),
                          SizedBox(width: ClienteStyles.spacing8),
                          Text(
                            'Vehículo sin asignar',
                            style: TextStyle(
                              color: ClienteStyles.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: ClienteStyles.spacing24),

            // Estado de solicitud o botón
            if (_solicitudEnviada) ...[
              Container(
                padding: const EdgeInsets.all(ClienteStyles.spacing20),
                decoration: BoxDecoration(
                  color: ClienteStyles.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                  border: Border.all(
                    color: ClienteStyles.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: ClienteStyles.accentBlue,
                      size: 48,
                    ),
                    SizedBox(height: ClienteStyles.spacing16),
                    Text(
                      'Solicitud enviada',
                      style: ClienteStyles.cardTitle.copyWith(
                        color: ClienteStyles.accentBlue,
                      ),
                    ),
                    SizedBox(height: ClienteStyles.spacing8),
                    Text(
                      'Notificación enviada al conductor ${_infoConductor!['nombre']}.\nEsperando respuesta (puede tardar hasta 5 minutos).',
                      style: ClienteStyles.bodyText.copyWith(
                        fontSize: 14,
                        color: ClienteStyles.accentBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _enviandoSolicitud ? null : _enviarSolicitud,
                  icon: _enviandoSolicitud
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ClienteStyles.surfaceWhite,
                      ),
                    ),
                  )
                      : Icon(Icons.directions_car_rounded),
                  label: Text(
                    _enviandoSolicitud ? 'Enviando...' : 'Solicitar Transporte',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ClienteStyles.primaryButtonStyle.copyWith(
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: ClienteStyles.spacing32),
          ],
        ),
      ),
    );
  }
}