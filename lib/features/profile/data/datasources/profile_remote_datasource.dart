import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

@lazySingleton
class ProfileRemoteDataSource {
  final ApiClient client;
  final DotEnv dotenv;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  ProfileRemoteDataSource(this.client, this.dotenv);

  Future<ProfileModel> getProfile() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/user/profile'),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Error al obtener el perfil');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/user/profile'),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al actualizar el perfil');
    }
  }
}
