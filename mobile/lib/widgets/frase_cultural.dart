import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../views/login/login_styles.dart';

class FraseCulturalDialog extends StatefulWidget {
  const FraseCulturalDialog({super.key});

  @override
  State<FraseCulturalDialog> createState() => _FraseCulturalDialogState();
}

class _FraseCulturalDialogState extends State<FraseCulturalDialog> {
  String? frase;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerFrase();
  }

  Future<void> obtenerFrase() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/1.0/frase/aleatoria'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          frase = data['data']['frase'];
          cargando = false;
        });
      } else {
        setState(() {
          frase = 'No se pudo cargar la frase cultural.';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        frase = 'Error de conexión.';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: LoginStyles.surfaceWhite,
          borderRadius: BorderRadius.circular(LoginStyles.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LoginStyles.spacing24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LoginStyles.primaryGreen,
                    LoginStyles.primaryGreen.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(LoginStyles.radiusXLarge),
                  topRight: Radius.circular(LoginStyles.radiusXLarge),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: LoginStyles.surfaceWhite,
                    size: 48,
                  ),
                  LoginStyles.verticalSpacingSmall,
                  Text(
                    'Frase Cultural',
                    style: LoginStyles.sectionTitle.copyWith(
                      color: LoginStyles.surfaceWhite,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(LoginStyles.spacing32),
              child: Column(
                children: [
                  // Estado de carga o contenido
                  if (cargando) ...[
                    Container(
                      padding: const EdgeInsets.all(LoginStyles.spacing32),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: LoginStyles.primaryGreen,
                            strokeWidth: 3,
                          ),
                          LoginStyles.verticalSpacing,
                          Text(
                            'Cargando frase cultural...',
                            style: LoginStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Frase
                    Text(
                      frase ?? 'Sin frase disponible',
                      style: LoginStyles.cardText.copyWith(
                        fontSize: 16,
                        height: 1.6,
                        color: LoginStyles.textPrimary.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  LoginStyles.verticalSpacingXLarge,

                  // Botón cerrar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: cargando ? null : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LoginStyles.primaryGreen,
                        foregroundColor: LoginStyles.surfaceWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: LoginStyles.primaryGreen.withOpacity(0.5),
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Botón para recargar si hay error
                  if (!cargando && (frase == 'Error de conexión.' || frase == 'No se pudo cargar la frase cultural.')) ...[
                    LoginStyles.verticalSpacingSmall,
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          cargando = true;
                        });
                        obtenerFrase();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                      ),
                      label: Text('Reintentar'),
                      style: LoginStyles.textButtonStyle,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}