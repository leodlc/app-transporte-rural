import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';

class DialogoCodigoSeguridad extends StatefulWidget {
  final Future<bool> Function(String codigo) onVerificarCodigo;
  final int intentosRestantesInicial;

  const DialogoCodigoSeguridad({
    super.key,
    required this.onVerificarCodigo,
    required this.intentosRestantesInicial,
  });

  @override
  State<DialogoCodigoSeguridad> createState() => _DialogoCodigoSeguridadState();

  // MODIFICACIÓN: Ahora devuelve un bool? (true: correcto, false: sin intentos, null: cancelado)
  static Future<bool?> mostrar({
    required BuildContext context,
    required Future<bool> Function(String codigo) onVerificarCodigo,
    required int intentosRestantesInicial,
  }) {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // Correcto, para no cerrar al tocar fuera
      builder: (_) => DialogoCodigoSeguridad(
        onVerificarCodigo: onVerificarCodigo,
        intentosRestantesInicial: intentosRestantesInicial,
      ),
    );
  }
}

class _DialogoCodigoSeguridadState extends State<DialogoCodigoSeguridad> {
  final TextEditingController _codigoController = TextEditingController();
  bool _esperandoVerificacion = false;
  late int _intentosRestantes;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _intentosRestantes = widget.intentosRestantesInicial;
  }

  Future<void> _verificar() async {
    if (_esperandoVerificacion || _codigoController.text.length != 4) return;

    setState(() {
      _esperandoVerificacion = true;
      _mensajeError = null; // Limpiar error previo
    });

    final bool esCorrecto = await widget.onVerificarCodigo(_codigoController.text);

    // Si el widget sigue montado después del await
    if (!mounted) return;

    if (esCorrecto) {
      // Si el código es correcto, el evento 'viaje:comenzado' se encargará
      // Aquí simplemente cerramos el diálogo devolviendo 'true'.
      Navigator.pop(context, true);
    } else {
      // Si el código es incorrecto, actualizamos los intentos.
      setState(() {
        _intentosRestantes--;
        _codigoController.clear();
        _esperandoVerificacion = false;
        if (_intentosRestantes > 0) {
          _mensajeError = 'Código incorrecto. Te quedan $_intentosRestantes intentos.';
        }
      });

      // Si se acabaron los intentos, cerramos el diálogo devolviendo 'false'.
      // El backend enviará 'viaje:cancelado' y la vista principal reaccionará.
      if (_intentosRestantes <= 0) {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: ConductorStyles.successColor),
          const SizedBox(width: 8),
          const Text('Código de Seguridad'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Solicita al cliente el código de 4 dígitos para iniciar.'),
          const SizedBox(height: 16),
          TextField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            enabled: !_esperandoVerificacion,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              labelText: 'Código de seguridad',
              hintText: '0000',
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black54),
              suffixStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                borderSide: BorderSide(color: Colors.black54.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ConductorStyles.radiusMedium),
                borderSide: BorderSide(color: Colors.black54, width: 2),
              ),
              prefixIcon: const Icon(Icons.lock),
              counterText: '',
              errorText: _mensajeError, // Mostrar el mensaje de error aquí
            ),
          ),
        ],
      ),
      actions: [
        // Devolvemos 'null' si el usuario cancela manualmente
        TextButton(
          onPressed: _esperandoVerificacion ? null : () => Navigator.pop(context, null),
          child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: _esperandoVerificacion || _codigoController.text.length != 4
              ? null
              : _verificar, // Llamar a la función _verificar
          style: ElevatedButton.styleFrom(
            backgroundColor: ConductorStyles.successColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _esperandoVerificacion
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Verificar e Iniciar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}