import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/cliente_controller.dart';
import 'cliente_styles.dart';
import 'editar_perfil_cliente.dart';

class PerfilCliente extends StatefulWidget {
  final VoidCallback? onPerfilActualizado;
  const PerfilCliente({super.key, this.onPerfilActualizado});

  @override
  State<PerfilCliente> createState() => _PerfilClienteState();
}

class _PerfilClienteState extends State<PerfilCliente> {
  final ClienteController _clienteController = ClienteController();

  String nombre = "Cargando...";
  String email = "Cargando...";
  String telefono = "Cargando...";
  String rol = "CLIENTE";
  String? id;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final clienteId = prefs.getString('id');
    if (clienteId != null) {
      final data = await _clienteController.fetchClienteData(clienteId);
      if (data != null) {
        setState(() {
          id = data['_id'];
          nombre = data['nombre'] ?? "Sin nombre";
          email = data['email'] ?? "Sin email";
          telefono = data['telefono'] ?? "Sin teléfono";
          rol = data['rol']?.toUpperCase() ?? "CLIENTE";
        });
      }
    }
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    String initials = names.isNotEmpty ? names[0][0].toUpperCase() : 'U';
    if (names.length > 1) initials += names.last[0].toUpperCase();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClienteStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: ClienteStyles.surfaceWhite,
        elevation: 0,
        title: const Text("Mi Perfil", style: ClienteStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar perfil',
            onPressed: _cargarPerfil,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClienteStyles.spacing20),
        child: Column(
          children: [
            Center(
              child: ClienteStyles.drawerAvatar(
                initials: _getInitials(nombre),
              ),
            ),
            const SizedBox(height: ClienteStyles.spacing16),
            Text(nombre, style: ClienteStyles.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: ClienteStyles.spacing8),
            Text(email, style: ClienteStyles.cardSubtitle),
            const SizedBox(height: 4), // o usa un valor definido
            Text("Tel: $telefono", style: ClienteStyles.cardSubtitle),
            const SizedBox(height: ClienteStyles.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClienteStyles.spacing12,
                vertical: ClienteStyles.spacing8,
              ),
              decoration: ClienteStyles.chipDecoration(),
              child: Text(
                rol,
                style: ClienteStyles.labelText.copyWith(color: ClienteStyles.primaryGreen),
              ),
            ),
            const SizedBox(height: ClienteStyles.spacing24),

            // Botón editar
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 20),
                label: const Text("Editar perfil"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditarPerfilCliente()),
                  ).then((_) => _cargarPerfil()); // Refrescar datos al volver
                },
                style: ClienteStyles.primaryButtonStyle.copyWith(
                  padding: const MaterialStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 10),
                  ),
                  textStyle: MaterialStatePropertyAll(
                    ClienteStyles.buttonText.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ClienteStyles.spacing12),

            // Botón eliminar
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text("Eliminar cuenta"),
                onPressed: _confirmarEliminacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClienteStyles.errorColor,
                  foregroundColor: ClienteStyles.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ClienteStyles.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClienteStyles.radiusLarge),
        ),
        title: const Text("¿Eliminar cuenta?"),
        content: const Text(
          "Esta acción no se puede deshacer. Tu cuenta será eliminada permanentemente.",
          style: ClienteStyles.bodyText,
        ),
        actionsPadding: const EdgeInsets.only(right: ClienteStyles.spacing16, bottom: ClienteStyles.spacing12),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Eliminar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClienteStyles.errorColor,
              foregroundColor: ClienteStyles.surfaceWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (id != null) {
                final success = await _clienteController.deleteCliente(id!);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cuenta eliminada")),
                  );
                  // Aquí podrías redirigir al login:
                  // Navigator.pushAndRemoveUntil(...);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
