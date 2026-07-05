class ProfileEntity {
  final String id;
  final String email;
  final String nombre;
  final String tipo;
  final String telefono;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? ultimoAcceso;
  final int reportesCreados;
  final int reportesConfirmados;

  const ProfileEntity({
    required this.id,
    required this.email,
    required this.nombre,
    required this.tipo,
    required this.telefono,
    this.createdAt,
    this.updatedAt,
    this.ultimoAcceso,
    this.reportesCreados = 0,
    this.reportesConfirmados = 0,
  });
}
