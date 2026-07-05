import 'package:injectable/injectable.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

@LazySingleton(as: IProfileRepository)
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile(String token) async {
    return await _remoteDataSource.getProfile(token);
  }

  @override
  Future<void> updateProfile(String token, String nombre, String telefono, String email) async {
    await _remoteDataSource.updateProfile(token, {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
    });
  }
}
