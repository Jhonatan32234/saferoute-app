import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'session_service.dart';

@lazySingleton
class ApiClient {
  final http.Client _inner;
  final SessionService _sessionService;

  ApiClient(this._inner, this._sessionService);

  // Aumentamos el timeout global a 60 segundos por Render (Free tier)
  static const Duration _timeout = Duration(seconds: 60);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      debugPrint('🌐 [GET] $url');
      final response = await _inner.get(url, headers: _buildHeaders(headers)).timeout(_timeout);
      debugPrint('✅ [GET] ${url.path} - Status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('❌ [GET] $url - Error: $e');
      rethrow;
    }
  }

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      debugPrint('🌐 [POST] $url');
      final response = await _inner.post(url, headers: _buildHeaders(headers), body: body).timeout(_timeout);
      debugPrint('✅ [POST] ${url.path} - Status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('❌ [POST] $url - Error: $e');
      rethrow;
    }
  }

  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return _inner.put(url, headers: _buildHeaders(headers), body: body).timeout(_timeout);
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) {
    return _inner.delete(url, headers: _buildHeaders(headers), body: body).timeout(_timeout);
  }

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      ...?customHeaders,
    };

    final token = _sessionService.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
