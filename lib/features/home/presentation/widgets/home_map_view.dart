import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> with SingleTickerProviderStateMixin {
  mbm.MapboxMap? _mapboxMap;
  mbm.PointAnnotationManager? _pointAnnotationManager;
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
        if ((_routeAnimationController.value - _lastAnimValue).abs() > 0.1) {
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
      showAccuracyRing: true,
    ));

    // Registro de iconos personalizados
    await _registrarIconos();

    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();

    _pointAnnotationManager?.addOnPointAnnotationClickListener(
      _OnPointClickListener(onTap: (id) => _manejarClicMarcador(id)),
    );

    if (mounted) {
      _actualizarMapa(forzar: true);
    }
  }

  Future<void> _registrarIconos() async {
    final iconos = [
      {'id': 'accident', 'icon': Icons.car_crash, 'color': AppColors.danger},
      {'id': 'flood', 'icon': Icons.water_drop, 'color': AppColors.primary},
      {'id': 'pothole', 'icon': Icons.circle, 'color': AppColors.warning},
      {'id': 'blockage', 'icon': Icons.block, 'color': AppColors.purple},
      {'id': 'landslide', 'icon': Icons.landslide, 'color': const Color(0xFFEA580C)},
      {'id': 'fog', 'icon': Icons.foggy, 'color': const Color(0xFF0EA5E9)},
      {'id': 'nolight', 'icon': Icons.lightbulb_outline, 'color': const Color(0xFFEAB308)},
    ];

    for (var item in iconos) {
      final bytes = await _generarImagenDeIcono(item['icon'] as IconData, item['color'] as Color);
      await _mapboxMap?.style.addStyleImage(
        item['id'] as String,
        1.0,
        mbm.MbxImage(width: 100, height: 100, data: bytes),
        false, [], [], null
      );
    }
  }

  Future<Uint8List> _generarImagenDeIcono(IconData icon, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0;
    
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    
    final borderPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 3, borderPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontSize: 60.0, fontFamily: icon.fontFamily, color: color, package: icon.fontPackage),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _manejarClicMarcador(String id) {
    final alerta = _idToAlerta[id];
    if (alerta != null) widget.onAlertTap(alerta);
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
      }
    }
  }

  void _ajustarCamaraARuta(MapaProvider provider) async {
    if (provider.polilineas.isEmpty) return;
    final allPoints = provider.polilineas.expand((i) => i).toList();
    final lineString = mbm.LineString(coordinates: allPoints.map((p) => mbm.Position(p.longitude, p.latitude)).toList());
    
    final camera = await _mapboxMap?.cameraForGeometry(
      lineString.toJson(), 
      mbm.MbxEdgeInsets(top: 100.0, left: 60.0, bottom: 350.0, right: 60.0), 
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
          lineWidth: isSelected ? 8.0 : 4.0,
          lineOpacity: isSelected ? 1.0 : 0.4,
          lineJoin: mbm.LineJoin.ROUND,
        ),
      );
    }
  }

  void _dibujarMarcadores(MapaProvider mapa, NotificacionProvider noti) async {
    if (_pointAnnotationManager == null) return;
    
    final totalMarkers = noti.alertasMapa.length + (mapa.origenBusqueda != null ? 1 : 0) + (mapa.destinoBusqueda != null ? 1 : 0);
    if (totalMarkers == _lastMarkersCount) return;
    _lastMarkersCount = totalMarkers;

    await _pointAnnotationManager?.deleteAll();
    _idToAlerta.clear();

    for (var alerta in noti.alertasMapa) {
      final tipoId = _getTipoKey(alerta.tipo);
      final annotation = await _pointAnnotationManager?.create(
        mbm.PointAnnotationOptions(
          geometry: mbm.Point(coordinates: mbm.Position(alerta.longitud, alerta.latitud)),
          iconImage: tipoId,
          iconSize: 0.5,
        ),
      );
      if (annotation != null) _idToAlerta[annotation.id] = alerta;
    }

    if (mapa.origenBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.origenBusqueda!.longitude, mapa.origenBusqueda!.latitude)),
        iconImage: "marker-15",
        iconColor: Colors.green.value,
      ));
    }
    if (mapa.destinoBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.destinoBusqueda!.longitude, mapa.destinoBusqueda!.latitude)),
        iconImage: "rocket-15",
        iconColor: Colors.red.value,
      ));
    }
  }

  String _getTipoKey(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('accident')) return 'accident';
    if (t.contains('inundacion') || t.contains('flood')) return 'flood';
    if (t.contains('bache') || t.contains('pothole')) return 'pothole';
    if (t.contains('bloqueo') || t.contains('blockage')) return 'blockage';
    if (t.contains('derrumbe') || t.contains('landslide')) return 'landslide';
    if (t.contains('niebla') || t.contains('fog')) return 'fog';
    if (t.contains('luz') || t.contains('nolight')) return 'nolight';
    return 'pothole';
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad.toLowerCase()) {
      case 'rojo': case 'alto': return AppColors.riskHigh;
      case 'naranja': case 'medio': return AppColors.riskMedium;
      default: return AppColors.primary;
    }
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
        zoom: 15.0,
      ),
    );
  }
}

class _OnPointClickListener extends mbm.OnPointAnnotationClickListener {
  final Function(String) onTap;
  _OnPointClickListener({required this.onTap});
  @override
  void onPointAnnotationClick(mbm.PointAnnotation annotation) {
    onTap(annotation.id);
  }
}
