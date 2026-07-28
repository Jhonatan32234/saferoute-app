class ReportePendiente {
  final String tipo;
  final double latitud;
  final double longitud;
  final String notaVoz;
  final String rutaId;
  final DateTime timestamp;

  const ReportePendiente({
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.notaVoz,
    required this.rutaId,
    required this.timestamp,
  });
}
