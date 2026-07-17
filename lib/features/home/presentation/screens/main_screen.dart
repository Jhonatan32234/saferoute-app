import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../notificaciones/presentation/widgets/notificaciones_panel_v2.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
import '../providers/mapa_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_map_view.dart';
import '../widgets/home_report_panel.dart';
import '../widgets/home_search_bar.dart';
import '../../../rutas/presentation/widgets/buscador_rutas_widget.dart';
import '../../../rutas/presentation/widgets/ruta_pill_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  bool _online = true;
  LatLng? _puntoEnfocado;
  String? _ultimaRutaIdEscuchada;
  Timer? _telemetriaTimer;
  
  late ReporteProvider _reporteProvider;
  late MapaProvider _mapaProvider;
  late NotificacionProvider _notiProvider;
  bool _providersInitialized = false;

  @override
  void initState() {
    super.initState();
    _monitorearConectividad();
  }

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
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
      _mostrarAlertaAdminUrgente(alerta);
    }
  }

  Future<void> _inicializar() async {
    if (Platform.isAndroid) {
      await _solicitarPermisosNotificaciones();
    }

    await _mapaProvider.inicializarUbicacion();
    await _mapaProvider.cargarClusters();
    await _notiProvider.cargarHistorial();

    if (mounted) {
      _moverAPunto(_mapaProvider.ubicacionActual);
      if (!_mapaProvider.zonaInicializada) {
        _mapaProvider.actualizarZonaUbicacion();
      }
    }
  }

  Future<void> _solicitarPermisosNotificaciones() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error permisos notif: $e');
    }
  }

  void _monitorearConectividad() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() => _online = !result.contains(ConnectivityResult.none));
      }
    });
  }

  void _moverAPunto(LatLng punto) {
    _mapController.move(punto, 14.5);
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
          _moverAPunto(destino);
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

  void _mostrarAlertaAdminUrgente(NotificacionEntity alerta) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdminAlert(alerta: alerta),
    );
  }

  void _mostrarDetalleAlerta(NotificacionEntity alerta) {
    showDialog(
      context: context,
      builder: (_) => _AlertaDetalleDialog(alerta: alerta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapaProvider = context.watch<MapaProvider>();
    final tieneRutas = mapaProvider.rutas.isNotEmpty ||
        mapaProvider.mostrarSoloSeleccionada ||
        mapaProvider.cargandoRutas;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HomeAppBar(
        online: _online,
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
          
          const _MapGradients(),

          Positioned(
            top: 10.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              children: [
                if (!tieneRutas)
                  HomeSearchBar(onTap: _mostrarBuscadorRutas)
                else
                  const RutaPillWidget(),
              ],
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16.h,
            left: 16.w,
            right: 16.w,
            child: const HomeReportPanel(),
          ),
        ],
      ),
    );
  }
}

class _MapGradients extends StatelessWidget {
  const _MapGradients();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0, height: 140.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor.withOpacity(0.82), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, height: 140.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bgColor.withOpacity(0.68), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminAlert extends StatelessWidget {
  final NotificacionEntity alerta;
  const _AdminAlert({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.primary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: theme.colorScheme.onPrimary, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'INSTRUCCIÓN DE CONTROL', 
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alerta.mensaje, 
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onPrimary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instrucción directa del administrador.', 
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: theme.colorScheme.onPrimary, 
            foregroundColor: theme.colorScheme.primary,
          ),
          child: const Text('ENTENDIDO'),
        ),
      ],
    );
  }
}

class _AlertaDetalleDialog extends StatelessWidget {
  final NotificacionEntity alerta;
  const _AlertaDetalleDialog({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alerta.tipo.toUpperCase(), 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16.h),
            Text(alerta.mensaje, style: theme.textTheme.bodyMedium),
            if (alerta.notaVoz.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                alerta.notaVoz, 
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
