class UserEntity {
  final String token;
  final String nombre;
  final String tipo;
  final String userId;

  const UserEntity({
    required this.token,
    required this.nombre,
    required this.tipo,
    required this.userId,
  });
}