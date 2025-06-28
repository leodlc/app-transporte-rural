// clientes_admin.dart
import 'package:flutter/material.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente_model.dart';
import 'admin_styles.dart'; // Asegúrate de que la ruta sea correcta

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
    _recargarClientes();
  }

  void _recargarClientes() {
    setState(() {
      _clientesFuture = _clienteController.fetchAllClientes();
    });
  }

  Future<void> _toggleEstadoCliente(String clienteId, bool estadoActual) async {
    final actualizado = await _clienteController.updateCliente(clienteId, {'activo': !estadoActual});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actualizado
              ? (estadoActual ? "Cliente bloqueado" : "Cliente desbloqueado")
              : "Error al actualizar estado"),
          backgroundColor: actualizado ? AdminStyles.accentColor : Colors.red,
        ),
      );
      if (actualizado) {
        _recargarClientes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: const Text("Gestión de Clientes", style: TextStyle(color: AdminStyles.secondaryColor)),
        backgroundColor: AdminStyles.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AdminStyles.primaryColor));
          }
          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline,
              title: "Error al Cargar",
              message: "No se pudieron obtener los datos.",
              color: Colors.red,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const _EmptyState(
              icon: Icons.people_outline,
              title: "No hay clientes",
              message: "Los clientes se registrarán desde la app de usuario.",
            );
          }

          final clientes = snapshot.data!;
          return ListView.builder(
            padding: AdminStyles.listPadding,
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return _ClienteCard(
                cliente: cliente,
                onToggleStatus: () => _toggleEstadoCliente(cliente.id!, cliente.activo),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onToggleStatus;

  const _ClienteCard({required this.cliente, required this.onToggleStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AdminStyles.cardMargin,
      decoration: AdminStyles.cardBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(cliente.nombre, style: AdminStyles.cardTitle)),
                _StatusBadge(isActive: cliente.activo),
              ],
            ),
            const Divider(height: 16),
            _InfoRow(icon: Icons.account_circle_outlined, text: cliente.username),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, text: cliente.email),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: cliente.telefono ?? 'Sin teléfono'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(cliente.activo ? Icons.lock_outline : Icons.lock_open_outlined),
                label: Text(cliente.activo ? "Bloquear" : "Desbloquear"),
                style: TextButton.styleFrom(
                  foregroundColor: cliente.activo ? Colors.red : AdminStyles.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Activo' : 'Bloqueado',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Colors.grey[600];
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AdminStyles.cardSubtitle.copyWith(color: iconColor))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Color color;
  const _EmptyState({required this.title, required this.message, required this.icon, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}