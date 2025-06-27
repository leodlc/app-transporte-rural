import 'package:flutter/material.dart';
import 'package:mobile/controllers/conductor_controller.dart';
import '../../controllers/admin_controller.dart';
import 'agregar_conductor.dart';

class ConductoresAdmin extends StatefulWidget {
  const ConductoresAdmin({super.key});

  @override
  _ConductoresAdminState createState() => _ConductoresAdminState();
}

class _ConductoresAdminState extends State<ConductoresAdmin> {
  final AdminController _adminController = AdminController();
  final ConductorController _conductorController = ConductorController();
  late Future<List<Map<String, dynamic>>> _conductoresFuture;

  @override
  void initState() {
    super.initState();
    _conductoresFuture = _adminController.fetchConductores();
  }

  Future<void> _toggleEstadoConductor(String conductorId, bool estadoActual) async {
    final actualizado = await _conductorController.updateConductor(conductorId, {
      'activo': !estadoActual,
    });

    if (actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estadoActual ? "Conductor bloqueado" : "Conductor desbloqueado")),
      );
      setState(() {
        _conductoresFuture = _adminController.fetchConductores();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar estado del conductor")),
      );
    }
  }


  Future<void> _asignarVehiculo(String conductorId) async {
    final vehiculosDisponibles =
        await _adminController.fetchVehiculosDisponibles();

    if (vehiculosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay vehículos disponibles")),
      );
      return;
    }

    String? vehiculoSeleccionado;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Selecciona un vehículo"),
            content: DropdownButton<String>(
              hint: const Text("Seleccionar vehículo"),
              value: vehiculoSeleccionado,
              items: vehiculosDisponibles
                  .map<DropdownMenuItem<String>>((vehiculo) {
                return DropdownMenuItem<String>(
                  value: vehiculo['_id'].toString(),
                  child: Text("${vehiculo['marca']} - ${vehiculo['placa']}"),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  vehiculoSeleccionado = value;
                });
              },
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (vehiculoSeleccionado != null) {
                    await _adminController.asignarVehiculoAConductor(
                        conductorId, vehiculoSeleccionado!);
                    setState(() {
                      _conductoresFuture = _adminController.fetchConductores();
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Asignar"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Conductores"), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conductoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay conductores disponibles"));
          }

          final conductores = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: conductores.length,
            itemBuilder: (context, index) {
              final conductor = conductores[index];
              final vehiculo = conductor['vehiculo'];

              bool tieneVehiculo = vehiculo != null &&
                  vehiculo is Map<String, dynamic> &&
                  vehiculo.containsKey('marca') &&
                  vehiculo.containsKey('placa');

              // Manejo seguro de datos con valores por defecto
              String vehiculoInfo = tieneVehiculo
                  ? "${vehiculo['marca']} - ${vehiculo['placa']}"
                  : "Sin vehículo asignado";

              // Validación para evitar que la tarjeta se rompa
              bool errorEnVehiculo =
                  vehiculo != null && vehiculo is! Map<String, dynamic>;

              return Card(
                color: errorEnVehiculo ? Colors.red[300] : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del conductor
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Conductor: ${conductor['nombre']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Email: ${conductor['email']}"),
                              Text("Teléfono: ${conductor['telefono']}"),
                              Text("Cooperativa: ${conductor['cooperativa']['nombre']}"),
                              if (errorEnVehiculo)
                                const Text(
                                  "Error cargando vehículo",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                )
                              else
                                Text(
                                  "Vehículo: $vehiculoInfo",
                                  style: TextStyle(
                                      color: tieneVehiculo ? Colors.green : Colors.orange),
                                ),
                            ],
                          ),
                        ),

                        // Botones de acción
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!tieneVehiculo)
                              ElevatedButton(
                                onPressed: () => _asignarVehiculo(conductor['_id']),
                                child: const Text("Asignar Vehículo", textAlign: TextAlign.center),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: conductor['activo'] ? Colors.red : Colors.green,
                              ),
                              onPressed: () => _toggleEstadoConductor(conductor['_id'], conductor['activo']),
                              child: Text(conductor['activo'] ? "Bloquear" : "Desbloquear"),
                            ),
                          ],
                        ),
                      ],
                    ),
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
