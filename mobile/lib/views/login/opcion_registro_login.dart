import 'package:flutter/material.dart';
import 'registro_cliente_login.dart';
import 'registro_conductor_login.dart';

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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person,
                          size: 80, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegistroClienteLogin()),
                        );
                      },
                    ),
                    const Text("Cliente", style: TextStyle(fontSize: 18)),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.directions_car,
                          size: 80, color: Colors.green),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegistroConductorLogin()),
                        );
                      },
                    ),
                    const Text("Conductor", style: TextStyle(fontSize: 18)),
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