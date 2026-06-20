import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiDataSource {
  final String baseUrl;
  final http.Client client;

  ApiDataSource({required this.baseUrl, required this.client});

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
        'tipo': tipo.toLowerCase(), // Aseguramos minúsculas para el backend
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
    
    // Manejo de errores sin fallar por FormatException
    if (response.body.isNotEmpty) {
      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Error del servidor (${response.statusCode})');
      } catch (_) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    }
    
    throw Exception('Error del servidor sin respuesta (${response.statusCode})');
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
