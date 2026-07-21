import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:saferoute_app/core/utils/reporte_mapper.dart';
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
  
  bool _showSuccessPill = false;
  String _lastReportType = '';
  Timer? _pillTimer;

  late ReporteProvider _reporteProvider;
  late MapaProvider _mapaProvider;
  late NotificacionProvider _notiProvider;
  bool _providersInitialized = false;

  @override
  void dispose() {
    _pillTimer?.cancel();
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
    if (!_initialFixDone && (_mapaProvider.ubicacionActual.latitude != 16.753)) {
      _initialFixDone = true;
      _recenter();
    }
  }

  void _onReporteCompletado() {
    if (!mounted) return;
    if (_reporteProvider.ultimoResultado == 'éxito') {
      _triggerSuccessPill(_lastReportType);
    }
  }

  void _triggerSuccessPill(String tipo) {
    _pillTimer?.cancel();
    setState(() {
      _showSuccessPill = true;
      _lastReportType = tipo;
    });
    _pillTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSuccessPill = false);
    });
  }

  Future<void> _prepararApp() async {
    await Future.wait([
      _mapaProvider.inicializarUbicacion(),
      _notiProvider.cargarHistorial(),
    ]);
  }

  void _mostrarNotificaciones() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Alertas',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: NotificacionesPanelV2(
            onNotificacionTap: (lat, lon) {
              _mapboxController?.flyTo(
                mbm.CameraOptions(center: mbm.Point(coordinates: mbm.Position(lon, lat)), zoom: 15.5),
                mbm.MapAnimationOptions(duration: 1000)
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
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
    final mapa = context.watch<MapaProvider>();
    final tieneRutas = mapa.rutas.isNotEmpty || mapa.mostrarSoloSeleccionada;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Capa Base: Mapa
          HomeMapView(
            puntoEnfocado: _puntoEnfocado,
            onAlertTap: (alerta) {
              showDialog(context: context, builder: (_) => AlertaDetalleDialog(alerta: alerta));
            },
            onResetEnfocado: () => setState(() => _puntoEnfocado = null),
            onControllerCreated: (controller) => _mapboxController = controller,
          ),

          const MapGradients(),

          // 2. Capa Intermedia: Interfaz Principal
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
                  HomeReportPanel(onReportSent: (tipo) => _triggerSuccessPill(tipo)),
                ],
              ),
            ),
          ),

          // 3. CAPA FRONTAL: NOTIFICACIÓN DE ÉXITO (FIGMA)
          if (_showSuccessPill)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16.w,
              right: 16.w,
              child: _SuccessNotificationPill(tipo: _lastReportType),
            ),
        ],
      ),
    );
  }
}

class _SuccessNotificationPill extends StatelessWidget {
  final String tipo;
  const _SuccessNotificationPill({required this.tipo});

  @override
  Widget build(BuildContext context) {
    // Usar el mapper para asegurar el nombre en español
    final String label = ReporteMapper.getLabelFromType(tipo);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12), 
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reporte de $label enviado', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A))),
                  Text('Gracias por mejorar la seguridad en la ruta', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF15803D), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
