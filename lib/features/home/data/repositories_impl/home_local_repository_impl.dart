import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/home_local_repository.dart';

@LazySingleton(as: IHomeLocalRepository)
class HomeLocalRepositoryImpl implements IHomeLocalRepository {
  static const _activeTripKey = 'viaje_id_activo';

  final FlutterSecureStorage _storage;

  HomeLocalRepositoryImpl(this._storage);

  @override
  Future<void> guardarViajeActivo(String viajeId) async {
    try {
      await _storage.write(key: _activeTripKey, value: viajeId);
    } catch (error) {
      throw CacheException('No fue posible guardar el viaje activo: $error');
    }
  }

  @override
  Future<void> limpiarViajeActivo() async {
    try {
      await _storage.delete(key: _activeTripKey);
    } catch (error) {
      throw CacheException('No fue posible limpiar el viaje activo: $error');
    }
  }
}
