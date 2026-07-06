import '../entities/ruta_entity.dart';

abstract class IHomeRepository {
  Future<List<RutaEntity>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String token,
  });

  Future<String> iniciarViaje({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String polylineRuta,
    required String rutaId,
    required String token,
  });

  Future<bool> finalizarViaje({
    required String viajeId,
    String? password,
    required String token,
  });
}
