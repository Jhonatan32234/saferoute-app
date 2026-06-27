import 'package:injectable/injectable.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/ruta_entity.dart';
import '../datasources/home_remote_datasource.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepositoryImpl implements IHomeRepository {
  final HomeRemoteDataSource _api;

  HomeRepositoryImpl(this._api);

  @override
  // ¡CAMBIO CLAVE! Devuelve List<RutaEntity>
  Future<List<RutaEntity>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String token,
  }) async {
    // Como RutaModel hereda de RutaEntity, podemos retornarlo directamente
    return await _api.getRutas(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
      token: token,
    );
  }
}