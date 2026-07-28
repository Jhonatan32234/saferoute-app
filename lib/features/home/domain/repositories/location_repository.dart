import '../entities/geo_point.dart';

abstract class ILocationRepository {
  Future<GeoPoint> obtenerUbicacionActual();
  Stream<GeoPoint> observarUbicacion();
}
