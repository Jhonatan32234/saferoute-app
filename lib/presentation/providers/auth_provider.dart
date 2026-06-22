import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
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
  bool _inicializado = false;
  String? _error;
  DateTime? _ultimaActividad;

  String? get token => _token;
  String? get nombre => _nombre;
  String? get tipo => _tipo;
  bool get isLoading => _isLoading;
  bool get inicializado => _inicializado;
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
    return DateTime.now().difference(_ultimaActividad!) > const Duration(hours: 12);
  }

  Future<void> _cargarSesion() async {
    try {
      final permiteAutoLogin = await authRepository.getAutoLogin();
      
      if (!permiteAutoLogin) {
        _inicializado = true;
        notifyListeners();
        return;
      }

      final token = await authRepository.getToken();
      final loginTimeStr = await authRepository.getLoginTime();
      
      if (token != null && loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        if (DateTime.now().difference(loginTime) > const Duration(hours: 12)) {
          await logout();
          return;
        }

        _token = token;
        _nombre = await authRepository.getNombre();
        _tipo = await authRepository.getTipo();
        _ultimaActividad = loginTime;
      }
    } catch (e) {
      _token = null;
    } finally {
      _inicializado = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {bool recordar = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final bool estaOffline = connectivity.contains(ConnectivityResult.none);

      if (estaOffline) {
        return await _intentoLoginOffline(email, password);
      }

      final data = await authRepository.login(email, password);
      _token = data['token'];
      _nombre = data['nombre'];
      _tipo = data['tipo'];
      _ultimaActividad = DateTime.now();
      
      await authRepository.saveLoginTime(_ultimaActividad!.toIso8601String());
      await authRepository.setAutoLogin(recordar);
      
      if (recordar) {
        await authRepository.guardarCredenciales(email, password);
      } else {
        await authRepository.guardarCredenciales(email, "");
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errorStr = e.toString();
      
      if (errorStr.contains('SocketException') || 
          errorStr.contains('timeout') || 
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection refused')) {
        return await _intentoLoginOffline(email, password);
      }

      _error = errorStr.replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _intentoLoginOffline(String email, String password) async {
    final offlineCreds = await authRepository.obtenerCredencialesOffline();
    final offlineToken = await authRepository.getOfflineToken();

    if (offlineCreds['email']?.trim() == email.trim() && 
        offlineCreds['password'] == password && 
        offlineToken != null) {
      
      _token = offlineToken;
      _nombre = await authRepository.getOfflineNombre();
      _tipo = await authRepository.getOfflineTipo();
      
      final loginTimeStr = await authRepository.getLoginTime();
      _ultimaActividad = loginTimeStr != null ? DateTime.parse(loginTimeStr) : DateTime.now();

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    }

    _error = 'Sin conexión. No se encontraron credenciales guardadas para este usuario.';
    _isLoading = false;
    notifyListeners();
    return false;
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
    _inicializado = true;
    notifyListeners();
  }
}
