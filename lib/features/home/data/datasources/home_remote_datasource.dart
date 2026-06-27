import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/ruta_model.dart'; // <-- IMPORTANTE

@lazySingleton
class HomeRemoteDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  HomeRemoteDataSource(this.client, this.dotenv);

  // ¡CAMBIO CLAVE! Ahora devuelve List<RutaModel>
  Future<List<RutaModel>> getRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String token,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/rutas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'origen_lat': origenLat,
        'origen_lon': origenLon,
        'destino_lat': destinoLat,
        'destino_lon': destinoLon,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body)['rutas'] ?? [];
      // Mapeamos cada elemento del JSON a nuestro modelo estructurado
      return jsonList.map((json) => RutaModel.fromJson(json)).toList();
    }
    throw Exception('Error obteniendo rutas');
  }
}