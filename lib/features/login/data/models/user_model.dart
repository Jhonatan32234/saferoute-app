import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.token,
    required super.nombre,
    required super.tipo,
    required super.userId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      // Convertimos explícitamente a String por si el backend envía un Int
      userId: json['user_id']?.toString() ?? '',
    );
  }
}