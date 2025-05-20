import 'package:flutter/material.dart';
import 'package:mobile/controllers/cooperativa_controller.dart';
import '../../controllers/admin_controller.dart';
import 'formulario_cooperativa.dart'; // Asegúrate de crear esta pantalla

class CooperativasAdmin extends StatefulWidget {
  const CooperativasAdmin({super.key});

  @override
  _CooperativasAdminState createState() => _CooperativasAdminState();
}

class _CooperativasAdminState extends State<CooperativasAdmin> {
  final CooperativaController _cooperativaController = CooperativaController();

  late Future<List<Map<String, dynamic>>> _cooperativasFuture;

  @override
  void initState() {
    super.initState();
    _cooperativasFuture = _cooperativaController.fetchAllCooperativas();
  }

  void _recargarCooperativas() {
    setState(() {
      _cooperativasFuture = _cooperativaController.fetchAllCooperativas();
    });
  }

  void _mostrarFormulario({Map<String, dynamic>? cooperativa}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioCooperativa(
          cooperativa: cooperativa,
          onGuardar: _recargarCooperativas,
        ),
      ),
    );
  }

  Future<void> _eliminarCooperativa(String id) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta cooperativa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      await _cooperativaController.deleteCooperativa(id);
      _recargarCooperativas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Cooperativas")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cooperativasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay cooperativas registradas"));
          }

          final cooperativas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: cooperativas.length,
            itemBuilder: (context, index) {
              final coop = cooperativas[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: ListTile(
                  title: Text("Cooperativa: ${coop['nombre']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${coop['email']}"),
                      Text("Responsable: ${coop['responsable']}"),
                      Text("Ubicación: ${coop['ubicacion']}"),
                      Text("Teléfono: ${coop['telefono']}"),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarFormulario(cooperativa: coop),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarCooperativa(coop['_id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
