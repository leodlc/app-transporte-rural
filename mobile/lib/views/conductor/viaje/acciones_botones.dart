import 'package:flutter/material.dart';
import 'package:mobile/views/conductor/conductor_styles.dart';
import 'package:mobile/views/conductor/main_conductor.dart';

class AccionesBotones extends StatelessWidget {
  final String estadoViaje;
  final bool enviandoAccion;

  final VoidCallback onLlegando;
  final VoidCallback onVerificarCodigo;
  final VoidCallback onFinalizarViaje;
  final VoidCallback onCancelarViaje;

  const AccionesBotones({
    super.key,
    required this.estadoViaje,
    required this.enviandoAccion,
    required this.onLlegando,
    required this.onVerificarCodigo,
    required this.onFinalizarViaje,
    required this.onCancelarViaje,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = [];

    void regresarAInicio() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainConductor()),
            (route) => false, // Elimina todas las rutas anteriores
      );
    }

    switch (estadoViaje) {
      case 'cancelado':
        botones.add(ElevatedButton.icon(
          onPressed: regresarAInicio,
          icon: Icon(Icons.home, color: Colors.white,),
          label: Text('Regresar a inicio', style: TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: ConductorStyles.successColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ));
        break;

      case 'iniciado':
        botones.add(
          ElevatedButton.icon(
            onPressed: enviandoAccion ? null : onLlegando,
            icon: Icon(Icons.location_on, color: Colors.white),
            label: Text('Estoy llegando', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ConductorStyles.warningColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;

      case 'llegando':
        botones.add(
          ElevatedButton.icon(
            onPressed: enviandoAccion ? null : onVerificarCodigo,
            icon: Icon(Icons.security, color: Colors.white),
            label: Text('Ingresar Código', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ConductorStyles.successColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;

      case 'en_curso':
        botones.add(
          ElevatedButton.icon(
            onPressed: enviandoAccion ? null : onFinalizarViaje,
            icon: Icon(Icons.flag, color: Colors.white),
            label: Text('Finalizar Viaje', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ConductorStyles.successColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
        break;
    }

    if (!['finalizado', 'cancelado'].contains(estadoViaje)) {
      botones.add(
        OutlinedButton.icon(
          onPressed: enviandoAccion ? null : onCancelarViaje,
          icon: Icon(Icons.cancel, color: Colors.red),
          label: Text('Cancelar', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return Column(
      children: botones
          .map((boton) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SizedBox(width: double.infinity, height: 48, child: boton),
      ))
          .toList(),
    );
  }
}
