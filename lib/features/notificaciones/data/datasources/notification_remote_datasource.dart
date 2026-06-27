import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/notificacion_model.dart';

@lazySingleton
class NotificacionRemoteDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  NotificacionRemoteDataSource(this.client, this.dotenv);

  Future<List<NotificacionModel>> getHistorial(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/user/notificaciones?limite=50'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body)['notificaciones'] ?? [];
      return list.map((json) => NotificacionModel.fromJson(json)).toList();
    }
    throw Exception('Error cargando historial');
  }

  Future<void> marcarLeida(String token, String id) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/user/notificaciones/marcar?id=$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'leida': true}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error marcando notificación como leída');
    }
  }

  Future<void> marcarTodasLeidas(String token) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/user/notificaciones/marcar-todas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error marcando todas las notificaciones como leídas');
    }
  }
}