import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';

class DestinoRecienteModel extends DestinoReciente {
  DestinoRecienteModel({
    required super.id,
    required super.nombre,
    required super.lat,
    required super.lon,
    required super.fecha,
  });

  factory DestinoRecienteModel.fromJson(Map<String, dynamic> json) {
    return DestinoRecienteModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      lat: (json['lat'] ?? json['latitud'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? json['longitud'] ?? 0.0).toDouble(),
      fecha: DateTime.tryParse(json['fecha_creacion'] ?? json['fecha'] ?? '') ?? DateTime.now(),
    );
  }

  DestinoReciente toEntity() => this;
}
