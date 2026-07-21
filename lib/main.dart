// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadir este import
import 'package:google_fonts/google_fonts.dart';
import 'package:saferoute_app/app.dart';
import 'package:saferoute_app/core/di/injection.dart';

// ✅ Flag para controlar el bloqueo USB
const bool ENABLE_USB_BLOCKER = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
