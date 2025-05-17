class Conductor {
  final String? id;
  final String nombre;
  final String username;
  final String email;
  final String telefono;
  final String password;
  final String? vehiculo;
  final String? tokenFCM;
  final bool activo;
  final String rol;

  Conductor({
    this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.telefono,
    required this.password,
    this.vehiculo,
    this.tokenFCM,
    this.activo = true,
    this.rol = "conductor",
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "username": username,
      "email": email,
      "telefono": telefono,
      "password": password,
      "vehiculo": vehiculo,
      "tokenFCM": tokenFCM,
      "activo": activo,
      "rol": rol,
    };
  }

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json["_id"],
      nombre: json["nombre"],
      username: json["username"],
      email: json["email"],
      telefono: json["telefono"],
      password: json["password"],
      vehiculo: json["vehiculo"],
      tokenFCM: json["tokenFCM"],
      activo: json["activo"] ?? true,
      rol: json["rol"],
    );
  }
}