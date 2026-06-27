// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/mapa_provider.dart';
import 'presentation/providers/reporte_provider.dart';
import 'presentation/providers/notificacion_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/main_screen.dart';
import 'core/widgets/usb_debug_blocker.dart';
import 'core/widgets/fake_gps_blocker.dart';

// ✅ Flag para controlar el bloqueo USB
// Cambiar a false para desactivar temporalmente
const bool ENABLE_USB_BLOCKER = false;  // ← Cambia a false para desactivar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GoogleFonts.pendingFonts([
    GoogleFonts.plusJakartaSans(),
  ]);
  // Inicializar inyección de dependencias
  await configureDependencies();

  runApp(const SafeRouteApp());
}

class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthProvider>()),
        ChangeNotifierProxyProvider<AuthProvider, MapaProvider>(
          create: (_) => getIt<MapaProvider>(),
          update: (_, auth, provider) {
            provider!.token = auth.token ?? '';
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReporteProvider>(
          create: (_) => getIt<ReporteProvider>(),
          update: (_, auth, provider) {
            provider!.token = auth.token ?? '';
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificacionProvider>(
          create: (_) => getIt<NotificacionProvider>(),
          update: (_, auth, provider) {
            provider!.token = auth.token ?? '';
            return provider;
          },
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'SafeRoute',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: ENABLE_USB_BLOCKER  // ✅ Usar el flag
                ? const UsbDebugBlocker(
              child: FakeGpsBlocker(
                child: _AppRouter(),
              ),
            )
                : const FakeGpsBlocker(  // ✅ Sin bloqueo USB
              child: _AppRouter(),
            ),
          );
        },
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.inicializado) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando sesión segura...'),
            ],
          ),
        ),
      );
    }

    return auth.isLoggedIn ? const MainScreen() : const LoginPage();
  }
}