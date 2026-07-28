import 'package:injectable/injectable.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

@LazySingleton(as: IProfileRepository)
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<void> updateProfile(String nombre, String telefono, String email) async {
    await _remoteDataSource.updateProfile({
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
    });
  }
}
