import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../repositories/notification_repository.dart';

class EnviarTelemetriaParams {
  final double lat;
  final double lon;
  final double velocidad;
  final String rutaId;

  const EnviarTelemetriaParams({
    required this.lat,
    required this.lon,
    required this.velocidad,
    required this.rutaId,
  });
}

@lazySingleton
class EnviarTelemetriaUseCase {
  final INotificacionRepository _repository;

  EnviarTelemetriaUseCase(this._repository);

  Future<Either<Failure, Unit>> execute(EnviarTelemetriaParams params) {
    return guardUseCase(() async {
      await _repository.enviarTelemetria(
        lat: params.lat,
        lon: params.lon,
        velocidad: params.velocidad,
        rutaId: params.rutaId,
      );
      return unit;
    });
  }
}
