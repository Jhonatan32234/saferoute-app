import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../entities/reporte_pendiente.dart';
import '../entities/resultado_envio_reporte.dart';
import '../repositories/reporte_pendiente_repository.dart';
import '../repositories/reporte_repository.dart';

class EnviarReporteParams {
  final String tipo;
  final double latitud;
  final double longitud;
  final String notaVoz;
  final String rutaId;

  const EnviarReporteParams({
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.notaVoz,
    required this.rutaId,
  });
}

@lazySingleton
class EnviarReporteUseCase {
  final IReporteRepository _repository;
  final IReportePendienteRepository _pendientesRepository;

  EnviarReporteUseCase(this._repository, this._pendientesRepository);

  Future<Either<Failure, ResultadoEnvioReporte>> execute(
    EnviarReporteParams params,
  ) async {
    try {
      await _repository.crearReporte(
        tipo: params.tipo,
        latitud: params.latitud,
        longitud: params.longitud,
        notaVoz: params.notaVoz.trim(),
        rutaId: params.rutaId,
      );
      return const Right(
        ResultadoEnvioReporte(DisposicionEnvioReporte.enviado),
      );
    } catch (error) {
      final failure = mapExceptionToFailure(error);
      if (failure is! NetworkFailure) return Left(failure);

      try {
        await _pendientesRepository.guardar(
          ReportePendiente(
            tipo: params.tipo,
            latitud: params.latitud,
            longitud: params.longitud,
            notaVoz: params.notaVoz.trim(),
            rutaId: params.rutaId,
            timestamp: DateTime.now(),
          ),
        );
        return const Right(
          ResultadoEnvioReporte(DisposicionEnvioReporte.encolado),
        );
      } catch (cacheError) {
        return Left(mapExceptionToFailure(cacheError));
      }
    }
  }
}
