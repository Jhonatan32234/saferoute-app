import '../entities/notificacion_entity.dart';
import '../entities/notificacion_realtime_event.dart';

abstract class INotificacionRepository {
  Future<List<NotificacionEntity>> getHistorial();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
  String get baseUrl;

  // Realtime / Telemetry
  Stream<NotificacionRealtimeEvent> observarRuta(String rutaId);
  
  Future<void> enviarTelemetria({
    required double lat,
    required double lon,
    required double velocidad,
    required String rutaId,
  });

  Future<void> desconectarRuta();
}
