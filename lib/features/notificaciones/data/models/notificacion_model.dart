import '../../domain/entities/notificacion_entity.dart';

class NotificacionModel extends NotificacionEntity {
  NotificacionModel({
    required super.id, required super.tipo, required super.mensaje,
    required super.reporteId, required super.latitud, required super.longitud,
    required super.notaVoz, required super.rutaId, required super.timestamp,
    required super.leida,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: (json['id'] ?? json['reporte_id'] ?? '').toString(),
      tipo: json['tipo_incidente'] ?? json['tipo'] ?? 'nuevo_reporte',
      mensaje: json['mensaje'] ?? '',
      reporteId: (json['reporte_id'] ?? '').toString(),
      latitud: (json['latitud'] ?? json['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lon'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      timestamp: DateTime.tryParse(json['fecha_envio'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      leida: json['leida'] ?? false,
    );
  }
}