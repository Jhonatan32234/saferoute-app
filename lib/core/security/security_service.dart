import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SecurityService {
  static const _channel = MethodChannel('com.jmj.saferoute/security');

  Future<void> setSecureMode(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureMode', enabled);
    } catch (e) {
      // Ignorar errores si la plataforma no lo soporta
    }
  }
}
