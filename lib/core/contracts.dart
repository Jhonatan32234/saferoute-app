/// Representa una ruta calculada por el motor
class RutaSegura {
  final String id;
  final String nombre;
  final String tipo;
  final String seguridad;
  final double distanciaKm;
  final int tiempoMinutos;
  final double riesgoCombinado;
  final List<TramoRuta> tramos;

  const RutaSegura({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.seguridad,
    required this.distanciaKm,
    required this.tiempoMinutos,
    required this.riesgoCombinado,
    required this.tramos,
  });

  factory RutaSegura.fromJson(Map<String, dynamic> json) {
    return RutaSegura(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      seguridad: json['seguridad'] ?? 'verde',
      distanciaKm: (json['distancia_km'] ?? 0).toDouble(),
      tiempoMinutos: (json['tiempo_minutos'] ?? 0).toInt(),
      riesgoCombinado: (json['riesgo_combinado'] ?? 0).toDouble(),
      tramos: (json['tramos'] as List<dynamic>? ?? [])
          .map((t) => TramoRuta.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TramoRuta {
  final int clusterId;
  final double lat;
  final double lon;
  final double riesgo;
  final int numInundaciones;

  const TramoRuta({
    required this.clusterId,
    required this.lat,
    required this.lon,
    required this.riesgo,
    required this.numInundaciones,
  });

  factory TramoRuta.fromJson(Map<String, dynamic> json) {
    return TramoRuta(
      clusterId: (json['cluster_id'] ?? 0).toInt(),
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      riesgo: (json['riesgo'] ?? 0).toDouble(),
      numInundaciones: (json['num_inundaciones'] ?? 0).toInt(),
    );
  }
}

class IncidenteCercano {
  final String id;
  final String tipo;
  final double lat;
  final double lon;
  final String descripcion;
  final int confirmaciones;
  final DateTime timestamp;

  const IncidenteCercano({
    required this.id,
    required this.tipo,
    required this.lat,
    required this.lon,
    required this.descripcion,
    required this.confirmaciones,
    required this.timestamp,
  });

  factory IncidenteCercano.fromJson(Map<String, dynamic> json) {
    return IncidenteCercano(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? '',
      lat: (json['latitud'] ?? 0).toDouble(),
      lon: (json['longitud'] ?? 0).toDouble(),
      descripcion: json['nota_voz'] ?? json['texto'] ?? '',
      confirmaciones: (json['confirmaciones'] ?? 0).toInt(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}