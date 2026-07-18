import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';

abstract class IHomeRepository {
  Future<List<RutaEntity>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
  });

  Future<String> iniciarViaje({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String polylineRuta,
    required String rutaId,
  });

  Future<bool> finalizarViaje({
    required String viajeId,
    String? password,
  });

  // --- DESTINOS RECIENTES ---
  Future<List<DestinoReciente>> getDestinosRecientes();
  
  Future<void> guardarDestinoReciente({
    required String nombre,
    required double lat,
    required double lon,
  });

  Future<void> eliminarDestinoReciente(String id);
}
