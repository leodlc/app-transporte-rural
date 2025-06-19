import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../widgets/agregarUbicacion.dart';
import '../../config/api_config.dart';  // <-- Importa tu config aquí

class InicioConductor extends StatefulWidget {
  const InicioConductor({super.key});

  @override
  State<InicioConductor> createState() => _InicioConductorState();
}

class _InicioConductorState extends State<InicioConductor> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();

    // Usa baseUrl para la conexión websocket
    socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AgregarUbicacion(socket: socket);
  }
}
