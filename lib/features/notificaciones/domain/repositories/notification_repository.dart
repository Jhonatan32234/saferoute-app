import '../entities/notificacion_entity.dart';

abstract class INotificacionRepository {
  Future<List<NotificacionEntity>> getHistorial();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
  String get baseUrl;
}
