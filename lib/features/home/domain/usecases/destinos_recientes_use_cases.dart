import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../entities/destino_reciente_entity.dart';
import '../repositories/home_repository.dart';

@lazySingleton
class ObtenerDestinosRecientesUseCase {
  final IHomeRepository _repository;

  ObtenerDestinosRecientesUseCase(this._repository);

  Future<Either<Failure, List<DestinoReciente>>> execute() {
    return guardUseCase(_repository.getDestinosRecientes);
  }
}

@lazySingleton
class EliminarDestinoRecienteUseCase {
  final IHomeRepository _repository;

  EliminarDestinoRecienteUseCase(this._repository);

  Future<Either<Failure, Unit>> execute(String id) {
    return guardUseCase(() async {
      await _repository.eliminarDestinoReciente(id);
      return unit;
    });
  }
}
