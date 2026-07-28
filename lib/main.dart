// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:saferoute_app/app.dart';
import 'package:saferoute_app/core/di/injection.dart';
import 'package:saferoute_app/core/utils/notification_helper.dart';
import 'package:device_preview/device_preview.dart';

// ✅ Flag para controlar el bloqueo USB
const bool ENABLE_USB_BLOCKER = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Mapbox Token Globalmente
  mbm.MapboxOptions.setAccessToken("pk.eyJ1IjoiZGV2LXNhZmVyb3V0ZSIsImEiOiJjbXJwaW4yNHYwMTAzMnpwemZ2bTZ4MGxqIn0.mrb2nZ82lE8Tn6tMKdhWZQ");

  // Removido bloqueo de orientación para soportar responsividad (PC/Tablet)

  // Cargar fuentes necesarias
  await GoogleFonts.pendingFonts([
    GoogleFonts.plusJakartaSans(),
  ]);

  // Inicializar inyección de dependencias
  await configureDependencies();
  
  // ✅ Inicializar Ayudante de Notificaciones
  await NotificationHelper.inicializar();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kIsWeb,
      builder: (context) => const SafeRouteApp(enableUsbBlocker: ENABLE_USB_BLOCKER),
    ),
  );
}
