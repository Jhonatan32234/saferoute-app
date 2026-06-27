class RutaEntity {
  final String id;
  final String nombre;
  final String seguridad;
  final List<dynamic> coordenadas;

  // Nuevas variables requeridas por tu UI
  final double distanciaKm;
  final int tiempoMinutos;
  final String tipo;
  final double riesgoCombinado;

  const RutaEntity({
    required this.id,
    required this.nombre,
    required this.seguridad,
    required this.coordenadas,
    required this.distanciaKm,
    required this.tiempoMinutos,
    required this.tipo,
    required this.riesgoCombinado,
  });
}