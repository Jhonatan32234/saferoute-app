import '../entities/reporte.dart';

abstract class IReporteRepository {
  Future<Reporte> crearReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    required String notaVoz,
    required String rutaId,
    required String token,
  });
  Future<List<Reporte>> obtenerReportes({required String token});
  Future<void> validarReporte({
    required String reporteId,
    required bool vigente,
    required String token,
  });
}