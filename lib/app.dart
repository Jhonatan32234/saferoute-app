import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:saferoute_app/core/di/injection.dart';
import 'package:saferoute_app/core/theme/app_theme.dart';
import 'package:saferoute_app/features/home/presentation/providers/mapa_provider.dart';
import 'package:saferoute_app/features/home/presentation/screens/main_screen.dart';
import 'package:saferoute_app/features/login/presentation/providers/auth_provider.dart';
import 'package:saferoute_app/features/login/presentation/screens/login_screen.dart';
import 'package:saferoute_app/features/notificaciones/presentation/providers/notificacion_provider.dart';
import 'package:saferoute_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:saferoute_app/features/reportes/presentation/providers/reporte_provider.dart';
import 'package:saferoute_app/core/widgets/usb_debug_blocker.dart';
import 'package:saferoute_app/core/widgets/fake_gps_blocker.dart';

class SafeRouteApp extends StatelessWidget {
  final bool enableUsbBlocker;

  const SafeRouteApp({
    super.key,
    required this.enableUsbBlocker,
  });

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
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => getIt<ProfileProvider>(),
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
            home: enableUsbBlocker
                ? const UsbDebugBlocker(
                    child: FakeGpsBlocker(
                      child: AppRouter(),
                    ),
                  )
                : const FakeGpsBlocker(
                    child: AppRouter(),
                  ),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

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

    return auth.isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
