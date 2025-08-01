import 'package:mobile/controllers/notificacion_controller.dart';
import 'package:mobile/ws/SocketManager.dart';

class ViajeController {
  final SocketManager socket;
  final NotificacionController notificacion;
  final Function(String) mostrarExito;
  final Function(String) mostrarError;

  ViajeController({
    required this.socket,
    required this.notificacion,
    required this.mostrarExito,
    required this.mostrarError,
  });


}