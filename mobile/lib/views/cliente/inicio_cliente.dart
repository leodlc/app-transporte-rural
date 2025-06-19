import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/api_config.dart'; // Asumo que tienes este archivo con la baseUrl
import '../../widgets/agregarUbicacionCliente.dart';

class InicioCliente extends StatefulWidget {
  const InicioCliente({super.key});

  @override
  State<InicioCliente> createState() => _InicioClienteState();
}

class _InicioClienteState extends State<InicioCliente> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    // Usa la url base desde ApiConfig para mantener centralizado
    socket = IO.io(ApiConfig.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.connect();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio Cliente"),
      ),
      body: Center(
        child: AgregarUbicacionCliente(socket: socket),
      ),
    );
  }
}
