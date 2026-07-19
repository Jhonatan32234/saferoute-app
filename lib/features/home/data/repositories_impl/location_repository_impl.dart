import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/location_repository.dart';

@LazySingleton(as: ILocationRepository)
class LocationRepositoryImpl implements ILocationRepository {
  @override
  Future<GeoPoint> obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PermissionException(
        'Activa el servicio de ubicación para continuar.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionException(
        'SafeRoute no tiene permiso para acceder a la ubicación.',
      );
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      throw const PermissionException(
        'No fue posible determinar la ubicación actual.',
      );
    }
    return GeoPoint(position.latitude, position.longitude);
  }

  @override
  Stream<GeoPoint> observarUbicacion() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => GeoPoint(position.latitude, position.longitude));
  }
}
