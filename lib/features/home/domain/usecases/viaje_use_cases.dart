import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../entities/geo_point.dart';
import '../entities/ruta_entity.dart';
import '../repositories/home_local_repository.dart';
import '../repositories/home_repository.dart';

class IniciarViajeParams {
  final GeoPoint origen;
  final GeoPoint destino;
  final RutaEntity ruta;
  final String nombreDestino;

  const IniciarViajeParams({
    required this.origen,
    required this.destino,
    required this.ruta,
    required this.nombreDestino,
  });
}

@lazySingleton
class IniciarViajeUseCase {
  final IHomeRepository _repository;
  final IHomeLocalRepository _localRepository;

  IniciarViajeUseCase(this._repository, this._localRepository);

  Future<Either<Failure, String>> execute(IniciarViajeParams params) async {
    try {
      final id = await _repository.iniciarViaje(
        origenLat: params.origen.latitude,
        origenLon: params.origen.longitude,
        destinoLat: params.destino.latitude,
        destinoLon: params.destino.longitude,
        polylineRuta: params.ruta.polyline,
        rutaId: params.ruta.id.isEmpty ? params.ruta.nombre : params.ruta.id,
      );
      await _localRepository.guardarViajeActivo(id);

      if (params.nombreDestino.trim().isNotEmpty) {
        try {
          await _repository.guardarDestinoReciente(
            nombre: params.nombreDestino.trim(),
            lat: params.destino.latitude,
            lon: params.destino.longitude,
          );
        } catch (_) {
          // Guardar el destino es secundario y no debe cancelar un viaje iniciado.
        }
      }
      return Right(id);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}

class FinalizarViajeParams {
  final String viajeId;
  final String? password;

  const FinalizarViajeParams({required this.viajeId, this.password});
}

@lazySingleton
class FinalizarViajeUseCase {
  final IHomeRepository _repository;
  final IHomeLocalRepository _localRepository;

  FinalizarViajeUseCase(this._repository, this._localRepository);

  Future<Either<Failure, Unit>> execute(FinalizarViajeParams params) async {
    try {
      final success = await _repository.finalizarViaje(
        viajeId: params.viajeId,
        password: params.password,
      );
      if (!success) {
        return const Left(
            ServerFailure('El servidor no pudo finalizar el viaje.'));
      }
      await _localRepository.limpiarViajeActivo();
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
