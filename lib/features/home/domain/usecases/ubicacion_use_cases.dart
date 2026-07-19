import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../entities/geo_point.dart';
import '../repositories/location_repository.dart';

@lazySingleton
class ObtenerUbicacionActualUseCase {
  final ILocationRepository _repository;

  ObtenerUbicacionActualUseCase(this._repository);

  Future<Either<Failure, GeoPoint>> execute() {
    return guardUseCase(_repository.obtenerUbicacionActual);
  }
}

@lazySingleton
class ObservarUbicacionUseCase {
  final ILocationRepository _repository;

  ObservarUbicacionUseCase(this._repository);

  Stream<Either<Failure, GeoPoint>> execute() async* {
    try {
      await for (final point in _repository.observarUbicacion()) {
        yield Right(point);
      }
    } catch (error) {
      yield Left(mapExceptionToFailure(error));
    }
  }
}
