import 'package:flutter/material.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente_model.dart';

class ClientesAdmin extends StatefulWidget {
  const ClientesAdmin({super.key});

  @override
  State<ClientesAdmin> createState() => _ClientesAdminState();
}

class _ClientesAdminState extends State<ClientesAdmin> {
  final ClienteController _clienteController = ClienteController();
  late Future<List<Cliente>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    _clientesFuture = _clienteController.fetchAllClientes();
  }

  Future<void> _toggleEstadoCliente(String clienteId, bool estadoActual) async {
    final actualizado = await _clienteController.updateCliente(clienteId, {
      'activo': !estadoActual,
    });

    if (actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estadoActual ? "Cliente bloqueado" : "Cliente desbloqueado")),
      );
      setState(() {
        _clientesFuture = _clienteController.fetchAllClientes();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar estado del cliente")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Clientes")),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay clientes disponibles"));
          }

          final clientes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: ListTile(
                  title: Text("Cliente: ${cliente.nombre}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nombre de Usuario: ${cliente.username ?? 'N/A'}"),
                      Text("Email: ${cliente.email ?? 'N/A'}"),
                      Text("Teléfono: ${cliente.telefono ?? 'N/A'}"),
                      Text("Estado: ${cliente.activo ? 'Activo' : 'Bloqueado'}",
                          style: TextStyle(
                            color: cliente.activo ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cliente.activo ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _toggleEstadoCliente(cliente.id!, cliente.activo),
                    child: Text(cliente.activo ? "Bloquear" : "Desbloquear"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
