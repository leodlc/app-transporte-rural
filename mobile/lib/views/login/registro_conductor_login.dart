import 'package:flutter/material.dart';
import '../../controllers/conductor_controller.dart';
import '../../controllers/cooperativa_controller.dart';
import '../../models/conductor_model.dart';
import '../../models/cooperativa_model.dart';
import 'main_login.dart';
import 'login_styles.dart';

class RegistroConductorLogin extends StatefulWidget {
  const RegistroConductorLogin({super.key});

  @override
  _RegistroConductorLoginState createState() => _RegistroConductorLoginState();
}

class _RegistroConductorLoginState extends State<RegistroConductorLogin> {
  final _conductorController = ConductorController();
  final _cooperativaController = CooperativaController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoadingCooperativas = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();

  List<Cooperativa> _cooperativas = [];
  String? _cooperativaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCooperativas();
  }

  Future<void> _cargarCooperativas() async {
    try {
      List<Map<String, dynamic>> cooperativasJson = await _cooperativaController.fetchAllCooperativas();
      setState(() {
        _cooperativas = cooperativasJson.map((json) => Cooperativa.fromJson(json)).toList();
        _isLoadingCooperativas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCooperativas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar cooperativas"),
          backgroundColor: LoginStyles.errorColor,
        ),
      );
    }
  }

  Future<void> _registrarConductor() async {
    if (_formKey.currentState!.validate()) {
      if (_cooperativaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Por favor selecciona una cooperativa"),
            backgroundColor: LoginStyles.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      Conductor conductor = Conductor(
        nombre: _nombreController.text,
        username: _usernameController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        password: _passwordController.text,
        vehiculo: null,
        tokenFCM: null,
        activo: true,
        rol: "conductor",
        cooperativa: _cooperativaSeleccionada!,
      );

      bool registrado = await _conductorController.registerConductor(conductor);

      setState(() {
        _isLoading = false;
      });

      if (registrado) {
        // Mostrar diálogo de éxito
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: LoginStyles.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LoginStyles.radiusLarge),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(LoginStyles.spacing8),
                    decoration: BoxDecoration(
                      color: LoginStyles.primaryNavy.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: LoginStyles.primaryNavy,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: LoginStyles.spacing16),
                  Text(
                    'Registro exitoso',
                    style: LoginStyles.sectionTitle,
                  ),
                ],
              ),
              content: Text(
                'Tu cuenta de conductor ha sido creada. Ahora puedes iniciar sesión para comenzar a ofrecer viajes.',
                style: LoginStyles.cardText,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainLogin()),
                    );
                  },
                  child: Text(
                    'Ir al inicio',
                    style: TextStyle(
                      color: LoginStyles.primaryNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error en el registro. Inténtalo de nuevo."),
            backgroundColor: LoginStyles.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Estilos para el dropdown menu
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(LoginStyles.surfaceWhite),
            elevation: MaterialStateProperty.all(8),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
              ),
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: LoginStyles.backgroundLight,
        appBar: AppBar(
          backgroundColor: LoginStyles.surfaceWhite,
          elevation: 0,
          title: Text(
            "Registro Conductor",
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
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

                      LoginStyles.verticalSpacingLarge,

                      Text(
                        'Únete como conductor',
                        style: LoginStyles.title,
                        textAlign: TextAlign.center,
                      ),

                      LoginStyles.verticalSpacingSmall,

                      Text(
                        'Completa tu registro para empezar a ofrecer viajes',
                        style: LoginStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),

                      LoginStyles.verticalSpacingXLarge,

                      // Formulario en tarjeta
                      Container(
                        padding: const EdgeInsets.all(LoginStyles.spacing24),
                        decoration: LoginStyles.cardDecoration,
                        child: Column(
                          children: [
                            // Información personal
                            Text(
                              'Información personal',
                              style: LoginStyles.cardText.copyWith(
                                fontWeight: FontWeight.w600,
                                color: LoginStyles.primaryNavy,
                              ),
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _nombreController,
                              decoration: LoginStyles.nombreInput.copyWith(
                                helperText: "Ingresa tu nombre completo",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "El nombre es obligatorio";
                                }
                                if (value.trim().length < 3) {
                                  return "El nombre debe tener al menos 3 caracteres";
                                }
                                if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
                                  return "Solo se permiten letras y espacios";
                                }
                                return null;
                              },
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _usernameController,
                              decoration: LoginStyles.usernameInputAlt.copyWith(
                                helperText: "Mínimo 4 caracteres, sin espacios",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "El nombre de usuario es obligatorio";
                                }
                                if (value.length < 4) {
                                  return "Debe tener al menos 4 caracteres";
                                }
                                if (value.length > 20) {
                                  return "Máximo 20 caracteres permitidos";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                  return "Solo letras, números y guión bajo (_)";
                                }
                                return null;
                              },
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _emailController,
                              decoration: LoginStyles.emailInput.copyWith(
                                helperText: "ejemplo@correo.com",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "El correo es obligatorio";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                  return "Formato de correo inválido";
                                }
                                return null;
                              },
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _telefonoController,
                              decoration: LoginStyles.telefonoInput.copyWith(
                                helperText: "10 dígitos sin espacios",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                                prefixStyle: TextStyle(
                                  color: LoginStyles.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              maxLength: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "El teléfono es obligatorio";
                                }
                                final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
                                if (cleanPhone.length != 10) {
                                  return "Debe tener exactamente 10 dígitos";
                                }
                                return null;
                              },
                            ),

                            // Separador
                            LoginStyles.verticalSpacingLarge,
                            Divider(color: LoginStyles.dividerColor),
                            LoginStyles.verticalSpacing,

                            // Información de cooperativa
                            Text(
                              'Información laboral',
                              style: LoginStyles.cardText.copyWith(
                                fontWeight: FontWeight.w600,
                                color: LoginStyles.primaryNavy,
                              ),
                            ),

                            LoginStyles.verticalSpacing,

                            // Dropdown de cooperativas
                            _isLoadingCooperativas
                                ? Container(
                              padding: const EdgeInsets.all(LoginStyles.spacing16),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: LoginStyles.primaryNavy,
                                  ),
                                  LoginStyles.verticalSpacingSmall,
                                  Text(
                                    'Cargando cooperativas...',
                                    style: LoginStyles.subtitle,
                                  ),
                                ],
                              ),
                            )
                                : DropdownButtonFormField<String>(
                              decoration: LoginStyles.dropdownDecoration(
                                label: 'Cooperativa',
                                icon: Icons.business_rounded,
                                iconColor: LoginStyles.primaryNavy,
                                helperText: "Selecciona tu cooperativa",
                              ),
                              value: _cooperativaSeleccionada,
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: LoginStyles.primaryNavy,
                              ),
                              dropdownColor: LoginStyles.surfaceWhite,
                              style: LoginStyles.cardText,
                              menuMaxHeight: 300,
                              items: _cooperativas.map((cooperativa) {
                                return DropdownMenuItem<String>(
                                  value: cooperativa.id,
                                  child: Text(
                                    cooperativa.nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: LoginStyles.cardText,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _cooperativaSeleccionada = value;
                                });
                              },
                              validator: (value) =>
                              value == null ? "Debes seleccionar una cooperativa" : null,
                            ),

                            // Separador
                            LoginStyles.verticalSpacingLarge,
                            Divider(color: LoginStyles.dividerColor),
                            LoginStyles.verticalSpacing,

                            // Seguridad
                            Text(
                              'Seguridad',
                              style: LoginStyles.cardText.copyWith(
                                fontWeight: FontWeight.w600,
                                color: LoginStyles.primaryNavy,
                              ),
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _passwordController,
                              decoration: LoginStyles.passwordInputAlt.copyWith(
                                helperText: "Mínimo 6 caracteres con letras y números",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: LoginStyles.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                if (_confirmarPasswordController.text.isNotEmpty) {
                                  _formKey.currentState?.validate();
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "La contraseña es obligatoria";
                                }
                                if (value.length < 6) {
                                  return "Debe tener al menos 6 caracteres";
                                }
                                if (!value.contains(RegExp(r'[0-9]'))) {
                                  return "Debe contener al menos un número";
                                }
                                if (!value.contains(RegExp(r'[a-zA-Z]'))) {
                                  return "Debe contener al menos una letra";
                                }
                                return null;
                              },
                            ),

                            LoginStyles.verticalSpacing,

                            TextFormField(
                              controller: _confirmarPasswordController,
                              decoration: LoginStyles.confirmarPasswordInput.copyWith(
                                helperText: "Repite la contraseña anterior",
                                helperStyle: TextStyle(
                                  fontSize: 12,
                                  color: LoginStyles.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: LoginStyles.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _registrarConductor(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Debes confirmar tu contraseña";
                                }
                                if (value != _passwordController.text) {
                                  return "Las contraseñas no coinciden";
                                }
                                return null;
                              },
                            ),

                            LoginStyles.verticalSpacingLarge,

                            // Botón de registro
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_isLoading || _isLoadingCooperativas) ? null : _registrarConductor,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LoginStyles.primaryNavy,
                                  foregroundColor: LoginStyles.surfaceWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
                                  ),
                                  elevation: LoginStyles.elevationSmall,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      LoginStyles.surfaceWhite,
                                    ),
                                  ),
                                )
                                    : const Text('Registrarme como conductor'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      LoginStyles.verticalSpacingLarge,

                      // Información adicional
                      Container(
                        padding: const EdgeInsets.all(LoginStyles.spacing16),
                        decoration: BoxDecoration(
                          color: LoginStyles.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(LoginStyles.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: LoginStyles.accentBlue,
                              size: 20,
                            ),
                            SizedBox(width: LoginStyles.spacing8),
                            Expanded(
                              child: Text(
                                "Tu cuenta será revisada por la cooperativa antes de activarse",
                                style: LoginStyles.subtitle.copyWith(
                                  fontSize: 12,
                                  color: LoginStyles.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      LoginStyles.verticalSpacing,

                      // Link para login
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const MainLogin()),
                            );
                          },
                          style: LoginStyles.textButtonStyle,
                          child: Text('¿Ya tienes cuenta? Inicia sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }
}