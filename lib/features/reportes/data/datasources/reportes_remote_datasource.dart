import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/network/api_client.dart';
import '../models/reporte_model.dart';

@lazySingleton
class ReportesRemoteDataSource {
  final ApiClient client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  ReportesRemoteDataSource(this.client, this.dotenv);

  Future<ReporteModel> crearReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    required String notaVoz,
    required String rutaId,
  }) async {
    final String validRutaId = (rutaId.isEmpty || rutaId == 'sin-ruta' || rutaId == 'libre') ? "0" : rutaId;

    final Map<String, dynamic> body = {
      'tipo': tipo,
      'latitud': latitud,
      'longitud': longitud,
      'nota_voz': notaVoz,
      'ruta_id': validRutaId,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/api/reportes'),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.body.isEmpty) return ReporteModel.fromJson({'status': 'ok'});
      return ReporteModel.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 400) {
      // Ignoramos el JSON de la API por completo y enviamos un mensaje amigable
      throw 'La nota de voz no describe el incidente seleccionado. Por favor, intenta describirlo con más detalle.';
    }

    throw 'No se pudo enviar el reporte. Inténtalo más tarde.';
  }
}
