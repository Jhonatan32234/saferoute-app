import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class MarcarTodasNotificacionesLeidasUseCase {
  final INotificacionRepository _repository;

  MarcarTodasNotificacionesLeidasUseCase(this._repository);

  Future<Either<Failure, Unit>> execute() {
    return guardUseCase(() async {
      await _repository.marcarTodasLeidas();
      return unit;
    });
  }
}
