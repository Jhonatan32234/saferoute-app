import 'notificacion_entity.dart';

sealed class NotificacionRealtimeEvent {
  const NotificacionRealtimeEvent();
}

class NotificacionConexionCambiada extends NotificacionRealtimeEvent {
  final bool conectada;
  final String? message;

  const NotificacionConexionCambiada(this.conectada, {this.message});
}

class NotificacionAlertaProximidad extends NotificacionRealtimeEvent {
  final NotificacionEntity notificacion;

  const NotificacionAlertaProximidad(this.notificacion);
}

class NotificacionAlertaAdministrativa extends NotificacionRealtimeEvent {
  final NotificacionEntity notificacion;

  const NotificacionAlertaAdministrativa(this.notificacion);
}

class NotificacionTelemetriaConfirmada extends NotificacionRealtimeEvent {
  final bool desviado;

  const NotificacionTelemetriaConfirmada({required this.desviado});
}

class NotificacionHistorialInvalidado extends NotificacionRealtimeEvent {
  const NotificacionHistorialInvalidado();
}
