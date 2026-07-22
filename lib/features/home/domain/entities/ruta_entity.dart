class RutaEntity {
  final String id;
  final String nombre;
  final String seguridad;
  final List<dynamic> coordenadas;
  final String polyline; // <--- Campo para la polilínea codificada

  final double distanciaKm;
  final int tiempoMinutos;
  final String tipo;
  final double riesgoCombinado;

  const RutaEntity({
    required this.id,
    required this.nombre,
    required this.seguridad,
    required this.coordenadas,
    required this.polyline,
    required this.distanciaKm,
    required this.tiempoMinutos,
    required this.tipo,
    required this.riesgoCombinado,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RutaEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
