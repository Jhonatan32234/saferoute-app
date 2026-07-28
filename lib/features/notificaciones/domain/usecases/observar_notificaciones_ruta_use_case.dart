import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../entities/notificacion_realtime_event.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class ObservarNotificacionesRutaUseCase {
  final INotificacionRepository _repository;

  ObservarNotificacionesRutaUseCase(this._repository);

  Stream<Either<Failure, NotificacionRealtimeEvent>> execute(
      String rutaId) async* {
    try {
      await for (final event in _repository.observarRuta(rutaId)) {
        yield Right(event);
      }
    } catch (error) {
      yield Left(mapExceptionToFailure(error));
    }
  }
}
