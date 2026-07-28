import '../../domain/entities/reporte_entity.dart';

class ReporteModel extends ReporteEntity {
  const ReporteModel({
    required super.id, required super.tipo, required super.latitud,
    required super.longitud, required super.notaVoz, required super.rutaId,
    required super.timestamp, required super.vigente, required super.confirmaciones,
  });

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    return ReporteModel(
      id: (json['id'] ?? '').toString(),
      tipo: json['tipo'] ?? '',
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: (json['ruta_id'] ?? '').toString(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      vigente: json['vigente'] ?? true,
      confirmaciones: (json['confirmaciones'] ?? 0).toInt(),
    );
  }
}