import '../entities/profile_entity.dart';

abstract class IProfileRepository {
  Future<ProfileEntity> getProfile(String token);
  Future<void> updateProfile(String token, String nombre, String telefono, String email);
}
