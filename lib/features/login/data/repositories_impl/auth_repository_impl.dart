import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/login_remote_datasource.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final LoginRemoteDataSource _api;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  Future<UserEntity> login(String email, String password) async {
    // Retorna el UserModel (que hereda de UserEntity)
    final user = await _api.login(email, password);

    // Sesión activa: Accedemos a las propiedades del objeto
    await _storage.write(key: 'jwt_token', value: user.token);
    await _storage.write(key: 'nombre', value: user.nombre);
    await _storage.write(key: 'tipo', value: user.tipo);
    await _storage.write(key: 'user_id', value: user.userId);

    // Respaldo Offline
    await guardarDatosOffline(user.token, user.nombre, user.tipo);
    await guardarCredencialesOffline(email, password);

    return user;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'nombre');
    await _storage.delete(key: 'tipo');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'login_time');
    await _storage.delete(key: 'auto_login');
  }

  @override
  Future<String?> getToken() async => _storage.read(key: 'jwt_token');
  @override
  Future<String?> getNombre() async => _storage.read(key: 'nombre');
  @override
  Future<String?> getUserId() async => _storage.read(key: 'user_id');
  @override
  Future<String?> getTipo() async => _storage.read(key: 'tipo');

  @override
  Future<void> saveLoginTime(String time) async {
    await _storage.write(key: 'login_time', value: time);
  }

  @override
  Future<String?> getLoginTime() async {
    return await _storage.read(key: 'login_time');
  }

  @override
  Future<void> guardarCredenciales(String email, String password) async {
    await _storage.write(key: 'saved_email', value: email);
    await _storage.write(key: 'saved_password', value: password);
  }

  @override
  Future<Map<String, String?>> obtenerCredenciales() async {
    return {
      'email': await _storage.read(key: 'saved_email'),
      'password': await _storage.read(key: 'saved_password'),
    };
  }

  @override
  Future<void> setAutoLogin(bool value) async {
    await _storage.write(key: 'auto_login', value: value.toString());
  }

  @override
  Future<bool> getAutoLogin() async {
    final value = await _storage.read(key: 'auto_login');
    return value == 'true';
  }

  @override
  Future<void> guardarDatosOffline(String token, String nombre, String tipo) async {
    await _storage.write(key: 'offline_token', value: token);
    await _storage.write(key: 'offline_nombre', value: nombre);
    await _storage.write(key: 'offline_tipo', value: tipo);
  }

  @override
  Future<String?> getOfflineToken() async => _storage.read(key: 'offline_token');

  @override
  Future<String?> getOfflineNombre() async => _storage.read(key: 'offline_nombre');

  @override
  Future<String?> getOfflineTipo() async => _storage.read(key: 'offline_tipo');

  @override
  Future<void> guardarCredencialesOffline(String email, String password) async {
    await _storage.write(key: 'offline_email', value: email);
    await _storage.write(key: 'offline_password', value: password);
  }

  @override
  Future<Map<String, String?>> obtenerCredencialesOffline() async {
    return {
      'email': await _storage.read(key: 'offline_email'),
      'password': await _storage.read(key: 'offline_password'),
    };
  }
}