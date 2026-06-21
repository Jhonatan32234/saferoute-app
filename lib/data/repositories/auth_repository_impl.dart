import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/api_datasources.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final ApiDataSource _api;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl({required ApiDataSource api})
      : _api = api,
        _storage = const FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.login(email, password);
    await _storage.write(key: 'jwt_token', value: data['token']);
    await _storage.write(key: 'nombre', value: data['nombre']);
    await _storage.write(key: 'tipo', value: data['tipo']);
    await _storage.write(key: 'user_id', value: data['user_id']);
    return data;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'nombre');
    await _storage.delete(key: 'tipo');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'login_time');
  }

  @override
  Future<String?> getToken() async => _storage.read(key: 'jwt_token');

  @override
  Future<String?> getNombre() async => _storage.read(key: 'nombre');

  // Nuevos métodos para gestionar el tiempo de sesión
  Future<void> saveLoginTime(String time) async {
    await _storage.write(key: 'login_time', value: time);
  }

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
}
