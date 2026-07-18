import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:provider/provider.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';
import '../providers/mapa_provider.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';

class HomeMapView extends StatefulWidget {
  final dynamic puntoEnfocado;
  final Function(NotificacionEntity) onAlertTap;
  final VoidCallback onResetEnfocado;
  final Function(mbm.MapboxMap)? onControllerCreated;

  const HomeMapView({
    super.key,
    this.puntoEnfocado,
    required this.onAlertTap,
    required this.onResetEnfocado,
    this.onControllerCreated,
  });

  @override
  State<HomeMapView> createState() => HomeMapViewState();
}

class HomeMapViewState extends State<HomeMapView> with SingleTickerProviderStateMixin {
  mbm.MapboxMap? _mapboxMap;
  mbm.CircleAnnotationManager? _circleAnnotationManager;
  mbm.PolylineAnnotationManager? _polylineAnnotationManager;

  final String _styleUrl = "mapbox://styles/dev-saferoute/cmrpjagea00bt01qta2r53wkl";
  
  final Map<String, NotificacionEntity> _idToAlerta = {};
  String? _lastRutaId;
  int _lastMarkersCount = 0;

  late AnimationController _routeAnimationController;
  double _lastAnimValue = 0.0;

  @override
  void initState() {
    super.initState();
    mbm.MapboxOptions.setAccessToken("pk.eyJ1IjoiZGV2LXNhZmVyb3V0ZSIsImEiOiJjbXJwaW4yNHYwMTAzMnpwemZ2bTZ4MGxqIn0.mrb2nZ82lE8Tn6tMKdhWZQ");
    
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        // Optimización: Solo redibujar si el progreso cambió significativamente (evita el lag)
        if ((_routeAnimationController.value - _lastAnimValue).abs() > 0.05) {
          _lastAnimValue = _routeAnimationController.value;
          _dibujarRutaActual();
        }
      });
  }

  @override
  void dispose() {
    _routeAnimationController.dispose();
    super.dispose();
  }

  void _onMapCreated(mbm.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(mapboxMap);
    }
    
    _mapboxMap?.scaleBar.updateSettings(mbm.ScaleBarSettings(enabled: false));
    _mapboxMap?.location.updateSettings(mbm.LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));

    _circleAnnotationManager = await _mapboxMap?.annotations.createCircleAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();

    _circleAnnotationManager?.addOnCircleAnnotationClickListener(
      _OnCircleClickListener(onTap: (id) => _manejarClicMarcador(id)),
    );

    _actualizarMapa(forzar: true);
  }

  void _manejarClicMarcador(String id) {
    final alerta = _idToAlerta[id];
    if (alerta != null) {
      widget.onAlertTap(alerta);
    }
  }

  void _actualizarMapa({bool forzar = false}) {
    if (_mapboxMap == null) return;
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    _verificarRuta(mapaProvider, forzar);
    _dibujarMarcadores(mapaProvider, notiProvider);
  }

  void _verificarRuta(MapaProvider provider, bool forzar) {
    final currentId = provider.rutaSeleccionada?.id ?? "list-${provider.rutas.length}";
    if (currentId != _lastRutaId || forzar) {
      _lastRutaId = currentId;
      if (provider.polilineas.isNotEmpty) {
        _routeAnimationController.reset();
        _routeAnimationController.forward();
        _ajustarCamaraARuta(provider);
      } else {
        _polylineAnnotationManager?.deleteAll();
      }
    }
  }

  void _ajustarCamaraARuta(MapaProvider provider) async {
    if (provider.polilineas.isEmpty) return;
    final allPoints = provider.polilineas.expand((i) => i).toList();
    final lineString = mbm.LineString(coordinates: allPoints.map((p) => mbm.Position(p.longitude, p.latitude)).toList());
    
    final camera = await _mapboxMap?.cameraForGeometry(
      lineString.toJson(), 
      mbm.MbxEdgeInsets(top: 100, left: 60, bottom: 350, right: 60), 
      null, null
    );

    if (camera != null) {
      _mapboxMap?.flyTo(camera, mbm.MapAnimationOptions(duration: 1200));
    }
  }

  void _dibujarRutaActual() async {
    final provider = context.read<MapaProvider>();
    if (_polylineAnnotationManager == null || provider.polilineas.isEmpty) return;

    await _polylineAnnotationManager?.deleteAll();

    for (int i = 0; i < provider.polilineas.length; i++) {
      final fullPoints = provider.polilineas[i];
      final isSelected = provider.rutaSeleccionada != null && provider.rutas[i] == provider.rutaSeleccionada;
      
      int visibleCount = (fullPoints.length * _routeAnimationController.value).floor();
      if (visibleCount < 2) visibleCount = 2;
      final points = fullPoints.take(visibleCount).toList();

      _polylineAnnotationManager?.create(
        mbm.PolylineAnnotationOptions(
          geometry: mbm.LineString(coordinates: points.map((p) => mbm.Position(p.longitude, p.latitude)).toList()),
          lineColor: _colorRuta(provider.rutas[i].seguridad).value,
          lineWidth: isSelected ? 7.0 : 3.0,
          lineOpacity: isSelected ? 1.0 : 0.3,
          lineJoin: mbm.LineJoin.ROUND,
        ),
      );
    }
  }

  void _dibujarMarcadores(MapaProvider mapa, NotificacionProvider noti) async {
    if (_circleAnnotationManager == null) return;
    
    final totalMarkers = noti.alertasMapa.length + (mapa.origenBusqueda != null ? 1 : 0) + (mapa.destinoBusqueda != null ? 1 : 0);
    if (totalMarkers == _lastMarkersCount) return;
    _lastMarkersCount = totalMarkers;

    await _circleAnnotationManager?.deleteAll();
    _idToAlerta.clear();

    for (var alerta in noti.alertasMapa) {
      final color = _getTipoColor(alerta.tipo);
      final annotation = await _circleAnnotationManager?.create(
        mbm.CircleAnnotationOptions(
          geometry: mbm.Point(coordinates: mbm.Position(alerta.longitud, alerta.latitud)),
          circleRadius: 15.0,
          circleColor: color.value,
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.value,
        ),
      );
      if (annotation != null) _idToAlerta[annotation.id] = alerta;
    }

    if (mapa.origenBusqueda != null) {
      _circleAnnotationManager?.create(mbm.CircleAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.origenBusqueda!.longitude, mapa.origenBusqueda!.latitude)),
        circleRadius: 8.0, circleColor: Colors.green.value, circleStrokeWidth: 2.0, circleStrokeColor: Colors.white.value,
      ));
    }
    if (mapa.destinoBusqueda != null) {
      _circleAnnotationManager?.create(mbm.CircleAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.destinoBusqueda!.longitude, mapa.destinoBusqueda!.latitude)),
        circleRadius: 10.0, circleColor: Colors.red.value, circleStrokeWidth: 2.5, circleStrokeColor: Colors.white.value,
      ));
    }
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad.toLowerCase()) {
      case 'rojo': case 'alto': return AppColors.riskHigh;
      case 'naranja': case 'medio': return AppColors.riskMedium;
      default: return AppColors.primary;
    }
  }

  Color _getTipoColor(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('accident')) return AppColors.danger;
    if (t.contains('inundacion') || t.contains('flood')) return AppColors.primary;
    if (t.contains('bache') || t.contains('pothole')) return AppColors.warning;
    return AppColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();
    if (_mapboxMap != null) {
      Future.microtask(() => _actualizarMapa());
    }
    return mbm.MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: _styleUrl,
      onMapCreated: _onMapCreated,
      cameraOptions: mbm.CameraOptions(
        center: mbm.Point(coordinates: mbm.Position(mapaProvider.ubicacionActual.longitude, mapaProvider.ubicacionActual.latitude)),
        zoom: 14.5,
      ),
    );
  }
}

class _OnCircleClickListener extends mbm.OnCircleAnnotationClickListener {
  final Function(String) onTap;
  _OnCircleClickListener({required this.onTap});
  @override
  void onCircleAnnotationClick(mbm.CircleAnnotation annotation) {
    onTap(annotation.id);
  }
}
