import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class DetenerNotificacionesRutaUseCase {
  final INotificacionRepository _repository;

  DetenerNotificacionesRutaUseCase(this._repository);

  Future<Either<Failure, Unit>> execute() {
    return guardUseCase(() async {
      await _repository.desconectarRuta();
      return unit;
    });
  }
}
