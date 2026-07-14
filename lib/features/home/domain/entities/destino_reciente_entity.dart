class DestinoReciente {
  final String id;
  final String nombre;
  final double lat;
  final double lon;
  final DateTime fecha;

  DestinoReciente({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lon,
    required this.fecha,
  });

  factory DestinoReciente.fromJson(Map<String, dynamic> json) => DestinoReciente(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? '',
    lat: (json['lat'] ?? json['latitud'] ?? 0.0).toDouble(),
    lon: (json['lon'] ?? json['longitud'] ?? 0.0).toDouble(),
    fecha: DateTime.tryParse(json['fecha_creacion'] ?? json['fecha'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'lat': lat,
    'lon': lon,
    'fecha': fecha.toIso8601String(),
  };
}
