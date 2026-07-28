import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../repositories/notification_repository.dart';

@lazySingleton
class MarcarNotificacionLeidaUseCase {
  final INotificacionRepository _repository;

  MarcarNotificacionLeidaUseCase(this._repository);

  Future<Either<Failure, Unit>> execute(String id) {
    return guardUseCase(() async {
      await _repository.marcarLeida(id);
      return unit;
    });
  }
}
