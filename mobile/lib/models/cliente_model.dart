class Cliente {
  final String? id;
  final String nombre;
  final String username;
  final String? direccion;
  final String? telefono;
  final String email;
  final String password;
  final String? firmaDigital;
  final bool activo;
  final String? tokenFCM;
  final String rol;

  Cliente({
    this.id,
    required this.nombre,
    required this.username,
    this.direccion,
    this.telefono,
    required this.email,
    required this.password,
    this.firmaDigital,
    this.activo = true,
    this.tokenFCM,
    this.rol = "cliente",
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "username": username,
      "direccion": direccion,
      "telefono": telefono,
      "email": email,
      "password": password,
      "firmaDigital": firmaDigital,
      "activo": activo,
      "tokenFCM": tokenFCM,
      "rol": rol,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json["_id"],
      nombre: json["nombre"],
      username: json["username"],
      direccion: json["direccion"],
      telefono: json["telefono"],
      email: json["email"],
      password: json["password"],
      firmaDigital: json["firmaDigital"],
      activo: json["activo"] ?? true,
      tokenFCM: json["tokenFCM"] is String ? json["tokenFCM"] : null,
      rol: json["rol"],
    );
  }
}