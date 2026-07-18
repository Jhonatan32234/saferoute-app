import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  LatLng? _puntoEnfocado;
  String? _ultimaRutaIdEscuchada;
  Timer? _telemetriaTimer;
  mbm.MapboxMap? _mapboxController;
  
  late ReporteProvider _reporteProvider;
  late MapaProvider _mapaProvider;
  late NotificacionProvider _notiProvider;
  bool _providersInitialized = false;

  @override
  void dispose() {
    _telemetriaTimer?.cancel();
    if (_providersInitialized) {
      _reporteProvider.removeListener(_onReporteCompletado);
      _mapaProvider.removeListener(_onRutaChanged);
      _notiProvider.removeListener(_onNotificacionActualizada);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providersInitialized) {
      _reporteProvider = context.read<ReporteProvider>();
      _mapaProvider = context.read<MapaProvider>();
      _notiProvider = context.read<NotificacionProvider>();

      _reporteProvider.addListener(_onReporteCompletado);
      _mapaProvider.addListener(_onRutaChanged);
      _notiProvider.addListener(_onNotificacionActualizada);

      _providersInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepararApp());
    }
  }

  void _onReporteCompletado() {
    if (!mounted) return;
    if (_reporteProvider.ultimoResultado == 'éxito') {
      _mapaProvider.cargarClusters();
      _notiProvider.cargarHistorial();
    }
  }

  void _onRutaChanged() {
    if (!mounted) return;
    final String idActual = _mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';
    if (idActual == _ultimaRutaIdEscuchada) return;
    
    _ultimaRutaIdEscuchada = idActual;
    _telemetriaTimer?.cancel();

    if (_mapaProvider.rutaSeleccionada != null) {
      _iniciarSeguimientoRuta(idActual);
    } else {
      _notiProvider.desconectarRuta();
    }
  }

  void _iniciarSeguimientoRuta(String rutaId) {
    _telemetriaTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _notiProvider.enviarTelemetria(
        _mapaProvider.ubicacionActual.latitude,
        _mapaProvider.ubicacionActual.longitude,
        0,
        rutaId,
      );
    });

    setState(() => _puntoEnfocado = null);
    _notiProvider.escucharRuta(rutaId);
  }

  void _onNotificacionActualizada() {
    if (!mounted) return;
    if (_notiProvider.ultimaAlertaUrgente != null) {
      final alerta = _notiProvider.ultimaAlertaUrgente!;
      _notiProvider.limpiarAlertaUrgente();
      _mostrarAlertaUrgente(alerta);
    }
  }

  Future<void> _prepararApp() async {
    if (Platform.isAndroid) {
      await _pedirPermisos();
    }

    await _mapaProvider.inicializarUbicacion();
    await _mapaProvider.cargarClusters();
    await _notiProvider.cargarHistorial();

    if (mounted && !_mapaProvider.zonaInicializada) {
      _mapaProvider.actualizarZonaUbicacion();
    }
    
    // Forzar re-centrado inicial una vez que tenemos la ubicación
    if (mounted && _mapboxController != null) {
      _recenter();
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

  void _mostrarNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificacionesPanelV2(
        onNotificacionTap: (lat, lon) {
          final destino = LatLng(lat, lon);
          setState(() => _puntoEnfocado = destino);
          _mapboxController?.flyTo(
            mbm.CameraOptions(center: mbm.Point(coordinates: mbm.Position(lon, lat)), zoom: 15.5),
            mbm.MapAnimationOptions(duration: 1000)
          );
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

  void _recenter() {
    if (_mapboxController == null) return;
    _mapboxController?.flyTo(
      mbm.CameraOptions(
        center: mbm.Point(
          coordinates: mbm.Position(
            _mapaProvider.ubicacionActual.longitude,
            _mapaProvider.ubicacionActual.latitude,
          ),
        ),
        zoom: 15.5,
      ),
      mbm.MapAnimationOptions(duration: 1200),
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
      extendBody: true,
      appBar: HomeAppBar(
        online: auth.isOnline,
        onNotificationsTap: _mostrarNotificaciones,
      ),
      body: Stack(
        children: [
          HomeMapView(
            puntoEnfocado: _puntoEnfocado,
            onAlertTap: _mostrarDetalleAlerta,
            onResetEnfocado: () => setState(() => _puntoEnfocado = null),
            onControllerCreated: (controller) {
              setState(() {
                _mapboxController = controller;
              });
              // Recenter tan pronto como el controlador esté listo
              _recenter();
            },
          ),
          
          const MapGradients(),

          _OverlayManager(
            tieneRutas: tieneRutas,
            onSearchTap: _mostrarBuscadorRutas,
            onRecenterTap: _recenter,
          ),
        ],
      ),
    );
  }
}

class _OverlayManager extends StatelessWidget {
  final bool tieneRutas;
  final VoidCallback onSearchTap;
  final VoidCallback onRecenterTap;

  const _OverlayManager({
    required this.tieneRutas, 
    required this.onSearchTap,
    required this.onRecenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned.fill(
      child: SafeArea(
        bottom: false, // Manejamos el bottom manualmente para evitar choques con nav bar
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, bottomPadding + 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Parte Superior: Info de Ruta
              if (tieneRutas) const RutaPillWidget(),

              const Spacer(),

              // Botones Flotantes Laterales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Lado Izquierdo: Buscar
                  if (!tieneRutas)
                    HomeSearchBar(onTap: onSearchTap)
                  else
                    const SizedBox.shrink(),

                  // Lado Derecho: Recenter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        onPressed: onRecenterTap,
                        backgroundColor: Colors.white,
                        elevation: 4,
                        mini: true,
                        child: const Icon(Icons.my_location_rounded, color: Colors.blue, size: 20),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ],
              ),

              // Parte Inferior: Panel de Reportes
              const HomeReportPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
