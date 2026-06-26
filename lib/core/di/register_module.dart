// lib/core/di/register_module.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  http.Client get httpClient => http.Client();

  @lazySingleton
  FlutterSecureStorage get storage => const FlutterSecureStorage();

  @preResolve
  Future<DotEnv> get dotenvInstance async {
    await dotenv.load(fileName: ".env");
    return dotenv;
  }
}