import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/mapa_provider.dart';
import 'presentation/providers/reporte_provider.dart';
import 'presentation/providers/notificacion_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/main_screen.dart';
import 'package:http/http.dart' as http;
import 'data/datasources/api_datasources.dart';
import 'data/repositories/reporte_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const SafeRouteApp());
}

class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultApiUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Usamos el parámetro 'previous' para evitar recrear el provider 
        // y perder el estado (como la ubicación GPS) al loguearse.
        ChangeNotifierProxyProvider<AuthProvider, MapaProvider>(
          create: (_) => MapaProvider(
            api: ApiDataSource(
              baseUrl: defaultApiUrl,
              client: http.Client(),
            ),
            token: '',
          ),
          update: (_, auth, previous) {
            final provider = previous ?? MapaProvider(api: auth.api, token: auth.token ?? '');
            provider.token = auth.token ?? '';
            return provider;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ReporteProvider>(
          create: (_) => ReporteProvider(
            repository: ReporteRepositoryImpl(
              api: ApiDataSource(
                baseUrl: defaultApiUrl,
                client: http.Client(),
              ),
            ),
            token: '',
          ),
          update: (_, auth, previous) => ReporteProvider(
            repository: auth.reporteRepository, 
            token: auth.token ?? ''
          ),
        ),

        ChangeNotifierProxyProvider<AuthProvider, NotificacionProvider>(
          create: (_) => NotificacionProvider(
            baseUrl: defaultApiUrl,
            token: '',
          ),
          update: (_, auth, previous) => NotificacionProvider(
            baseUrl: auth.api.baseUrl,
            token: auth.token ?? '',
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SafeRoute',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}
