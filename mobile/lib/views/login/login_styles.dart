import 'package:flutter/material.dart';

class LoginStyles {
  static const TextStyle title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const InputDecoration usernameInput = InputDecoration(
    labelText: 'Usuario',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.person),
  );

  static const InputDecoration passwordInput = InputDecoration(
    labelText: 'Contraseña',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.lock),
  );

  static const TextStyle linkText = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  //estilos para OpcionRegistroLogin
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardText = TextStyle(
    fontSize: 18,
  );

  static const Icon clienteIcon = Icon(
    Icons.person,
    size: 80,
    color: Colors.blue,
  );

  static const Icon conductorIcon = Icon(
    Icons.directions_car,
    size: 80,
    color: Colors.green,
  );

  // Estilos para RegistroClienteLogin
  static const SizedBox verticalSpacing = SizedBox(height: 20);

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const InputDecoration nombreInput = InputDecoration(
    labelText: "Nombre",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.person),
  );

  static const InputDecoration usernameInputAlt = InputDecoration(
    labelText: "Username",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.alternate_email),
  );

  static const InputDecoration emailInput = InputDecoration(
    labelText: "Email",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.email),
  );

  static const InputDecoration telefonoInput = InputDecoration(
    labelText: "Teléfono",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.phone),
  );

  static const InputDecoration passwordInputAlt = InputDecoration(
    labelText: "Contraseña",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.lock),
  );

  static const InputDecoration confirmarPasswordInput = InputDecoration(
    labelText: "Confirmar Contraseña",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.lock_outline),
  );
  static const InputDecoration cooperativaInput = InputDecoration(
    labelText: "Cooperativa",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.directions_bus),
  );
}
