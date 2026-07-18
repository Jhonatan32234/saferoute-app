import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'session_service.dart';

@lazySingleton
class ApiClient {
  final http.Client _inner;
  final SessionService _sessionService;

  ApiClient(this._inner, this._sessionService);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _inner.get(url, headers: _buildHeaders(headers));
  }

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _inner.post(url, headers: _buildHeaders(headers), body: body);
  }

  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return _inner.put(url, headers: _buildHeaders(headers), body: body);
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) {
    return _inner.delete(url, headers: _buildHeaders(headers), body: body);
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
