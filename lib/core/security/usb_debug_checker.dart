import 'dart:async';
import 'package:flutter/services.dart';

class UsbDebugChecker {
  // Canales sincronizados con MainActivity.kt
  static const _usbChannel = MethodChannel('com.jmj.saferoute/usb_debug');
  static const _seguridadChannel = MethodChannel('com.jmj.saferoute/seguridad');

  /// Verifica si la depuración USB está activada
  static Future<bool> isUsbDebugEnabled() async {
    try {
      // El método en Kotlin es 'checkUSBDebugging'
      final bool? result = await _usbChannel.invokeMethod<bool>('checkUSBDebugging');
      return result ?? true; // Si es nulo, por seguridad asumimos activado
    } catch (e) {
      // Enfoque RASP: Si falla la comunicación, bloqueamos por seguridad
      return true;
    }
  }

  /// Abre los ajustes de desarrollador
  static Future<void> openDeveloperSettings() async {
    try {
      await _seguridadChannel.invokeMethod('openDeveloperSettings');
    } catch (e) {
      // No se pudo abrir
    }
  }
  
  /// Permite escuchar actualizaciones en tiempo real enviadas desde el onResume de Android
  static void setUpdateHandler(Function(bool) onUpdate) {
    _usbChannel.setMethodCallHandler((call) async {
      if (call.method == 'onUpdateDebugStatus') {
        onUpdate(call.arguments as bool);
      }
    });
  }
}
