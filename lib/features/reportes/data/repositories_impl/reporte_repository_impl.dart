import 'package:injectable/injectable.dart';
import '../../../../core/utils/reporte_mapper.dart';
import '../../domain/repositories/reporte_repository.dart';
import '../../domain/entities/reporte_entity.dart';
import '../datasources/reportes_remote_datasource.dart';

@LazySingleton(as: IReporteRepository)
class ReporteRepositoryImpl implements IReporteRepository {
  final ReportesRemoteDataSource _api;

  ReporteRepositoryImpl(this._api);

  @override
  Future<ReporteEntity> crearReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    required String notaVoz,
    required String rutaId,
  }) async {
    // Mapeamos el ID técnico (ej: 'accident') al valor que espera el servidor (ej: 'accidente')
    final tipoBackend = ReporteMapper.toBackend(tipo);

    return await _api.crearReporte(
      tipo: tipoBackend,
      latitud: latitud,
      longitud: longitud,
      notaVoz: notaVoz,
      rutaId: rutaId,
    );
  }
}
