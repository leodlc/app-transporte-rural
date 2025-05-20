class Cooperativa {
  final String? id;
  final String nombre;
  final String email;
  final String responsable;
  final String ubicacion;
  final String telefono;

  Cooperativa({
    this.id,
    required this.nombre,
    required this.email,
    required this.responsable,
    required this.ubicacion,
    required this.telefono,
  });

  factory Cooperativa.fromJson(Map<String, dynamic> json) {
    return Cooperativa(
      id: json['_id'],
      nombre: json['nombre'],
      email: json['email'],
      responsable: json['responsable'],
      ubicacion: json['ubicacion'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "email": email,
      "responsable": responsable,
      "ubicacion": ubicacion,
      "telefono": telefono,
    };
  }
}
