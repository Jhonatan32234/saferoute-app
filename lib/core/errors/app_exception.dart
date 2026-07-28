sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'No fue posible conectar con el servidor.']);
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode});
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class PermissionException extends AppException {
  const PermissionException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
