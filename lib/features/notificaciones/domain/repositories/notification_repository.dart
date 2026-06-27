import '../entities/notificacion_entity.dart';

abstract class INotificacionRepository {
  Future<List<NotificacionEntity>> getHistorial(String token);
  Future<void> marcarLeida(String token, String id);
  Future<void> marcarTodasLeidas(String token);
  String get baseUrl;
}