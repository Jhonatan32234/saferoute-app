import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/session_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import 'auth_state.dart';

@lazySingleton
class AuthProvider extends ChangeNotifier {
  final IAuthRepository authRepository;
  final SessionService _sessionService;
  final LoginUseCase _loginUseCase;

  AuthState _state = const AuthInitial();
  bool _inicializado = false;
  DateTime? _ultimaActividad;
  bool _isOnline = true;

  AuthProvider(this.authRepository, this._sessionService, this._loginUseCase) {
    _cargarSesion();
    _monitorearConectividad();
  }

  AuthState get state => _state;
  bool get inicializado => _inicializado;
  bool get isOnline => _isOnline;

  bool get isLoading => _state is AuthLoading;
  String? get error => _state is AuthUnauthenticated ? (_state as AuthUnauthenticated).error : null;
  String? get token => _sessionService.token;
  String? get nombre => _state is AuthAuthenticated ? (_state as AuthAuthenticated).nombre : null;
  String? get userId => _state is AuthAuthenticated ? (_state as AuthAuthenticated).userId : null;
  bool get isLoggedIn => _state is AuthAuthenticated && !sesionExpirada;

  void _monitorearConectividad() {
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  void actualizarActividad() {
    _ultimaActividad = DateTime.now();
    if (_ultimaActividad != null) {
      authRepository.saveLoginTime(_ultimaActividad!.toIso8601String());
    }
  }

  bool get sesionExpirada {
    if (!_sessionService.hasToken) return true;
    if (_ultimaActividad == null) return true;
    return DateTime.now().difference(_ultimaActividad!) > const Duration(hours: 12);
  }

  Future<void> _cargarSesion() async {
    try {
      await _sessionService.initialize();
      final permiteAutoLogin = await authRepository.getAutoLogin();

      if (!permiteAutoLogin) {
        _state = const AuthUnauthenticated();
        _inicializado = true;
        notifyListeners();
        return;
      }

      final loginTimeStr = await authRepository.getLoginTime();

      if (_sessionService.hasToken && loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        if (DateTime.now().difference(loginTime) > const Duration(hours: 12)) {
          await logout();
          return;
        }

        final nombre = await authRepository.getNombre() ?? '';
        final tipo = await authRepository.getTipo() ?? '';
        final userId = await authRepository.getUserId() ?? '';
        _ultimaActividad = loginTime;

        _state = AuthAuthenticated(
          token: _sessionService.token!,
          nombre: nombre,
          tipo: tipo,
          userId: userId,
        );
      } else {
        _state = const AuthUnauthenticated();
      }
    } catch (e) {
      await _sessionService.setToken(null);
      _state = const AuthUnauthenticated();
    } finally {
      _inicializado = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {bool recordar = false}) async {
    _state = const AuthLoading();
    notifyListeners();

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return await _intentoLoginOffline(email, password);
    }

    final result = await _loginUseCase.execute(email, password);

    return result.fold(
      (failure) async {
        if (failure.contains('SocketException') || failure.contains('timeout')) {
          return await _intentoLoginOffline(email, password);
        }
        _state = AuthUnauthenticated(error: failure);
        notifyListeners();
        return false;
      },
      (user) async {
        await _sessionService.setToken(user.token);
        _ultimaActividad = DateTime.now();
        await authRepository.saveLoginTime(_ultimaActividad!.toIso8601String());
        await authRepository.setAutoLogin(recordar);

        if (recordar) {
          await authRepository.guardarCredenciales(email, password);
        } else {
          await authRepository.guardarCredenciales(email, "");
        }

        _state = AuthAuthenticated(
          token: user.token, 
          nombre: user.nombre, 
          tipo: user.tipo,
          userId: user.userId,
        );
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> _intentoLoginOffline(String email, String password) async {
    final offlineCreds = await authRepository.obtenerCredencialesOffline();
    final offlineToken = await authRepository.getOfflineToken();

    if (offlineCreds['email']?.trim() == email.trim() &&
        offlineCreds['password'] == password &&
        offlineToken != null) {

      await _sessionService.setToken(offlineToken);
      final nombre = await authRepository.getOfflineNombre() ?? '';
      final tipo = await authRepository.getOfflineTipo() ?? '';
      final userId = await authRepository.getUserId() ?? '';
      final loginTimeStr = await authRepository.getLoginTime();
      _ultimaActividad = loginTimeStr != null ? DateTime.parse(loginTimeStr) : DateTime.now();

      _state = AuthAuthenticated(
        token: offlineToken, 
        nombre: nombre, 
        tipo: tipo,
        userId: userId,
      );
      notifyListeners();
      return true;
    }

    _state = const AuthUnauthenticated(error: 'Sin conexión. No se encontraron credenciales guardadas.');
    notifyListeners();
    return false;
  }

  Future<Map<String, String?>> getCredencialesGuardadas() async {
    return await authRepository.obtenerCredenciales();
  }

  Future<void> logout() async {
    await _sessionService.setToken(null);
    _ultimaActividad = null;
    _state = const AuthUnauthenticated();
    _inicializado = true;
    notifyListeners();
    try {
      await authRepository.logout();
    } catch (e) {
      debugPrint("Error al limpiar sesión: $e");
    }
  }
}
