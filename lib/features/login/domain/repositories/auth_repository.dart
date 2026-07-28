import '../entities/user_entity.dart';

abstract class IAuthRepository {
  // ¡Fíjate cómo cambiamos el Map<String, dynamic> por UserEntity!
  Future<UserEntity> login(String email, String password);

  Future<void> logout();
  Future<String?> getToken();
  Future<String?> getNombre();
  Future<String?> getUserId();
  Future<String?> getTipo();

  Future<void> saveLoginTime(String time);
  Future<String?> getLoginTime();

  Future<void> guardarCredenciales(String email, String password);
  Future<Map<String, String?>> obtenerCredenciales();

  Future<void> setAutoLogin(bool value);
  Future<bool> getAutoLogin();

  Future<void> guardarDatosOffline(String token, String nombre, String tipo);
  Future<String?> getOfflineToken();
  Future<String?> getOfflineNombre();
  Future<String?> getOfflineTipo();
  Future<void> guardarCredencialesOffline(String email, String password);
  Future<Map<String, String?>> obtenerCredencialesOffline();
}