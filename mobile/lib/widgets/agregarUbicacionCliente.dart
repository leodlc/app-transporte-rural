import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/cliente_controller.dart';

class AgregarUbicacionCliente extends StatefulWidget {
  final IO.Socket socket;

  const AgregarUbicacionCliente({super.key, required this.socket});

  @override
  State<AgregarUbicacionCliente> createState() => _AgregarUbicacionClienteState();
}

class _AgregarUbicacionClienteState extends State<AgregarUbicacionCliente> {
  bool _cargando = false;
  bool _ubicacionActiva = false;
  late String _usuarioId;

  Position? _posicion;
  StreamSubscription<Position>? _posicionSub;

  final ClienteController _clienteController = ClienteController();

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  @override
  void dispose() {
    _posicionSub?.cancel();
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getString("id") ?? "";

    if (_usuarioId.isEmpty) return;

    await _clienteController.fetchClienteData(_usuarioId);

    final activo = prefs.getBool('ubicacionActiva') ?? false;
    setState(() {
      _ubicacionActiva = activo;
    });

    // Ya no activamos ubicación aquí para evitar reactivación automática
  }

  void _iniciarEscuchaPosicion() {
    _posicionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position posicion) {
      setState(() {
        _posicion = posicion;
      });

      widget.socket.emit("cliente:ubicacion-actualizar", {
        "clienteId": _usuarioId,
        "lat": posicion.latitude,
        "lng": posicion.longitude,
      });
    });
  }

  Future<void> _activarUbicacion() async {
    setState(() => _cargando = true);

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permiso de ubicación denegado")));
        return;
      }
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _posicion = posicion;

      widget.socket.emit("cliente:ubicacion-actualizar", {
        "clienteId": _usuarioId,
        "lat": posicion.latitude,
        "lng": posicion.longitude,
      });

      setState(() {
        _cargando = false;
        _ubicacionActiva = true;
      });

      _iniciarEscuchaPosicion();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ubicacionActiva', true);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubicación activada")));
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al obtener ubicación: $e")));
    }
  }

  Future<void> _desactivarUbicacion() async {
    setState(() => _cargando = true);

    try {
      widget.socket.emit("cliente:ubicacion-desactivar", {"clienteId": _usuarioId});

      await _posicionSub?.cancel();
      _posicionSub = null;

      setState(() {
        _cargando = false;
        _ubicacionActiva = false;
        _posicion = null;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ubicacionActiva', false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubicación desactivada")));
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al desactivar ubicación: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Center(child: Lottie.asset('assets/lottieicons/activarUbicacion.json', width: 150));
    }

    if (_ubicacionActiva) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text("Ubicación activa", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          if (_posicion != null) ...[
            Text("Latitud: ${_posicion!.latitude.toStringAsFixed(6)}"),
            Text("Longitud: ${_posicion!.longitude.toStringAsFixed(6)}"),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _desactivarUbicacion,
            icon: const Icon(Icons.location_off),
            label: const Text("Desactivar ubicación"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      );
    }

    return Center(
      child: ElevatedButton.icon(
        onPressed: _activarUbicacion,
        icon: const Icon(Icons.my_location),
        label: const Text("Activar ubicación"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
