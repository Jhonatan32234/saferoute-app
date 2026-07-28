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
import '../../../notificaciones/domain/entities/notificacion_entity.dart';
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

  // Nuevas variables para alerta de administrador
  bool _showAdminAlertPill = false;
  NotificacionEntity? _currentAdminAlert;
  Timer? _adminPillTimer;

  late ReporteProvider _reporteProvider;
  late MapaProvider _mapaProvider;
  late NotificacionProvider _notiProvider;
  bool _providersInitialized = false;

  @override
  void dispose() {
    _pillTimer?.cancel();
    _adminPillTimer?.cancel();
    if (_providersInitialized) {
      _reporteProvider.removeListener(_onReporteCompletado);
      _mapaProvider.removeListener(_onLocationFix);
      _mapaProvider.removeListener(_onMapaAlertaRecibida);
      _notiProvider.removeListener(_onNuevaAlertaUrgente);
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
      _mapaProvider.addListener(_onMapaAlertaRecibida);
      _notiProvider.addListener(_onNuevaAlertaUrgente);

      _providersInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepararApp());
    }
  }

  void _onNuevaAlertaUrgente() {
    if (!mounted) return;
    final alerta = _notiProvider.ultimaAlertaUrgente;
    if (alerta != null) {
      _mostrarAlertaCritica(alerta, esDeMapa: false);
    }
  }

  void _onMapaAlertaRecibida() {
    if (!mounted) return;
    final alerta = _mapaProvider.ultimaAlertaAdmin;
    if (alerta != null) {
      debugPrint("📍 Recibida alerta admin desde MapaProvider en MainScreen");
      // ✅ Agregamos la alerta al NotiProvider para que el mapa dibuje el marcador
      _notiProvider.agregarAlertaLocal(alerta);
      _mostrarAlertaCritica(alerta, esDeMapa: true);
    }
  }

  void _mostrarAlertaCritica(NotificacionEntity alerta, {required bool esDeMapa}) {
    if (_currentAdminAlert?.id == alerta.id && _showAdminAlertPill) return;

    _triggerAdminAlertPill(alerta);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminAlertDialog(
        alerta: alerta,
        onAceptar: () {
          if (esDeMapa) {
            _mapaProvider.limpiarAlertaAdmin();
          } else {
            _notiProvider.marcarLeida(alerta.id);
            _notiProvider.limpiarAlertaUrgente();
          }
          _recenterToAlerta(alerta);
        },
      ),
    );
  }

  void _triggerAdminAlertPill(NotificacionEntity alerta) {
    _adminPillTimer?.cancel();
    setState(() {
      _currentAdminAlert = alerta;
      _showAdminAlertPill = true;
    });
    // Desaparece tras 10 segundos
    _adminPillTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showAdminAlertPill = false);
    });
  }

  void _recenterToAlerta(NotificacionEntity alerta) {
    if (alerta.longitud == 0 || alerta.latitud == 0) return;
    debugPrint("🎯 Recentering to alerta at: ${alerta.latitud}, ${alerta.longitud}");
    _mapboxController?.flyTo(
      mbm.CameraOptions(center: mbm.Point(coordinates: mbm.Position(alerta.longitud, alerta.latitud)), zoom: 16.0),
      mbm.MapAnimationOptions(duration: 1500)
    );
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
    // Sincronización de userId
    final auth = context.watch<AuthProvider>();
    final mapa = context.watch<MapaProvider>();
    
    if (auth.userId != null && auth.userId != mapa.userId) {
      Future.microtask(() => mapa.userId = auth.userId!);
    }

    final tieneRutas = mapa.rutas.isNotEmpty || mapa.mostrarSoloSeleccionada;

    if (mapa.error != null) {
      Future.microtask(() {
        if (mounted) {
          String userFriendlyError = mapa.error!;
          if (userFriendlyError.contains('host lookup') || userFriendlyError.contains('SocketException')) {
            userFriendlyError = 'Sin conexión: Revisa tu internet o el servidor está caído.';
          } else if (userFriendlyError.contains('timeout')) {
            userFriendlyError = 'El servidor está tardando mucho en responder. Inténtalo de nuevo.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyError),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'Reintentar', textColor: Colors.white, onPressed: () => mapa.limpiarError()),
            ),
          );
          mapa.limpiarError();
        }
      });
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          HomeMapView(
            puntoEnfocado: _puntoEnfocado,
            onAlertTap: (alerta) {
              showDialog(context: context, builder: (_) => AlertaDetalleDialog(alerta: alerta));
            },
            onResetEnfocado: () => setState(() => _puntoEnfocado = null),
            onControllerCreated: (controller) => _mapboxController = controller,
          ),
          const MapGradients(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Responsivo para PC
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
                          backgroundColor: theme.colorScheme.surface,
                          elevation: 4,
                          mini: true,
                          child: Icon(Icons.my_location_rounded, color: theme.colorScheme.primary),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      HomeReportPanel(onReportSent: (tipo) => _triggerSuccessPill(tipo)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ✅ Alerta de Administrador Emergente (Pill)
          if (_showAdminAlertPill && _currentAdminAlert != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 75.h,
              left: 16.w,
              right: 16.w,
              child: _AdminAlertPill(
                alerta: _currentAdminAlert!,
                onTap: () {
                  _recenterToAlerta(_currentAdminAlert!);
                  setState(() => _showAdminAlertPill = false);
                },
              ),
            ),

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

class _AdminAlertPill extends StatelessWidget {
  final NotificacionEntity alerta;
  final VoidCallback onTap;

  const _AdminAlertPill({required this.alerta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GestureDetector(
          onTap: onTap,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onError, size: 20),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ALERTA DE SEGURIDAD',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.error,
                            letterSpacing: 1.1
                          )
                        ),
                        Text(
                          alerta.mensaje,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700
                          )
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.error),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessNotificationPill extends StatelessWidget {
  final String tipo;
  const _SuccessNotificationPill({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String label = ReporteMapper.getLabelFromType(tipo);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.12), 
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                  child: Icon(Icons.check, color: theme.colorScheme.onSecondary, size: 16),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Reporte de $label enviado', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.secondary)),
                      Text('Gracias por mejorar la seguridad en la ruta', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
