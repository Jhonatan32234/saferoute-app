import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

@lazySingleton
class LoginRemoteDataSource {
  final ApiClient client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  LoginRemoteDataSource(this.client, this.dotenv);

  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Usamos el fromJson para convertir la respuesta a un objeto seguro
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error de autenticación');
  }
}