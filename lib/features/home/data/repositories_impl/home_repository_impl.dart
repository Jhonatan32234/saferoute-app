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
  }) async {
    return await _api.getRutas(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
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
  }) async {
    return await _api.iniciarViaje(
      origenLat: origenLat,
      origenLon: origenLon,
      destinoLat: destinoLat,
      destinoLon: destinoLon,
      polylineRuta: polylineRuta,
      rutaId: rutaId,
    );
  }

  @override
  Future<bool> finalizarViaje({
    required String viajeId,
    String? password,
  }) async {
    return await _api.finalizarViaje(
      viajeId: viajeId,
      password: password,
    );
  }

  @override
  Future<List<DestinoReciente>> getDestinosRecientes() async {
    final models = await _api.getDestinosRecientes();
    return models.map((m) => m as DestinoReciente).toList();
  }

  @override
  Future<void> guardarDestinoReciente({
    required String nombre,
    required double lat,
    required double lon,
  }) async {
    await _api.guardarDestinoReciente(
      nombre: nombre,
      lat: lat,
      lon: lon,
    );
  }

  @override
  Future<void> eliminarDestinoReciente(String id) async {
    await _api.eliminarDestinoReciente(id);
  }
}
