import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase_guard.dart';
import '../entities/ruta_entity.dart';
import '../repositories/home_repository.dart';

class BuscarRutasParams {
  final double origenLat;
  final double origenLon;
  final double destinoLat;
  final double destinoLon;

  const BuscarRutasParams({
    required this.origenLat,
    required this.origenLon,
    required this.destinoLat,
    required this.destinoLon,
  });
}

@lazySingleton
class BuscarRutasUseCase {
  final IHomeRepository _repository;

  BuscarRutasUseCase(this._repository);

  Future<Either<Failure, List<RutaEntity>>> execute(BuscarRutasParams params) {
    return guardUseCase(
      () => _repository.getRutas(
        origenLat: params.origenLat,
        origenLon: params.origenLon,
        destinoLat: params.destinoLat,
        destinoLon: params.destinoLon,
      ),
    );
  }
}
