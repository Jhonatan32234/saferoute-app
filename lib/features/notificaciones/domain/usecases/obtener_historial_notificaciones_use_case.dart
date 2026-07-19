import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../entities/notificacion_entity.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class ObtenerHistorialNotificacionesUseCase {
  final INotificacionRepository _repository;

  ObtenerHistorialNotificacionesUseCase(this._repository);

  Future<Either<Failure, List<NotificacionEntity>>> execute() {
    return guardUseCase(_repository.getHistorial);
  }
}
