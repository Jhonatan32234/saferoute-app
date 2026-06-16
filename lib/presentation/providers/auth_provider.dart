import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:saferoute_app/data/datasources/api_datasources.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  late final ApiDataSource _api;

  String? _token;
  String? _userId;
  String? _nombre;
  String? _tipo;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get token => _token;
  String? get userId => _userId;
  String? get nombre => _nombre;
  String? get tipo => _tipo;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get error => _error;
  ApiDataSource get api => _api;

  AuthProvider() {
    // Intentar obtener del env, si no, usar fallback seguro
    final baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';
    _api = ApiDataSource(baseUrl: baseUrl, client: http.Client());
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      _token = await _storage.read(key: 'jwt_token');
      _nombre = await _storage.read(key: 'nombre');
      _tipo = await _storage.read(key: 'tipo');
      _userId = await _storage.read(key: 'user_id');
      if (_token != null) notifyListeners();
    } catch (e) {
      debugPrint("Error cargando token: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password);
      _token = data['token'];
      _userId = data['user_id'];
      _nombre = data['nombre'];
      _tipo = data['tipo'];

      await _storage.write(key: 'jwt_token', value: _token);
      await _storage.write(key: 'user_id', value: _userId);
      await _storage.write(key: 'nombre', value: _nombre);
      await _storage.write(key: 'tipo', value: _tipo);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _nombre = null;
    _tipo = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
