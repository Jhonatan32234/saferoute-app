// lib/data/datasources/api_datasources.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@lazySingleton
class ApiDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  ApiDataSource(this.client, this.dotenv);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error de autenticación');
  }

  Future<List<dynamic>> getRutas({
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
      return jsonDecode(response.body)['rutas'] ?? [];
    }
    throw Exception('Error obteniendo rutas');
  }

  Future<Map<String, dynamic>> crearReporte({
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
      if (response.body.isEmpty) return {'status': 'ok'};
      return jsonDecode(response.body);
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

  Future<Map<String, dynamic>> getResumen({required String token}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/resumen'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error obteniendo resumen');
  }
}