import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class ActualizarPerfilParams {
  final String nombre;
  final String telefono;
  final String email;

  const ActualizarPerfilParams({
    required this.nombre,
    required this.telefono,
    required this.email,
  });
}

@lazySingleton
class ActualizarPerfilUseCase {
  final IProfileRepository _repository;

  ActualizarPerfilUseCase(this._repository);

  Future<Either<Failure, ProfileEntity>> execute(
    ActualizarPerfilParams params,
  ) async {
    final nombre = params.nombre.trim();
    final telefono = params.telefono.trim();
    final email = params.email.trim().toLowerCase();

    if (nombre.isEmpty || email.isEmpty) {
      return const Left(
        ValidationFailure('El nombre y el correo son obligatorios.'),
      );
    }

    try {
      await _repository.updateProfile(nombre, telefono, email);
      return Right(await _repository.getProfile());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
