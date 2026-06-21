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
  DateTime? _ultimaActividad;

  String? get token => _token;
  String? get nombre => _nombre;
  String? get tipo => _tipo;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null && !sesionExpirada;
  String? get error => _error;

  AuthProvider() {
    final baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';
    api = ApiDataSource(baseUrl: baseUrl, client: http.Client());
    authRepository = AuthRepositoryImpl(api: api);
    reporteRepository = ReporteRepositoryImpl(api: api);
    _cargarSesion();
  }

  void actualizarActividad() {
    _ultimaActividad = DateTime.now();
    if (_ultimaActividad != null) {
      authRepository.saveLoginTime(_ultimaActividad!.toIso8601String());
    }
  }

  bool get sesionExpirada {
    if (_token == null) return true;
    if (_ultimaActividad == null) return true;
    
    // 12 horas de sesión máxima
    return DateTime.now().difference(_ultimaActividad!) > const Duration(hours: 12);
  }

  Future<void> _cargarSesion() async {
    try {
      final token = await authRepository.getToken();
      final loginTimeStr = await authRepository.getLoginTime();
      
      if (token != null && loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        
        // Si la sesión guardada tiene más de 12 horas, limpiamos todo
        if (DateTime.now().difference(loginTime) > const Duration(hours: 12)) {
          await logout();
          return;
        }

        _token = token;
        _nombre = await authRepository.getNombre();
        _ultimaActividad = loginTime;
        notifyListeners();
      } else {
        // Si no hay token o no hay tiempo de login, aseguramos que esté deslogueado
        _token = null;
        _ultimaActividad = null;
        notifyListeners();
      }
    } catch (e) {
      _token = null;
      _ultimaActividad = null;
      notifyListeners();
    }
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
      _ultimaActividad = DateTime.now();
      
      // Persistimos el momento del login
      await authRepository.saveLoginTime(_ultimaActividad!.toIso8601String());
      
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
    _ultimaActividad = null;
    notifyListeners();
  }
}
