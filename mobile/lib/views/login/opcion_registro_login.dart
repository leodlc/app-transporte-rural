import 'package:flutter/material.dart';
import 'registro_cliente_login.dart';
import 'registro_conductor_login.dart';
import 'login_styles.dart'; // ← Importar los estilos

class OpcionRegistroLogin extends StatelessWidget {
  const OpcionRegistroLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona tu tipo de cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Regístrate como:",
              style: LoginStyles.sectionTitle, // ← Estilo de título
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: LoginStyles.clienteIcon, // ← Icono cliente
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegistroClienteLogin()),
                        );
                      },
                    ),
                    const Text("Cliente", style: LoginStyles.cardText),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: LoginStyles.conductorIcon, // ← Icono conductor
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegistroConductorLogin()),
                        );
                      },
                    ),
                    const Text("Conductor", style: LoginStyles.cardText),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
