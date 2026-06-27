import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Imports absolutos para evitar errores de URI
import 'package:saferoute_app/core/theme/app_colors.dart';
import 'package:saferoute_app/features/reportes/presentation/providers/reporte_provider.dart';
import 'package:saferoute_app/features/reportes/presentation/widgets/report_button_widget.dart';
import 'package:saferoute_app/features/rutas/presentation/widgets/buscador_rutas_widget.dart';
import 'package:saferoute_app/features/rutas/presentation/widgets/ruta_pill_widget.dart';
import 'package:saferoute_app/features/login/presentation/providers/auth_provider.dart';
import 'package:saferoute_app/features/home/presentation/providers/mapa_provider.dart';

import '../../../../domain/entities/notificacion.dart';
import '../../../notifications/presentation/providers/notificacion_provider.dart';
import '../../../notifications/presentation/widgets/notificaciones_panel_v2.dart';

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

  @override
  void initState() {
    super.initState();
    _inicializar();
    _monitorearConectividad();
  }

  @override
  void dispose() {
    _telemetriaTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ReporteProvider>().removeListener(_onReporteCompletado);
    context.read<ReporteProvider>().addListener(_onReporteCompletado);

    context.read<MapaProvider>().removeListener(_onRutaChanged);
    context.read<MapaProvider>().addListener(_onRutaChanged);

    context.read<NotificacionProvider>().removeListener(_onNotificacionActualizada);
    context.read<NotificacionProvider>().addListener(_onNotificacionActualizada);
  }

  void _onReporteCompletado() {
    if (mounted) {
      final reporteProvider = context.read<ReporteProvider>();
      final mapaProvider = context.read<MapaProvider>();
      final notiProvider = context.read<NotificacionProvider>();

      if (reporteProvider.ultimoResultado != null) {
        if (reporteProvider.ultimoResultado == 'éxito') {
          mapaProvider.cargarClusters();
          notiProvider.cargarHistorial();
        }
      }
    }
  }

  void _onRutaChanged() {
    if (!mounted) return;
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    // SOLUCIÓN: Usar sintaxis de punto para acceder al ID de la entidad
    final String idActual = mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';

    if (idActual == _ultimaRutaIdEscuchada) return;
    _ultimaRutaIdEscuchada = idActual;

    _telemetriaTimer?.cancel();

    if (mapaProvider.rutaSeleccionada != null) {
      _telemetriaTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        notiProvider.enviarTelemetria(
          mapaProvider.ubicacionActual.latitude,
          mapaProvider.ubicacionActual.longitude,
          0,
          idActual,
        );
      });

      setState(() => _puntoEnfocado = null);

      // SOLUCIÓN: Usar sintaxis de punto para el nombre
      final String nombreRuta = mapaProvider.rutaSeleccionada!.nombre;

      final index = mapaProvider.rutas.indexOf(mapaProvider.rutaSeleccionada!);
      if (index >= 0 && index < mapaProvider.polilineas.length) {
        final List<LatLng> puntos = mapaProvider.polilineas[index];
        final List<Map<String, dynamic>> zonas = [];

        final step = puntos.length > 100 ? 20 : 10;
        for (int i = 0; i < puntos.length; i += step) {
          zonas.add({
            'zona_nombre': '${nombreRuta}_p$i',
            'latitud': puntos[i].latitude,
            'longitud': puntos[i].longitude,
            'radio_km': 10.0,
          });
        }

        if ((puntos.length - 1) % step != 0) {
          zonas.add({
            'zona_nombre': '${nombreRuta}_fin',
            'latitud': puntos.last.latitude,
            'longitud': puntos.last.longitude,
            'radio_km': 10.0,
          });
        }

        if (zonas.length > 30) {
          final zonasFiltradas = <Map<String, dynamic>>[];
          final stepFiltro = (zonas.length / 30).ceil();
          for (int i = 0; i < zonas.length; i += stepFiltro) {
            zonasFiltradas.add(zonas[i]);
          }
          if (zonasFiltradas.isNotEmpty &&
              zonasFiltradas.last['zona_nombre'] != zonas.last['zona_nombre']) {
            zonasFiltradas.add(zonas.last);
          }
          notiProvider.escucharRuta(idActual);
        } else {
          notiProvider.escucharRuta(idActual);
        }
      }
    } else {
      notiProvider.desconectarRuta();
    }
  }

  void _onNotificacionActualizada() {}

  Future<void> _inicializar() async {
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    if (Platform.isAndroid) {
      try {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Error solicitando permisos de notificación: $e');
      }
    }

    await mapaProvider.inicializarUbicacion();
    await mapaProvider.cargarClusters();
    await notiProvider.cargarHistorial();

    if (mounted) {
      _moverAPunto(mapaProvider.ubicacionActual);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inicializarZonaUbicacion();
      }
    });
  }

  void _monitorearConectividad() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() => _online = !result.contains(ConnectivityResult.none));
      }
    });
  }

  void _inicializarZonaUbicacion() {
    if (!mounted) return;
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();
    if (!mapaProvider.zonaInicializada) {
      mapaProvider.actualizarZonaUbicacion(notiProvider);
    }
  }

  void _moverAPunto(LatLng punto) {
    if (!mounted) return;
    _mapController.move(punto, 14.5);
  }

  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificacionesPanelV2(
        onNotificacionTap: (lat, lon) {
          final destino = LatLng(lat, lon);
          if (mounted) {
            setState(() => _puntoEnfocado = destino);
            _moverAPunto(destino);
          }
        },
      ),
    );
  }

  void _mostrarBuscadorRutas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuscadorRutasWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mapaProvider = context.watch<MapaProvider>();
    final reporteProvider = context.watch<ReporteProvider>();
    final notiProvider = context.watch<NotificacionProvider>();

    final tieneRutas = mapaProvider.rutas.isNotEmpty ||
        mapaProvider.mostrarSoloSeleccionada ||
        mapaProvider.cargandoRutas;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: AppColors.white.withOpacity(0.88),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4.r,
                  ),
                ],
              ),
              padding: EdgeInsets.all(2.r),
              child: Image.asset(
                'assets/saferoute_blue_nof.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shield,
                  color: AppColors.primary,
                  size: 20.r,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'SafeRoute',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.18,
                color: AppColors.slate800,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: _online ? AppColors.success : AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _mostrarNotificaciones(context),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate200),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 18.r,
                    color: AppColors.slate700,
                  ),
                  if (notiProvider.sinLeer > 0)
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5.r,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slate200),
              ),
              child: Icon(
                Icons.logout,
                size: 18.r,
                color: AppColors.slate700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapaProvider.ubicacionActual,
              initialZoom: 12,
              onTap: (_, __) {
                if (_puntoEnfocado != null) setState(() => _puntoEnfocado = null);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jmj.saferoute',
              ),
              PolylineLayer(polylines: _buildPolilineas(mapaProvider)),
              MarkerLayer(markers: _buildMarkers(mapaProvider, notiProvider)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.slate50.withOpacity(0.82),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.slate50.withOpacity(0.68),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              children: [
                if (!tieneRutas)
                  _buildSearchButton()
                else
                  const RutaPillWidget(),
              ],
            ),
          ),
          Positioned(
            bottom: 24.h,
            left: 16.w,
            right: 16.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (reporteProvider.ultimoResultado != null)
                  _buildStatusMessage(reporteProvider),
                if (reporteProvider.enviando)
                  _buildLoadingIndicator(),
                ReportButtonWidget(
                  onReporteEnviado: (tipo, notaVoz) {
                    _enviarReporte(tipo, notaVoz);
                  },
                  isLoading: reporteProvider.enviando,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () => _mostrarBuscadorRutas(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.primary,
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '¿A dónde vas?',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
            ),
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.navigation,
                color: AppColors.primary,
                size: 16.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage(ReporteProvider reporteProvider) {
    final isSuccess = reporteProvider.ultimoResultado == 'éxito';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSuccess ? AppColors.success.withOpacity(0.3) : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? AppColors.success : AppColors.danger,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isSuccess ? 'Reporte enviado' : reporteProvider.error ?? 'Error',
              style: TextStyle(
                color: isSuccess ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate800.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.r,
            height: 20.r,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Enviando reporte...',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _enviarReporte(String tipo, String notaVoz) {
    final reporteProvider = context.read<ReporteProvider>();
    final mapaProvider = context.read<MapaProvider>();

    // SOLUCIÓN: Usar sintaxis de punto
    final rutaId = mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';

    reporteProvider.enviarReporte(
      tipo: tipo,
      latitud: mapaProvider.ubicacionActual.latitude,
      longitud: mapaProvider.ubicacionActual.longitude,
      notaVoz: notaVoz,
      rutaId: rutaId,
    );
  }

  List<Polyline> _buildPolilineas(MapaProvider mapaProvider) {
    final polylines = <Polyline>[];
    if (mapaProvider.mostrarSoloSeleccionada && mapaProvider.rutaSeleccionada != null) {
      final index = mapaProvider.rutas.indexOf(mapaProvider.rutaSeleccionada!);
      if (index >= 0 && index < mapaProvider.polilineas.length) {
        polylines.add(Polyline(
          points: mapaProvider.polilineas[index],
          strokeWidth: 5,
          // SOLUCIÓN: Usar sintaxis de punto
          color: _colorRuta(mapaProvider.rutaSeleccionada!.seguridad),
        ));
      }
    } else {
      for (int i = 0; i < mapaProvider.polilineas.length; i++) {
        final r = mapaProvider.rutas[i];
        polylines.add(Polyline(
          points: mapaProvider.polilineas[i],
          strokeWidth: 4,
          // SOLUCIÓN: Usar sintaxis de punto
          color: _colorRuta(r.seguridad).withOpacity(0.8),
        ));
      }
    }
    return polylines;
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad) {
      case 'rojo':
        return AppColors.riskHigh;
      case 'naranja':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  List<Marker> _buildMarkers(MapaProvider mapaProvider, NotificacionProvider notiProvider) {
    final markers = <Marker>[];

    for (var alerta in notiProvider.alertasMapa) {
      final color = _getTipoColor(alerta.tipo);
      markers.add(Marker(
        point: LatLng(alerta.latitud, alerta.longitud),
        width: 40.r,
        height: 40.r,
        child: GestureDetector(
          onTap: () => _mostrarDetalleAlerta(alerta),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTipoIcon(alerta.tipo),
              color: color,
              size: 24.r,
            ),
          ),
        ),
      ));
    }

    if (mapaProvider.origenBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.origenBusqueda!,
        width: 40.r,
        height: 40.r,
        child: Icon(
          Icons.location_on,
          color: AppColors.success,
          size: 35.r,
        ),
      ));
    }

    if (mapaProvider.destinoBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.destinoBusqueda!,
        width: 45.r,
        height: 45.r,
        child: Icon(
          Icons.flag,
          color: AppColors.danger,
          size: 40.r,
        ),
      ));
    }

    markers.add(Marker(
      point: mapaProvider.ubicacionActual,
      width: 40.r,
      height: 40.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 24.r,
            height: 24.r,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2.r),
            ),
            child: Center(
              child: Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    ));

    if (_puntoEnfocado != null) {
      markers.add(Marker(
        point: _puntoEnfocado!,
        width: 100.r,
        height: 100.r,
        child: GestureDetector(
          onTap: () => setState(() => _puntoEnfocado = null),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'VER AQUÍ',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                color: AppColors.danger,
                size: 50.r,
              ),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident': case 'accidente': return AppColors.danger;
      case 'flood': case 'inundacion': return AppColors.primary;
      case 'pothole': case 'bache': return AppColors.warning;
      case 'blockage': case 'bloqueo': return AppColors.purple;
      case 'landslide': case 'derrumbe': return const Color(0xFFEA580C);
      case 'fog': case 'niebla': return const Color(0xFF0EA5E9);
      case 'nolight': case 'sin_luz': return const Color(0xFFEAB308);
      default: return AppColors.slate500;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident': case 'accidente': return Icons.car_crash;
      case 'flood': case 'inundacion': return Icons.water_drop;
      case 'pothole': case 'bache': return Icons.circle;
      case 'blockage': case 'bloqueo': return Icons.block;
      case 'landslide': case 'derrumbe': return Icons.landslide;
      case 'fog': case 'niebla': return Icons.foggy;
      case 'nolight': case 'sin_luz': return Icons.lightbulb_outline;
      default: return Icons.notification_important;
    }
  }

  void _mostrarDetalleAlerta(Notificacion alerta) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: _getTipoColor(alerta.tipo).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTipoIcon(alerta.tipo),
                      color: _getTipoColor(alerta.tipo),
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      alerta.tipo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta.mensaje,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    if (alerta.notaVoz.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        alerta.notaVoz,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.slate500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleCluster(Map<String, dynamic> cluster) {}
}