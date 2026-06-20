abstract class IAuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<String?> getNombre();
  Future<void> guardarCredenciales(String email, String password);
  Future<Map<String, String?>> obtenerCredenciales();
}
