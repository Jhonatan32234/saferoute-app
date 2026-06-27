class NotificacionEntity {
  final String id;
  final String tipo;
  final String mensaje;
  final String reporteId;
  final double latitud;
  final double longitud;
  final String notaVoz;
  final String rutaId;
  final DateTime timestamp;
  bool leida;

  NotificacionEntity({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.reporteId,
    required this.latitud,
    required this.longitud,
    required this.notaVoz,
    required this.rutaId,
    required this.timestamp,
    this.leida = false,
  });

  factory NotificacionEntity.fromJson(Map<String, dynamic> json) {
    return NotificacionEntity(
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
