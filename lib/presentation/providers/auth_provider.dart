import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/api_datasources.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/reporte_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  late final ApiDataSource api;
  late final AuthRepositoryImpl authRepository;
  late final ReporteRepositoryImpl reporteRepository;

  String? _token;
  String? _nombre;
  String? _tipo;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  String? get nombre => _nombre;
  String? get tipo => _tipo;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get error => _error;

  AuthProvider() {
    final baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';
    api = ApiDataSource(baseUrl: baseUrl, client: http.Client());
    authRepository = AuthRepositoryImpl(api: api);
    reporteRepository = ReporteRepositoryImpl(api: api);
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    _token = await authRepository.getToken();
    _nombre = await authRepository.getNombre();
    if (_token != null) notifyListeners();
  }

  Future<bool> login(String email, String password, {bool recordar = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await authRepository.login(email, password);
      _token = data['token'];
      _nombre = data['nombre'];
      _tipo = data['tipo'];
      
      if (recordar) {
        await authRepository.guardarCredenciales(email, password);
      }
      
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

  Future<Map<String, String?>> getCredencialesGuardadas() async {
    return await authRepository.obtenerCredenciales();
  }

  Future<void> logout() async {
    await authRepository.logout();
    _token = null;
    _nombre = null;
    _tipo = null;
    notifyListeners();
  }
}
