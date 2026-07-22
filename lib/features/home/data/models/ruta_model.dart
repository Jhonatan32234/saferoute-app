import '../../domain/entities/ruta_entity.dart';

class RutaModel extends RutaEntity {
  const RutaModel({
    required super.id,
    required super.nombre,
    required super.seguridad,
    required super.coordenadas,
    required super.polyline,
    required super.distanciaKm,
    required super.tiempoMinutos,
    required super.tipo,
    required super.riesgoCombinado,
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> coords = json['geometria_osrm'] ?? [];
    
    // Intentamos obtener la polilínea del JSON
    String encodedPolyline = json['polyline'] ?? json['geometry'] ?? json['polyline_ruta'] ?? '';

    // Si el servidor no la envió, la generamos localmente para cumplir con la API
    if (encodedPolyline.isEmpty && coords.isNotEmpty) {
      encodedPolyline = _encodePolyline(coords);
    }

    return RutaModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Ruta Desconocida',
      seguridad: json['seguridad'] ?? 'verde',
      coordenadas: coords,
      polyline: encodedPolyline,
      distanciaKm: (json['distancia_km'] ?? 0).toDouble(),
      tiempoMinutos: (json['tiempo_minutos'] ?? 0).toInt(),
      tipo: json['tipo'] ?? 'estandar',
      riesgoCombinado: (json['riesgo_combinado'] ?? 0).toDouble(),
    );
  }

  /// Implementación del algoritmo de codificación de polilíneas de Google (Precision 5)
  static String _encodePolyline(List<dynamic> coordinates) {
    StringBuffer polyline = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (var point in coordinates) {
      if (point is! List || point.length < 2) continue;
      
      // Multiplicamos por 1e5 (precisión 5) que es lo que espera tu API de Go
      // La API envía [latitude, longitude] en geometria_osrm
      int lat = (point[0] * 1e5).round();
      int lng = (point[1] * 1e5).round();

      _encodeValue(lat - prevLat, polyline);
      _encodeValue(lng - prevLng, polyline);

      prevLat = lat;
      prevLng = lng;
    }

    return polyline.toString();
  }

  static void _encodeValue(int value, StringBuffer polyline) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      polyline.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    polyline.writeCharCode(v + 63);
  }
}
