import '../entities/reporte_entity.dart';

abstract class IReporteRepository {
  Future<ReporteEntity> crearReporte({
    required String tipo, required double latitud, required double longitud,
    required String notaVoz, required String rutaId, required String token,
  });
}