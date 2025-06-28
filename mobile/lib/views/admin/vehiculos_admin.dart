// vehiculos_admin.dart
import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';
import 'agregar_vehiculo.dart';
import 'admin_styles.dart'; // Asegúrate de que la ruta sea correcta

class VehiculosAdmin extends StatefulWidget {
  const VehiculosAdmin({super.key});

  @override
  _VehiculosAdminState createState() => _VehiculosAdminState();
}

class _VehiculosAdminState extends State<VehiculosAdmin> {
  final AdminController _adminController = AdminController();
  late Future<List<Map<String, dynamic>>> _vehiculosFuture;

  @override
  void initState() {
    super.initState();
    _recargarVehiculos();
  }

  void _recargarVehiculos() {
    setState(() {
      _vehiculosFuture = _adminController.fetchVehiculos();
    });
  }

  Future<void> _eliminarVehiculo(String vehiculoId) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AdminStyles.primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      bool success = await _adminController.eliminarVehiculo(vehiculoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Vehículo eliminado" : "Error al eliminar"),
            backgroundColor: success ? AdminStyles.accentColor : Colors.red,
          ),
        );
        if (success) {
          _recargarVehiculos();
        }
      }
    }
  }

  Future<void> _irAgregarVehiculo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarVehiculo()),
    );
    if (result == true) {
      _recargarVehiculos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: const Text("Gestión de Vehículos", style: TextStyle(color: AdminStyles.secondaryColor)),
        backgroundColor: AdminStyles.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehiculosFuture,
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
              icon: Icons.no_transfer_outlined,
              title: "No hay vehículos",
              message: "Presiona '+' para agregar el primero.",
            );
          }

          final vehiculos = snapshot.data!;
          return ListView.builder(
            padding: AdminStyles.listPadding,
            itemCount: vehiculos.length,
            itemBuilder: (context, index) {
              final vehiculo = vehiculos[index];
              return _VehiculoCard(
                vehiculo: vehiculo,
                onDelete: () => _eliminarVehiculo(vehiculo['_id']),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irAgregarVehiculo,
        backgroundColor: AdminStyles.accentColor,
        child: AdminStyles.fabAddIcon,
        tooltip: 'Agregar Vehículo',
      ),
    );
  }
}

class _VehiculoCard extends StatelessWidget {
  final Map<String, dynamic> vehiculo;
  final VoidCallback onDelete;

  const _VehiculoCard({required this.vehiculo, required this.onDelete});

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
            Text("Placa: ${vehiculo['placa'] ?? 'N/A'}", style: AdminStyles.cardTitle),
            const Divider(height: 16),
            _InfoRow(icon: Icons.label_outline, text: "Marca: ${vehiculo['marca'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            _InfoRow(icon: AdminStyles.vehiculosIcon.icon!, text: "Modelo: ${vehiculo['modelo'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.confirmation_number_outlined, text: "RMT: ${vehiculo['rmt'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: AdminStyles.deleteIcon,
                onPressed: onDelete,
                tooltip: 'Eliminar Vehículo',
              ),
            ),
          ],
        ),
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
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.color = Colors.grey,
  });

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