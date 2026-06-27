import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reporte_model.dart';

@lazySingleton
class ReportesRemoteDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  ReportesRemoteDataSource(this.client, this.dotenv);

  Future<ReporteModel> crearReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    required String notaVoz,
    required String rutaId,
    required String token,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/reportes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tipo': tipo.toLowerCase(),
        'latitud': latitud,
        'longitud': longitud,
        'nota_voz': notaVoz,
        'ruta_id': rutaId,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) return ReporteModel.fromJson({'status': 'ok'});
      return ReporteModel.fromJson(jsonDecode(response.body));
    }

    if (response.body.isNotEmpty) {
      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Error del servidor');
      } catch (_) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    }
    throw Exception('Error del servidor (${response.statusCode})');
  }
}