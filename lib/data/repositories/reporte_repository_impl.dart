import '../../domain/entities/reporte.dart';
import '../../domain/repositories/reporte_repository.dart';
import '../datasources/api_datasources.dart';
import '../models/reporte_model.dart';
import 'dart:convert';

class ReporteRepositoryImpl implements IReporteRepository {
  final ApiDataSource _api;

  ReporteRepositoryImpl({required ApiDataSource api}) : _api = api;

  @override
  Future<Reporte> crearReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    required String notaVoz,
    required String rutaId,
    required String token,
  }) async {
    final data = await _api.crearReporte(
      tipo: tipo,
      latitud: latitud,
      longitud: longitud,
      notaVoz: notaVoz,
      rutaId: rutaId,
      token: token,
    );
    return ReporteModel.fromJson(data);
  }

  @override
  Future<List<Reporte>> obtenerReportes({required String token}) async {
    final response = await _api.client.get(
      Uri.parse('${_api.baseUrl}/api/reportes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    return (data['reportes'] as List)
        .map((json) => ReporteModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> validarReporte({
    required String reporteId,
    required bool vigente,
    required String token,
  }) async {
    await _api.client.put(
      Uri.parse('${_api.baseUrl}/api/reportes/$reporteId/validar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'vigente': vigente}),
    );
  }
}
