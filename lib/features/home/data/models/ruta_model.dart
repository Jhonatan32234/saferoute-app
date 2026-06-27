import '../../domain/entities/ruta_entity.dart';

class RutaModel extends RutaEntity {
  const RutaModel({
    required super.id,
    required super.nombre,
    required super.seguridad,
    required super.coordenadas,
    required super.distanciaKm,
    required super.tiempoMinutos,
    required super.tipo,
    required super.riesgoCombinado,
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Ruta Desconocida',
      seguridad: json['seguridad'] ?? 'verde',
      coordenadas: json['geometria_osrm'] ?? [], // Ajustado al JSON que vi en tu provider
      distanciaKm: (json['distancia_km'] ?? 0).toDouble(),
      tiempoMinutos: (json['tiempo_minutos'] ?? 0).toInt(),
      tipo: json['tipo'] ?? 'estandar',
      riesgoCombinado: (json['riesgo_combinado'] ?? 0).toDouble(),
    );
  }
}