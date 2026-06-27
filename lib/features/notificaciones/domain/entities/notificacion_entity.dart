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
    required this.id, required this.tipo, required this.mensaje,
    required this.reporteId, required this.latitud, required this.longitud,
    required this.notaVoz, required this.rutaId, required this.timestamp,
    this.leida = false,
  });
}