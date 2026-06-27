class ReporteEntity {
  final String id;
  final String tipo;
  final double latitud;
  final double longitud;
  final String notaVoz;
  final String rutaId;
  final DateTime timestamp;
  final bool vigente;
  final int confirmaciones;

  const ReporteEntity({
    required this.id, required this.tipo, required this.latitud,
    required this.longitud, required this.notaVoz, required this.rutaId,
    required this.timestamp, required this.vigente, required this.confirmaciones,
  });
}