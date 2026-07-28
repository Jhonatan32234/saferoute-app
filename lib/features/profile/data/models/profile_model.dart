import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.nombre,
    required super.tipo,
    required super.telefono,
    super.createdAt,
    super.updatedAt,
    super.ultimoAcceso,
    super.reportesCreados,
    super.reportesConfirmados,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      telefono: json['telefono'] ?? '', // Resiliente si viene nulo o no viene
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      ultimoAcceso: json['ultimo_acceso'] != null ? DateTime.tryParse(json['ultimo_acceso']) : null,
      reportesCreados: (json['reportes_creados'] ?? 0).toInt(),
      reportesConfirmados: (json['reportes_confirmados'] ?? 0).toInt(),
    );
  }
}
