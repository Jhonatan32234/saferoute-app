import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart'; // <-- Nuevo import

@lazySingleton
class LoginRemoteDataSource {
  final http.Client client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  LoginRemoteDataSource(this.client, this.dotenv);

  // Ahora devuelve UserModel
  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Usamos el fromJson para convertir la respuesta a un objeto seguro
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error de autenticación');
  }
}