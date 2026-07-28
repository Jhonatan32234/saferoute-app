import '../../../../core/errors/failure.dart';
import '../../domain/entities/notificacion_entity.dart';

class NotificacionSnapshot {
  final List<NotificacionEntity> historial;
  final List<NotificacionEntity> alertasMapa;
  final NotificacionEntity? alertaUrgente;
  final bool conectada;

  const NotificacionSnapshot({
    this.historial = const [],
    this.alertasMapa = const [],
    this.alertaUrgente,
    this.conectada = false,
  });

  NotificacionSnapshot copyWith({
    List<NotificacionEntity>? historial,
    List<NotificacionEntity>? alertasMapa,
    NotificacionEntity? alertaUrgente,
    bool clearAlertaUrgente = false,
    bool? conectada,
  }) {
    return NotificacionSnapshot(
      historial: historial ?? this.historial,
      alertasMapa: alertasMapa ?? this.alertasMapa,
      alertaUrgente:
          clearAlertaUrgente ? null : alertaUrgente ?? this.alertaUrgente,
      conectada: conectada ?? this.conectada,
    );
  }
}

sealed class NotificacionState {
  final NotificacionSnapshot snapshot;

  const NotificacionState(this.snapshot);
}

class NotificacionInitial extends NotificacionState {
  const NotificacionInitial() : super(const NotificacionSnapshot());
}

class NotificacionLoading extends NotificacionState {
  const NotificacionLoading(super.snapshot);
}

class NotificacionLoaded extends NotificacionState {
  const NotificacionLoaded(super.snapshot);
}

class NotificacionError extends NotificacionState {
  final Failure failure;

  const NotificacionError(this.failure, super.snapshot);
}
