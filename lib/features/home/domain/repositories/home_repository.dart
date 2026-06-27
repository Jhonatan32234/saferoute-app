import '../entities/ruta_entity.dart'; // <-- IMPORTANTE

abstract class IHomeRepository {
  // ¡CAMBIO CLAVE! Devuelve List<RutaEntity>
  Future<List<RutaEntity>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String token,
  });
}