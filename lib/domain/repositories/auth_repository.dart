// lib/domain/repositories/auth_repository.dart
abstract class IAuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<String?> getNombre();
  Future<String?> getUserId();
  Future<String?> getTipo();

  Future<void> saveLoginTime(String time);
  Future<String?> getLoginTime();

  Future<void> guardarCredenciales(String email, String password);
  Future<Map<String, String?>> obtenerCredenciales();

  // Gestión de persistencia de sesión
  Future<void> setAutoLogin(bool value);
  Future<bool> getAutoLogin();

  // Respaldo Offline persistente (no se borra en logout)
  Future<void> guardarDatosOffline(String token, String nombre, String tipo);
  Future<String?> getOfflineToken();
  Future<String?> getOfflineNombre();
  Future<String?> getOfflineTipo();
  Future<void> guardarCredencialesOffline(String email, String password);
  Future<Map<String, String?>> obtenerCredencialesOffline();
}