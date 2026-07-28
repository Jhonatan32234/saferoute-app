import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class SSLPinningValidation {
  static Future<void> check() async {
    return;
    final String? fingerprint = dotenv.maybeGet('API_SHA256');
    final String? domain = dotenv.maybeGet('API_DOMAIN');

    if (fingerprint == null || domain == null) {
      log("⚠️ SSL Pinning: Saltando validación (API_SHA256 o API_DOMAIN no configurados)");
      return;
    }

    try {
      await HttpCertificatePinning.check(
        serverURL: 'https://$domain',
        sha: SHA.SHA256,
        allowedSHAFingerprints: [fingerprint.replaceAll(':', ' ')],
        timeout: 15,
      );
      log("✅ SSL Pinning: Conexión segura con $domain");
    } catch (e) {
      log("❌ SSL Pinning: ¡ALERTA DE SEGURIDAD! La conexión no es confiable. Error: $e");
      throw Exception("SSL_PINNING_ERROR");
    }
  }
}
