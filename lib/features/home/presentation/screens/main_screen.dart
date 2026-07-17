import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../login/presentation/providers/auth_provider.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../notificaciones/presentation/widgets/notificaciones_panel_v2.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
import '../../../rutas/presentation/widgets/buscador_rutas_widget.dart';
import '../../../rutas/presentation/widgets/ruta_pill_widget.dart';
import '../providers/mapa_provider.dart';
import '../widgets/admin_alert_dialog.dart';
import '../widgets/alerta_detalle_dialog.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_map_view.dart';
import '../widgets/home_report_panel.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/map_gradients.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  LatLng? _puntoEnfocado;
  String? _ultimaRutaIdEscuchada;
  Timer? _telemetriaTimer;
  bool _providersInitialized = false;

  @override
  void dispose() {
    _telemetriaTimer?.cancel();
    _removerListeners();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providersInitialized) {
      _inicializarProviders();
      _providersInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepararApp());
    }
  }

  void _inicializarProviders() {
    final reporte = context.read<ReporteProvider>();
    final mapa = context.read<MapaProvider>();
    final noti = context.read<NotificacionProvider>();

    reporte.addListener(_onReporteCompletado);
    mapa.addListener(_onRutaChanged);
    noti.addListener(_onNotificacionActualizada);
  }

  void _removerListeners() {
    context.read<ReporteProvider>().removeListener(_onReporteCompletado);
    context.read<MapaProvider>().removeListener(_onRutaChanged);
    context.read<NotificacionProvider>().removeListener(_onNotificacionActualizada);
  }

  // --- Manejadores de Lógica ---

  void _onReporteCompletado() {
    final reporte = context.read<ReporteProvider>();
    if (reporte.ultimoResultado == 'éxito') {
      context.read<MapaProvider>().cargarClusters();
      context.read<NotificacionProvider>().cargarHistorial();
    }
  }

  void _onRutaChanged() {
    final mapa = context.read<MapaProvider>();
    final String idActual = mapa.rutaSeleccionada?.id ?? 'sin-ruta';
    if (idActual == _ultimaRutaIdEscuchada) return;
    
    _ultimaRutaIdEscuchada = idActual;
    _telemetriaTimer?.cancel();

    if (mapa.rutaSeleccionada != null) {
      _iniciarSeguimientoRuta(idActual);
    } else {
      context.read<NotificacionProvider>().desconectarRuta();
    }
  }

  void _iniciarSeguimientoRuta(String rutaId) {
    _telemetriaTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final mapa = context.read<MapaProvider>();
      context.read<NotificacionProvider>().enviarTelemetria(
        mapa.ubicacionActual.latitude,
        mapa.ubicacionActual.longitude,
        0,
        rutaId,
      );
    });

    setState(() => _puntoEnfocado = null);
    context.read<NotificacionProvider>().escucharRuta(rutaId);
  }

  void _onNotificacionActualizada() {
    if (!mounted) return;
    final noti = context.read<NotificacionProvider>();
    if (noti.ultimaAlertaUrgente != null) {
      final alerta = noti.ultimaAlertaUrgente!;
      noti.limpiarAlertaUrgente();
      _mostrarAlertaUrgente(alerta);
    }
  }

  // --- Inicialización de Sistema ---

  Future<void> _prepararApp() async {
    if (Platform.isAndroid) {
      await _pedirPermisos();
    }

    final mapa = context.read<MapaProvider>();
    await mapa.inicializarUbicacion();
    await mapa.cargarClusters();
    await context.read<NotificacionProvider>().cargarHistorial();

    if (mounted) {
      _mapController.move(mapa.ubicacionActual, 14.5);
      if (!mapa.zonaInicializada) {
        mapa.actualizarZonaUbicacion();
      }
    }
  }

  Future<void> _pedirPermisos() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error permisos: $e');
    }
  }

  // --- Navegación y Diálogos ---

  void _mostrarNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificacionesPanelV2(
        onNotificacionTap: (lat, lon) {
          final destino = LatLng(lat, lon);
          setState(() => _puntoEnfocado = destino);
          _mapController.move(destino, 14.5);
        },
      ),
    );
  }

  void _mostrarBuscadorRutas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuscadorRutasWidget(),
    );
  }

  void _mostrarAlertaUrgente(dynamic alerta) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminAlertDialog(alerta: alerta),
    );
  }

  void _mostrarDetalleAlerta(dynamic alerta) {
    showDialog(
      context: context,
      builder: (_) => AlertaDetalleDialog(alerta: alerta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final mapa = context.watch<MapaProvider>();

    final tieneRutas = mapa.rutas.isNotEmpty || mapa.mostrarSoloSeleccionada || mapa.cargandoRutas;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HomeAppBar(
        online: auth.isOnline,
        onNotificationsTap: _mostrarNotificaciones,
      ),
      body: Stack(
        children: [
          HomeMapView(
            mapController: _mapController,
            puntoEnfocado: _puntoEnfocado,
            onAlertTap: _mostrarDetalleAlerta,
            onResetEnfocado: () => setState(() => _puntoEnfocado = null),
          ),
          
          const MapGradients(),

          _SearchOverlay(
            tieneRutas: tieneRutas,
            onSearchTap: _mostrarBuscadorRutas,
          ),

          const _ReportOverlay(),
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  final bool tieneRutas;
  final VoidCallback onSearchTap;

  const _SearchOverlay({required this.tieneRutas, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10, left: 16, right: 16,
      child: Column(
        children: [
          if (!tieneRutas)
            HomeSearchBar(onTap: onSearchTap)
          else
            const RutaPillWidget(),
        ],
      ),
    );
  }
}

class _ReportOverlay extends StatelessWidget {
  const _ReportOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16, right: 16,
      child: const HomeReportPanel(),
    );
  }
}
