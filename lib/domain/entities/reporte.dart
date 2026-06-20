class Reporte {
  final String id;
  final String tipo;
  final double latitud;
  final double longitud;
  final String notaVoz;
  final String rutaId;
  final DateTime timestamp;
  final bool vigente;
  final int confirmaciones;

  const Reporte({
    required this.id,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.notaVoz,
    required this.rutaId,
    required this.timestamp,
    required this.vigente,
    required this.confirmaciones,
  });

  bool get esInundacion => tipo == 'inundacion';
  bool get esAccidente => tipo == 'accidente';
  bool get esBache => tipo == 'bache';
  bool get esDerrumbe => tipo == 'derrumbe';

  String get tiempoTranscurrido {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}