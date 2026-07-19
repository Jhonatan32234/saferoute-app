abstract class IHomeLocalRepository {
  Future<void> guardarViajeActivo(String viajeId);
  Future<void> limpiarViajeActivo();
}
