import '../entities/profile_entity.dart';

abstract class IProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<void> updateProfile(String nombre, String telefono, String email);
}
