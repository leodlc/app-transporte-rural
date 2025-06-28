import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/cliente_controller.dart';
import '../views/cliente/cliente_styles.dart';

class AgregarUbicacionCliente extends StatefulWidget {
  final IO.Socket socket;

  const AgregarUbicacionCliente({super.key, required this.socket});

  @override
  State<AgregarUbicacionCliente> createState() => _AgregarUbicacionClienteState();
}

class _AgregarUbicacionClienteState extends State<AgregarUbicacionCliente> with SingleTickerProviderStateMixin {
  bool _cargando = false;
  bool _ubicacionActiva = false;
  late String _usuarioId;

  Position? _posicion;
  StreamSubscription<Position>? _posicionSub;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final ClienteController _clienteController = ClienteController();

  @override
  void initState() {
    super.initState();
    _inicializarDatos();

    // Animación para el indicador de ubicación activa
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _posicionSub?.cancel();
    _animationController.dispose();
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
  }

  void _iniciarEscuchaPosicion() {
    _posicionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Permiso de ubicación denegado"),
            backgroundColor: ClienteStyles.errorColor,
          ),
        );
        return;
      }
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ubicación activada"),
          backgroundColor: ClienteStyles.successColor,
        ),
      );
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al obtener ubicación: $e"),
          backgroundColor: ClienteStyles.errorColor,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ubicación desactivada"),
          backgroundColor: ClienteStyles.warningColor,
        ),
      );
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al desactivar ubicación: $e"),
          backgroundColor: ClienteStyles.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottieicons/activarUbicacion.json',
              width: 150,
            ),
            SizedBox(height: ClienteStyles.spacing16),
            Text(
              'Obteniendo ubicación...',
              style: ClienteStyles.bodyText.copyWith(
                color: ClienteStyles.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_ubicacionActiva) {
      return Container(
        padding: const EdgeInsets.all(ClienteStyles.spacing24),
        decoration: ClienteStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador animado de ubicación activa
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ClienteStyles.successColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ClienteStyles.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: ClienteStyles.spacing16),

            Text(
              "Ubicación activa",
              style: ClienteStyles.cardTitle.copyWith(
                color: ClienteStyles.successColor,
              ),
            ),

            SizedBox(height: ClienteStyles.spacing8),

            Text(
              "Los conductores pueden ver tu ubicación",
              style: ClienteStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),

            if (_posicion != null) ...[
              SizedBox(height: ClienteStyles.spacing16),
              Container(
                padding: const EdgeInsets.all(ClienteStyles.spacing12),
                decoration: BoxDecoration(
                  color: ClienteStyles.backgroundLight,
                  borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: ClienteStyles.textSecondary,
                        ),
                        SizedBox(width: ClienteStyles.spacing8),
                        Text(
                          "Coordenadas actuales",
                          style: ClienteStyles.labelText,
                        ),
                      ],
                    ),
                    SizedBox(height: ClienteStyles.spacing8),
                    Text(
                      "${_posicion!.latitude.toStringAsFixed(6)}, ${_posicion!.longitude.toStringAsFixed(6)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: ClienteStyles.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: ClienteStyles.spacing24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _desactivarUbicacion,
                icon: const Icon(Icons.location_off_rounded),
                label: const Text("Desactivar ubicación"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClienteStyles.errorColor,
                  foregroundColor: ClienteStyles.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Botón de activar ubicación
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _activarUbicacion,
          icon: Icon(
            Icons.my_location_rounded,
            color: ClienteStyles.primaryGreen,
          ),
          label: Text(
            "Activar ubicación",
            style: TextStyle(
              color: ClienteStyles.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ClienteStyles.surfaceWhite,
            foregroundColor: ClienteStyles.primaryGreen,
            padding: const EdgeInsets.symmetric(
              horizontal: ClienteStyles.spacing24,
              vertical: ClienteStyles.spacing16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClienteStyles.radiusMedium),
              side: BorderSide(
                color: ClienteStyles.primaryGreen,
                width: 2,
              ),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}