import 'package:flutter/material.dart';
import 'package:mobile/controllers/cooperativa_controller.dart';
import 'formulario_cooperativa.dart';
import 'admin_styles.dart';

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
    _recargarCooperativas();
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta cooperativa? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AdminStyles.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmacion == true) {
      // Aquí iría la lógica para mostrar un snackbar de éxito o error
      await _cooperativaController.deleteCooperativa(id);
      _recargarCooperativas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cooperativa eliminada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyles.backgroundColor,
      appBar: AppBar(
        title: const Text(AdminStyles.appTitle, style: TextStyle(color: AdminStyles.secondaryColor)),
        backgroundColor: AdminStyles.primaryColor,
        automaticallyImplyLeading: false, // Oculta el botón de regreso si no es necesario
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cooperativasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AdminStyles.primaryColor));
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: "Error al cargar",
              message: "No se pudieron obtener los datos. Inténtalo de nuevo.",
              color: Colors.red,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _EmptyState(
              icon: Icons.business_outlined,
              title: "No hay cooperativas",
              message: "Presiona el botón '+' para agregar la primera.",
              color: Colors.grey,
            );
          }

          final cooperativas = snapshot.data!;
          return ListView.builder(
            padding: AdminStyles.listPadding,
            itemCount: cooperativas.length,
            itemBuilder: (context, index) {
              final coop = cooperativas[index];
              return _CooperativaCard(
                cooperativa: coop,
                onEdit: () => _mostrarFormulario(cooperativa: coop),
                onDelete: () => _eliminarCooperativa(coop['_id']),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: AdminStyles.accentColor,
        child: AdminStyles.fabAddIcon,
        tooltip: 'Agregar Cooperativa',
      ),
    );
  }
}

// WIDGET PARA LA TARJETA DE CADA COOPERATIVA
class _CooperativaCard extends StatelessWidget {
  final Map<String, dynamic> cooperativa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CooperativaCard({
    required this.cooperativa,
    required this.onEdit,
    required this.onDelete,
  });

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
            Text(cooperativa['nombre'] ?? 'Sin nombre', style: AdminStyles.cardTitle),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, text: cooperativa['email'] ?? 'No especificado'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.person_outline, text: cooperativa['responsable'] ?? 'No especificado'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on_outlined, text: cooperativa['ubicacion'] ?? 'No especificada'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: cooperativa['telefono'] ?? 'No especificado'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: AdminStyles.editIcon, onPressed: onEdit, tooltip: 'Editar'),
                IconButton(icon: AdminStyles.deleteIcon, onPressed: onDelete, tooltip: 'Eliminar'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET HELPER PARA MOSTRAR UNA FILA DE INFORMACIÓN CON ÍCONO
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AdminStyles.cardSubtitle)),
      ],
    );
  }
}

// WIDGET PARA MOSTRAR CUANDO LA LISTA ESTÁ VACÍA O HAY UN ERROR
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
    );
  }
}