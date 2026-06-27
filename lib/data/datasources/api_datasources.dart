import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@lazySingleton
class ApiDataSource {
  final http.Client client;
  final DotEnv dotenv;

  ApiDataSource(this.client, this.dotenv);

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';
}
