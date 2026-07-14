import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';

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

  // --- DESTINOS RECIENTES ---
  Future<List<DestinoReciente>> getDestinosRecientes(String token);
  
  Future<void> guardarDestinoReciente({
    required String nombre,
    required double lat,
    required double lon,
    required String token,
  });

  Future<void> eliminarDestinoReciente(String id, String token);
}
