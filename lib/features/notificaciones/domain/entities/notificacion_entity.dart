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
  final bool esAdmin;
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
    this.esAdmin = false,
    this.leida = false,
  });

  factory NotificacionEntity.fromJson(Map<String, dynamic> json) {
    final tipoOriginal = (json['tipo'] ?? '').toString();
    final enviadoPor = (json['enviado_por'] ?? '').toString();
    
    // Es admin si el tipo es alerta_incidente_admin o si explícitamente dice que lo envía admin
    final bool admin = tipoOriginal == 'alerta_incidente_admin' || enviadoPor == 'admin';

    return NotificacionEntity(
      id: (json['id'] ?? json['reporte_id'] ?? '').toString(),
      tipo: (json['tipo_incidente'] ?? tipoOriginal.replaceFirst('alerta_incidente_', '')).toString(),
      mensaje: json['mensaje'] ?? '',
      reporteId: (json['reporte_id'] ?? '').toString(),
      latitud: (json['latitud'] ?? json['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lon'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      timestamp: DateTime.tryParse(json['fecha_envio'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      esAdmin: admin,
      leida: json['leida'] ?? false,
    );
  }
}
