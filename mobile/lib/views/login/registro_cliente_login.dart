import 'package:flutter/material.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente_model.dart';
import 'main_login.dart';

class RegistroClienteLogin extends StatefulWidget {
  const RegistroClienteLogin({super.key});

  @override
  _RegistroClienteLoginState createState() => _RegistroClienteLoginState();
}

class _RegistroClienteLoginState extends State<RegistroClienteLogin> {
  final _clienteController = ClienteController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Colores
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFD32F2F);

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: textSecondary),
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor),
      ),
    );
  }

  Future<void> _registrarCliente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Cliente cliente = Cliente(
        nombre: _nombreController.text,
        username: _usernameController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        direccion: "",
        password: _passwordController.text,
      );

      bool registrado = await _clienteController.registerCliente(cliente);

      setState(() {
        _isLoading = false;
      });

      if (registrado) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: primaryGreen,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Registro exitoso',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Tu cuenta ha sido creada. Revisa tu correo para encontrar el código de verificación.',
                style: TextStyle(fontSize: 16),
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
                      color: primaryGreen,
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
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        title: Text(
          "Registro Cliente",
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 48,
                        color: primaryGreen,
                      ),
                    ),

                    SizedBox(height: 24),

                    Text(
                      'Crea tu cuenta de cliente',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Completa los siguientes datos para registrarte',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 32),

                    // Formulario en tarjeta
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreController,
                            decoration: _getInputDecoration('Nombre completo', Icons.person_outline_rounded).copyWith(
                              helperText: "Ingresa tu nombre completo",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),
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

                          SizedBox(height: 16),

                          TextFormField(
                            controller: _usernameController,
                            decoration: _getInputDecoration('Nombre de usuario', Icons.alternate_email_rounded).copyWith(
                              helperText: "Mínimo 4 caracteres, sin espacios",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),
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
                              if (value.startsWith('_') || value.endsWith('_')) {
                                return "No puede empezar o terminar con guión bajo";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            decoration: _getInputDecoration('Correo electrónico', Icons.email_outlined).copyWith(
                              helperText: "ejemplo@correo.com",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "El correo electrónico es obligatorio";
                              }
                              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                return "Ingresa un correo válido";
                              }
                              if (value.length > 100) {
                                return "El correo es demasiado largo";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          TextFormField(
                            controller: _telefonoController,
                            decoration: _getInputDecoration('Teléfono', Icons.phone_outlined).copyWith(
                              helperText: "10 dígitos sin espacios",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),

                              prefixStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            maxLength: 10,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "El teléfono es obligatorio";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            decoration: _getInputDecoration('Contraseña', Icons.lock_outline_rounded).copyWith(
                              helperText: "Mínimo 6 caracteres",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: textSecondary,
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
                              if (value.length > 50) {
                                return "Máximo 50 caracteres permitidos";
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

                          SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmarPasswordController,
                            decoration: _getInputDecoration('Confirmar contraseña', Icons.lock_reset_rounded).copyWith(
                              helperText: "Repite la contraseña anterior",
                              helperStyle: TextStyle(fontSize: 12, color: textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: textSecondary,
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
                            onFieldSubmitted: (_) => _registrarCliente(),
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

                          SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registrarCliente,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: surfaceWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(surfaceWhite),
                                ),
                              )
                                  : const Text(
                                'Registrarme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Link para login
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainLogin()),
                          );
                        },
                        child: Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
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