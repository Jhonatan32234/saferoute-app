// ============================================
// SAFEROUTE · CONTRATO COMPARTIDO
// NO MODIFICAR SIN ACUERDO ENTRE AMBOS DEVS
// ============================================

// --- MODELOS DE DATOS ---

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo,
    'seguridad': seguridad,
    'distancia_km': distanciaKm,
    'tiempo_minutos': tiempoMinutos,
    'riesgo_combinado': riesgoCombinado,
    'tramos': tramos.map((t) => t.toJson()).toList(),
  };
}

/// Representa un tramo individual de una ruta
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

  Map<String, dynamic> toJson() => {
    'cluster_id': clusterId,
    'lat': lat,
    'lon': lon,
    'riesgo': riesgo,
    'num_inundaciones': numInundaciones,
  };
}

/// Representa un incidente reportado cercano
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

  /// Texto legible del tiempo transcurrido
  String get tiempoTranscurrido {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  /// Ícono según tipo
  String get icono {
    switch (tipo) {
      case 'accidente': return '🚗';
      case 'inundacion': return '🌊';
      case 'bache': return '🕳️';
      case 'bloqueo': case 'derrumbe': return '🚧';
      case 'sin_luz': return '💡';
      default: return '⚠️';
    }
  }

  /// Color según tipo
  int get color {
    switch (tipo) {
      case 'accidente': return 0xFFE94560;
      case 'inundacion': return 0xFF2196F3;
      case 'bache': return 0xFFF0A500;
      case 'bloqueo': case 'derrumbe': return 0xFF795548;
      case 'sin_luz': return 0xFF9C27B0;
      default: return 0xFF607D8B;
    }
  }
}

/// Representa el resumen semanal del dashboard
class ResumenSemanal {
  final int totalReportes;
  final List<TopicoInfo> topicos;
  final String resumenLlm;
  final TopicoInfo? topicoDominante;

  const ResumenSemanal({
    required this.totalReportes,
    required this.topicos,
    required this.resumenLlm,
    this.topicoDominante,
  });

  factory ResumenSemanal.fromJson(Map<String, dynamic> json) {
    final topicosList = (json['topicos'] as List<dynamic>? ?? [])
        .map((t) => TopicoInfo.fromJson(t as Map<String, dynamic>))
        .toList();
    return ResumenSemanal(
      totalReportes: (json['total_reportes'] ?? 0).toInt(),
      topicos: topicosList,
      resumenLlm: json['resumen_llm'] ?? '',
      topicoDominante: topicosList.isNotEmpty ? topicosList.first : null,
    );
  }
}

class TopicoInfo {
  final String nombre;
  final int frecuencia;
  final double porcentaje;
  final String tendencia;

  const TopicoInfo({
    required this.nombre,
    required this.frecuencia,
    required this.porcentaje,
    required this.tendencia,
  });

  factory TopicoInfo.fromJson(Map<String, dynamic> json) {
    return TopicoInfo(
      nombre: json['nombre'] ?? '',
      frecuencia: (json['frecuencia'] ?? 0).toInt(),
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
      tendencia: json['tendencia'] ?? '',
    );
  }
}

/// Tipos de incidente disponibles para reportar
class TiposIncidente {
  static const List<Map<String, dynamic>> opciones = [
    {'tipo': 'accidente', 'icono': '🚗', 'label': 'Accidente'},
    {'tipo': 'inundacion', 'icono': '🌊', 'label': 'Inundación'},
    {'tipo': 'bache', 'icono': '🕳️', 'label': 'Bache'},
    {'tipo': 'bloqueo', 'icono': '🚧', 'label': 'Bloqueo'},
  ];

  static String label(String tipo) {
    return opciones.firstWhere((o) => o['tipo'] == tipo,
        orElse: () => {'label': tipo})['label'] as String;
  }

  static String icono(String tipo) {
    return opciones.firstWhere((o) => o['tipo'] == tipo,
        orElse: () => {'icono': '⚠️'})['icono'] as String;
  }
}