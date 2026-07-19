import '../entities/reporte_pendiente.dart';

abstract class IReportePendienteRepository {
  Future<List<ReportePendiente>> obtenerTodos();
  Future<void> guardar(ReportePendiente reporte);
  Future<void> reemplazarTodos(List<ReportePendiente> reportes);
}
