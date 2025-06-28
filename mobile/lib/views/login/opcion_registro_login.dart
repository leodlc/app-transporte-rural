import 'package:flutter/material.dart';
import 'registro_cliente_login.dart';
import 'registro_conductor_login.dart';
import 'login_styles.dart';

class OpcionRegistroLogin extends StatelessWidget {
  const OpcionRegistroLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyles.backgroundLight,
      appBar: AppBar(
        backgroundColor: LoginStyles.surfaceWhite,
        elevation: 0,
        title: Text(
          "Tipo de cuenta",
          style: LoginStyles.sectionTitle.copyWith(
            color: LoginStyles.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: LoginStyles.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LoginStyles.spacing24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono principal
                  Container(
                    padding: const EdgeInsets.all(LoginStyles.spacing24),
                    decoration: BoxDecoration(
                      color: LoginStyles.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 64,
                      color: LoginStyles.primaryGreen,
                    ),
                  ),

                  LoginStyles.verticalSpacingLarge,

                  // Título
                  Text(
                    "¿Cómo quieres registrarte?",
                    style: LoginStyles.title,
                    textAlign: TextAlign.center,
                  ),

                  LoginStyles.verticalSpacingSmall,

                  // Subtítulo
                  Text(
                    "Selecciona el tipo de cuenta que mejor se adapte a ti",
                    style: LoginStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),

                  LoginStyles.verticalSpacingXLarge,

                  // Opciones
                  Row(
                    children: [
                      // Opción Cliente
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistroClienteLogin(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
                          child: Container(
                            padding: const EdgeInsets.all(LoginStyles.spacing24),
                            decoration: BoxDecoration(
                              color: LoginStyles.surfaceWhite,
                              borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
                              border: Border.all(
                                color: LoginStyles.dividerColor,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(LoginStyles.spacing16),
                                  decoration: BoxDecoration(
                                    color: LoginStyles.primaryGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: LoginStyles.primaryGreen,
                                  ),
                                ),
                                LoginStyles.verticalSpacing,
                                Text(
                                  "Cliente",
                                  style: LoginStyles.cardText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                LoginStyles.verticalSpacingSmall,
                                Text(
                                  "Solicita viajes",
                                  style: LoginStyles.subtitle.copyWith(
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: LoginStyles.spacing16),

                      // Opción Conductor
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistroConductorLogin(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
                          child: Container(
                            padding: const EdgeInsets.all(LoginStyles.spacing24),
                            decoration: BoxDecoration(
                              color: LoginStyles.surfaceWhite,
                              borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
                              border: Border.all(
                                color: LoginStyles.dividerColor,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(LoginStyles.spacing16),
                                  decoration: BoxDecoration(
                                    color: LoginStyles.primaryNavy.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.directions_car_rounded,
                                    size: 48,
                                    color: LoginStyles.primaryNavy,
                                  ),
                                ),
                                LoginStyles.verticalSpacing,
                                Text(
                                  "Conductor",
                                  style: LoginStyles.cardText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                LoginStyles.verticalSpacingSmall,
                                Text(
                                  "Ofrece viajes",
                                  style: LoginStyles.subtitle.copyWith(
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  LoginStyles.verticalSpacingXLarge,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}