import 'package:injectable/injectable.dart';
import 'package:saferoute_app/features/home/domain/repositories/home_repository.dart';
import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/data/datasources/home_remote_datasource.dart';

@LazySingleton(as: IHomeRepository)
class HomeRepositoryImpl implements IHomeRepository {
  final HomeRemoteDataSource _api;

  HomeRepositoryImpl(this._api);

  @override
  Future<List<RutaEntity>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String token,
  }) async {
    return await _api.getRutas(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
      token: token,
    );
  }

  @override
  Future<String> iniciarViaje({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String polylineRuta,
    required String rutaId,
    required String token,
  }) async {
    return await _api.iniciarViaje(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
      polylineRuta: polylineRuta,
      rutaId: rutaId,
      token: token,
    );
  }

  @override
  Future<bool> finalizarViaje({
    required String viajeId,
    String? password,
    required String token,
  }) async {
    return await _api.finalizarViaje(
      viajeId: viajeId,
      password: password,
      token: token,
    );
  }
}