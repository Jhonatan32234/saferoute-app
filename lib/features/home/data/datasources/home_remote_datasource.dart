import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/ruta_model.dart';
import '../models/destino_reciente_model.dart';

@lazySingleton
class HomeRemoteDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  HomeRemoteDataSource(this.client, this.dotenv);

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
      final decoded = jsonDecode(response.body);
      final List<dynamic> jsonList = decoded['rutas'] ?? [];
      return jsonList.map((json) => RutaModel.fromJson(json)).toList();
    }
    throw Exception('Error obteniendo rutas');
  }

  Future<String> iniciarViaje({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
    required String polylineRuta,
    required String rutaId,
    required String token,
  }) async {
    final payload = {
      'origen_lat': origenLat,
      'origen_lon': origenLon,
      'destino_lat': destinoLat,
      'destino_lon': destinoLon,
      'polyline_ruta': polylineRuta,
      'ruta_id': rutaId,
    };
    
    final response = await client.post(
      Uri.parse('$baseUrl/api/viajes/iniciar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['viaje_id'];
    }
    
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Error al iniciar el viaje');
  }

  Future<bool> finalizarViaje({
    required String viajeId,
    String? password,
    required String token,
  }) async {
    final body = {
      'viaje_id': viajeId,
    };
    if (password != null) {
      body['password'] = password;
    }

    final response = await client.post(
      Uri.parse('$baseUrl/api/viajes/finalizar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- DESTINOS RECIENTES ---

  Future<List<DestinoRecienteModel>> getDestinosRecientes(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/user/destinos?limite=10'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list = decoded['destinos'] ?? [];
      return list.map((json) => DestinoRecienteModel.fromJson(json)).toList();
    }
    throw Exception('Error cargando destinos recientes');
  }

  Future<void> guardarDestinoReciente({
    required String nombre,
    required double lat,
    required double lon,
    required String token,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/user/destinos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'lat': lat,
        'lon': lon,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error guardando destino reciente');
    }
  }

  Future<void> eliminarDestinoReciente(String id, String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/user/destinos?id=$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error eliminando destino reciente');
    }
  }
}
