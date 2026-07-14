import '../../domain/entities/notificacion_entity.dart';

class NotificacionModel extends NotificacionEntity {
  NotificacionModel({
    required super.id,
    required super.tipo,
    required super.mensaje,
    required super.reporteId,
    required super.latitud,
    required super.longitud,
    required super.notaVoz,
    required super.rutaId,
    required super.timestamp,
    required super.leida,
    super.esAdmin,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    final tipoOriginal = (json['tipo'] ?? '').toString();
    final enviadoPor = (json['enviado_por'] ?? '').toString();
    
    // Es admin si el tipo es alerta_incidente_admin o si explícitamente dice que lo envía admin
    final bool admin = tipoOriginal == 'alerta_incidente_admin' || enviadoPor == 'admin';

    return NotificacionModel(
      id: (json['id'] ?? json['reporte_id'] ?? '').toString(),
      tipo: (json['tipo_incidente'] ?? tipoOriginal.replaceFirst('alerta_incidente_', '')).toString(),
      mensaje: json['mensaje'] ?? '',
      reporteId: (json['reporte_id'] ?? '').toString(),
      latitud: (json['latitud'] ?? json['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lon'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      timestamp: DateTime.tryParse(json['fecha_envio'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      leida: json['leida'] ?? false,
      esAdmin: admin,
    );
  }

  NotificacionEntity toEntity() {
    return NotificacionEntity(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      reporteId: reporteId,
      latitud: latitud,
      longitud: longitud,
      notaVoz: notaVoz,
      rutaId: rutaId,
      timestamp: timestamp,
      leida: leida,
      esAdmin: esAdmin,
    );
  }
}
