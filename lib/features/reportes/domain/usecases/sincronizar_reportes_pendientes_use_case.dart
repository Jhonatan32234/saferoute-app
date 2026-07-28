import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../entities/reporte_pendiente.dart';
import '../entities/resultado_envio_reporte.dart';
import '../repositories/reporte_pendiente_repository.dart';
import '../repositories/reporte_repository.dart';

@lazySingleton
class SincronizarReportesPendientesUseCase {
  final IReporteRepository _repository;
  final IReportePendienteRepository _pendientesRepository;

  SincronizarReportesPendientesUseCase(
    this._repository,
    this._pendientesRepository,
  );

  Future<Either<Failure, ResultadoSincronizacionReportes>> execute() async {
    try {
      final pendientes = await _pendientesRepository.obtenerTodos();
      if (pendientes.isEmpty) {
        return const Right(
          ResultadoSincronizacionReportes(enviados: 0, pendientes: 0),
        );
      }

      var enviados = 0;
      final restantes = <ReportePendiente>[];

      for (var index = 0; index < pendientes.length; index++) {
        final reporte = pendientes[index];
        try {
          await _repository.crearReporte(
            tipo: reporte.tipo,
            latitud: reporte.latitud,
            longitud: reporte.longitud,
            notaVoz: reporte.notaVoz,
            rutaId: reporte.rutaId,
          );
          enviados++;
        } catch (error) {
          final failure = mapExceptionToFailure(error);
          restantes.add(reporte);
          if (failure is NetworkFailure) {
            restantes.addAll(pendientes.skip(index + 1));
            break;
          }
        }
      }

      await _pendientesRepository.reemplazarTodos(restantes);
      return Right(
        ResultadoSincronizacionReportes(
          enviados: enviados,
          pendientes: restantes.length,
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
