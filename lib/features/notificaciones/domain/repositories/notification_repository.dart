import '../entities/notificacion_entity.dart';

abstract class INotificacionRepository {
  Future<List<NotificacionEntity>> getHistorial(String token);
}