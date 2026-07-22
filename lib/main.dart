// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadir este import
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:saferoute_app/app.dart';
import 'package:saferoute_app/core/di/injection.dart';

// ✅ Flag para controlar el bloqueo USB
const bool ENABLE_USB_BLOCKER = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Mapbox Token Globalmente
  mbm.MapboxOptions.setAccessToken("pk.eyJ1IjoiZGV2LXNhZmVyb3V0ZSIsImEiOiJjbXJwaW4yNHYwMTAzMnpwemZ2bTZ4MGxqIn0.mrb2nZ82lE8Tn6tMKdhWZQ");

  // ✅ Bloquear orientación a Vertical (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar fuentes necesarias
  await GoogleFonts.pendingFonts([
    GoogleFonts.plusJakartaSans(),
  ]);

  // Inicializar inyección de dependencias
  await configureDependencies();

  runApp(const SafeRouteApp(enableUsbBlocker: ENABLE_USB_BLOCKER));
}
