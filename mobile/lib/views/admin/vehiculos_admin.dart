import 'package:flutter/material.dart';
import '../../controllers/admin_controller.dart';
import 'agregar_vehiculo.dart';

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
    _vehiculosFuture = _adminController.fetchVehiculos();
  }

  Future<void> _eliminarVehiculo(String vehiculoId) async {
    bool success = await _adminController.eliminarVehiculo(vehiculoId);
    if (success) {
      setState(() {
        _vehiculosFuture = _adminController.fetchVehiculos();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehículo eliminado")),
      );
    }
  }

  Future<void> _irAgregarVehiculo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarVehiculo(),
      ),
    );

    if (result == true) {
      setState(() {
        _vehiculosFuture = _adminController.fetchVehiculos();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Vehículos"), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehiculosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay vehículos disponibles"));
          }

          final vehiculos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: vehiculos.length,
            itemBuilder: (context, index) {
              final vehiculo = vehiculos[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: ListTile(
                  title: Text("Placa: ${vehiculo['placa']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Marca: ${vehiculo['marca']}"),
                      Text("Modelo: ${vehiculo['modelo']}"),
                      Text("RMT: ${vehiculo['rmt']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarVehiculo(vehiculo['_id']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irAgregarVehiculo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
