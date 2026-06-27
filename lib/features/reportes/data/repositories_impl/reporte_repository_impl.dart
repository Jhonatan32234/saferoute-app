import 'package:injectable/injectable.dart';
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
    required String token,
  }) async {
    return await _api.crearReporte(
      tipo: tipo,
      latitud: latitud,
      longitud: longitud,
      notaVoz: notaVoz,
      rutaId: rutaId,
      token: token,
    );
  }
}