import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionService {
  final FlutterSecureStorage _storage;
  String? _token;

  SessionService(this._storage);

  String? get token => _token;

  Future<void> initialize() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      await _storage.write(key: 'auth_token', value: token);
    } else {
      await _storage.delete(key: 'auth_token');
    }
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;
}
