import 'dart:async';
import 'package:flutter/services.dart';

class FakeGpsChecker {
  static const _channel = MethodChannel('com.jmj.saferoute/gps');

  /// Verifica si se está utilizando una ubicación simulada (Fake GPS)
  /// Retorna "CLEAN" si es seguro, o un mensaje descriptivo si se detecta fraude.
  static Future<String> checkFakeGps() async {
    try {
      final String? result = await _channel.invokeMethod<String>('checkFakeGPS');
      return result ?? "Error en verificación";
    } catch (e) {
      // Enfoque RASP: Si falla la comunicación, asumimos riesgo por seguridad
      return "Fallo en el sistema de verificación de ubicación";
    }
  }
}
