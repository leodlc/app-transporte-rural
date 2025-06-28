// conductores_admin.dart
import 'package:flutter/material.dart';
import 'package:mobile/controllers/conductor_controller.dart';
import '../../controllers/admin_controller.dart';
import 'admin_styles.dart'; // Asegúrate de que la ruta sea correcta

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
    _recargarConductores();
  }

  void _recargarConductores() {
    setState(() {
      _conductoresFuture = _adminController.fetchConductores();
    });
  }

  Future<void> _toggleEstadoConductor(String conductorId, bool estadoActual) async {
    final actualizado = await _conductorController.updateConductor(conductorId, {'activo': !estadoActual});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(actualizado ? (estadoActual ? "Conductor bloqueado" : "Conductor desbloqueado") : "Error al actualizar"),
          backgroundColor: actualizado ? AdminStyles.accentColor : Colors.red,
        ),
      );
      if (actualizado) _recargarConductores();
    }
  }

  Future<void> _asignarVehiculo(String conductorId) async {
    final vehiculosDisponibles = await _adminController.fetchVehiculosDisponibles();
    if (!mounted) return;
    if (vehiculosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay vehículos disponibles para asignar")));
      return;
    }

    String? vehiculoSeleccionado;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Seleccionar Vehículo"),
            content: DropdownButtonFormField<String>(
              value: vehiculoSeleccionado,
              hint: const Text("Elige una placa"),
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: vehiculosDisponibles.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(value: v['_id'], child: Text("${v['marca']} - ${v['placa']}"));
              }).toList(),
              onChanged: (value) => setDialogState(() => vehiculoSeleccionado = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: AdminStyles.primaryColor)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (vehiculoSeleccionado != null) {
                    await _adminController.asignarVehiculoAConductor(conductorId, vehiculoSeleccionado!);
                    if (mounted) Navigator.pop(context);
                    _recargarConductores();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AdminStyles.accentColor),
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
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: const Text("Gestión de Conductores", style: TextStyle(color: AdminStyles.secondaryColor)),
        backgroundColor: AdminStyles.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conductoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AdminStyles.primaryColor));
          }
          if (snapshot.hasError) {
            return const _EmptyState(
                icon: Icons.error_outline, title: "Error", message: "No se pudieron obtener los datos.", color: Colors.red);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const _EmptyState(
                icon: Icons.person_search_outlined, title: "No hay conductores", message: "Primero se deben registrar conductores.");
          }

          final conductores = snapshot.data!;
          return ListView.builder(
            padding: AdminStyles.listPadding,
            itemCount: conductores.length,
            itemBuilder: (context, index) {
              final conductor = conductores[index];
              return _ConductorCard(
                conductor: conductor,
                onToggleStatus: () => _toggleEstadoConductor(conductor['_id'], conductor['activo']),
                onAssignVehicle: () => _asignarVehiculo(conductor['_id']),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConductorCard extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final VoidCallback onToggleStatus;
  final VoidCallback onAssignVehicle;

  const _ConductorCard({required this.conductor, required this.onToggleStatus, required this.onAssignVehicle});

  @override
  Widget build(BuildContext context) {
    final vehiculo = conductor['vehiculo'];
    bool tieneVehiculo = vehiculo != null && vehiculo is Map<String, dynamic>;
    final vehiculoInfo = tieneVehiculo ? "${vehiculo['marca']} - ${vehiculo['placa']}" : "Sin vehículo asignado";
    final cooperativaNombre = conductor['cooperativa']?['nombre'] ?? 'Sin cooperativa';

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
                Expanded(child: Text(conductor['nombre'] ?? 'Sin nombre', style: AdminStyles.cardTitle)),
                _StatusBadge(isActive: conductor['activo'] ?? false),
              ],
            ),
            const Divider(height: 16),
            _InfoRow(icon: Icons.email_outlined, text: conductor['email'] ?? 'N/A'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: conductor['telefono'] ?? 'N/A'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.business_outlined, text: cooperativaNombre),
            const SizedBox(height: 8),
            _InfoRow(
              icon: tieneVehiculo ? AdminStyles.vehiculosIcon.icon! : Icons.car_crash_outlined,
              text: vehiculoInfo,
              color: tieneVehiculo ? Colors.grey[600] : Colors.orange,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!tieneVehiculo)
                  TextButton.icon(
                    onPressed: onAssignVehicle,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Asignar Vehículo"),
                    style: TextButton.styleFrom(foregroundColor: AdminStyles.primaryColor),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(conductor['activo'] ? Icons.lock_outline : Icons.lock_open_outlined),
                  label: Text(conductor['activo'] ? "Bloquear" : "Desbloquear"),
                  style: TextButton.styleFrom(
                      foregroundColor: conductor['activo'] ? Colors.red : AdminStyles.accentColor),
                ),
              ],
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