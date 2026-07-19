import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

@lazySingleton
class ObtenerPerfilUseCase {
  final IProfileRepository _repository;

  ObtenerPerfilUseCase(this._repository);

  Future<Either<Failure, ProfileEntity>> execute() {
    return guardUseCase(_repository.getProfile);
  }
}
