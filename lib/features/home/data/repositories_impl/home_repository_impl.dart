import 'package:injectable/injectable.dart';
import 'package:saferoute_app/features/home/domain/repositories/home_repository.dart';
import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';
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

  @override
  Future<List<DestinoReciente>> getDestinosRecientes(String token) async {
    final models = await _api.getDestinosRecientes(token);
    // Cast explícito para asegurar compatibilidad de tipos en el override
    return models.map((m) => m as DestinoReciente).toList();
  }

  @override
  Future<void> guardarDestinoReciente({
    required String nombre,
    required double lat,
    required double lon,
    required String token,
  }) async {
    await _api.guardarDestinoReciente(
      nombre: nombre,
      lat: lat,
      lon: lon,
      token: token,
    );
  }

  @override
  Future<void> eliminarDestinoReciente(String id, String token) async {
    await _api.eliminarDestinoReciente(id, token);
  }
}
