import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_exception.dart';
import 'failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is NetworkException ||
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return NetworkFailure(_cleanMessage(error));
  }
  if (error is ServerException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  if (error is CacheException) return CacheFailure(error.message);
  if (error is AuthException) return AuthFailure(error.message);
  if (error is PermissionException) return PermissionFailure(error.message);
  if (error is ValidationException) return ValidationFailure(error.message);
  if (error is FormatException) {
    return const ServerFailure(
        'El servidor devolvió datos con un formato inválido.');
  }

  final message = _cleanMessage(error);
  final normalized = message.toLowerCase();
  if (normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('connection refused') ||
      normalized.contains('timeout')) {
    return NetworkFailure(message);
  }
  return UnknownFailure(message);
}

String _cleanMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}
