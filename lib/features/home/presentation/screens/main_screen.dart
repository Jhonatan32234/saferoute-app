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
  mbm.MapboxMap? _mapboxController;
  bool _initialFixDone = false;
  
  late ReporteProvider _reporteProvider;
  late MapaProvider _mapaProvider;
  late NotificacionProvider _notiProvider;
  bool _providersInitialized = false;

  @override
  void dispose() {
    if (_providersInitialized) {
      _reporteProvider.removeListener(_onReporteCompletado);
      _mapaProvider.removeListener(_onLocationFix);
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
      _mapaProvider.addListener(_onLocationFix);

      _providersInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepararApp());
    }
  }

  void _onLocationFix() {
    // Si la ubicación cambia respecto al valor por defecto (Tuxtla center), centrar una sola vez
    if (!_initialFixDone && (_mapaProvider.ubicacionActual.latitude != 16.753)) {
      _initialFixDone = true;
      _recenter();
    }
  }

  void _onReporteCompletado() {
    if (!mounted) return;
    if (_reporteProvider.ultimoResultado == 'éxito') {
      _mapaProvider.cargarClusters();
      _notiProvider.cargarHistorial();
    }
  }

  Future<void> _prepararApp() async {
    await Future.wait([
      _mapaProvider.inicializarUbicacion(),
      _notiProvider.cargarHistorial(),
    ]);
  }

  void _mostrarNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificacionesPanelV2(
        onNotificacionTap: (lat, lon) {
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
      mbm.MapAnimationOptions(duration: 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapa = context.watch<MapaProvider>();
    final tieneRutas = mapa.rutas.isNotEmpty || mapa.mostrarSoloSeleccionada;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          HomeMapView(
            puntoEnfocado: _puntoEnfocado,
            onAlertTap: (alerta) {
              showDialog(context: context, builder: (_) => AlertaDetalleDialog(alerta: alerta));
            },
            onResetEnfocado: () => setState(() => _puntoEnfocado = null),
            onControllerCreated: (controller) {
              setState(() => _mapboxController = controller);
              _recenter();
            },
          ),

          const MapGradients(),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                children: [
                  HomeAppBar(onNotificationsTap: _mostrarNotificaciones),
                  
                  SizedBox(height: 20.h),

                  if (!tieneRutas)
                    HomeSearchBar(onTap: _mostrarBuscadorRutas)
                  else
                    const RutaPillWidget(),

                  const Spacer(),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: _recenter,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      mini: true,
                      child: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),

                  const HomeReportPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
