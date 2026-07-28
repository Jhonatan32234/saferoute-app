import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:provider/provider.dart';
import 'package:saferoute_app/core/utils/reporte_mapper.dart';
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
  mbm.PointAnnotationManager? _pointAnnotationManager;
  mbm.PolylineAnnotationManager? _polylineAnnotationManager;

  final String _styleUrl = "mapbox://styles/dev-saferoute/cmrpjagea00bt01qta2r53wkl";
  final Map<String, NotificacionEntity> _idToAlerta = {};
  String? _lastRutaId;
  int _lastMarkersCount = -1;

  late AnimationController _routeAnimationController;
  double _lastAnimValue = 0.0;
  bool _isDrawingRuta = false;

  @override
  void initState() {
    super.initState();
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        if ((_routeAnimationController.value - _lastAnimValue).abs() > 0.04) {
          _lastAnimValue = _routeAnimationController.value;
          _dibujarRutaActual();
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dibujarRutaActual();
        }
      });

    // Escuchar cambios de los providers de forma manual para evitar rebuilds del MapWidget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MapaProvider>().addListener(_onProviderChanged);
        context.read<NotificacionProvider>().addListener(_onProviderChanged);
      }
    });
  }

  @override
  void dispose() {
    // Remover listeners para evitar fugas de memoria
    if (mounted) {
      try {
        context.read<MapaProvider>().removeListener(_onProviderChanged);
        context.read<NotificacionProvider>().removeListener(_onProviderChanged);
      } catch (_) {}
    }
    _routeAnimationController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted && _mapboxMap != null) {
      _actualizarMapa();
    }
  }

  void _onMapCreated(mbm.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(mapboxMap);
    }
    
    // Configuración de UI básica
    _mapboxMap?.compass.updateSettings(mbm.CompassSettings(enabled: false));
    _mapboxMap?.scaleBar.updateSettings(mbm.ScaleBarSettings(enabled: false));

    // ✅ BLOQUEO TOTAL DE ROTACIÓN Y PITCH (VISTA CENITAL ESTRICTA)
    _mapboxMap?.gestures.updateSettings(mbm.GesturesSettings(
      rotateEnabled: false,
      pitchEnabled: false,
      scrollEnabled: true,
      pinchToZoomEnabled: true,
      doubleTapToZoomInEnabled: true,
      quickZoomEnabled: true,
    ));

    _mapboxMap?.location.updateSettings(mbm.LocationComponentSettings(
      enabled: true,
      pulsingEnabled: false,
    ));

    await _registrarIconos();

    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();

    _pointAnnotationManager?.addOnPointAnnotationClickListener(
      _OnPointClickListener(onTap: (id) => _manejarClicMarcador(id)),
    );

    _recenterInicial();
  }

  void _recenterInicial() {
    final mapaProvider = context.read<MapaProvider>();
    _mapboxMap?.setCamera(mbm.CameraOptions(
      center: mbm.Point(coordinates: mbm.Position(mapaProvider.ubicacionActual.longitude, mapaProvider.ubicacionActual.latitude)),
      zoom: 15.0,
      pitch: 0.0,
      bearing: 0.0,
    ));
    _actualizarMapa(forzar: true);
  }

  Future<void> _registrarIconos() async {
    for (var item in ReporteMapper.tiposUI) {
      final color = Color(int.parse((item['color'] as String).replaceFirst('#', '0xFF')));
      final bytes = await _generarImagenLimpia(item['icon'] as IconData, color, hasBackground: true);
      await _mapboxMap?.style.addStyleImage(item['tipo'] as String, 1.0, mbm.MbxImage(width: 100, height: 100, data: bytes), false, [], [], null);
      await _mapboxMap?.style.addStyleImage(ReporteMapper.uiToBackend(item['tipo'] as String), 1.0, mbm.MbxImage(width: 100, height: 100, data: bytes), false, [], [], null);
    }

    final banderaBytes = await _generarBanderaFigma(const Color(0xFFEF4444));
    await _mapboxMap?.style.addStyleImage("rocket-15", 1.0, mbm.MbxImage(width: 120, height: 120, data: banderaBytes), false, [], [], null);

    final origenBytes = await _generarPuntoInicioFigma(const Color(0xFF10B981));
    await _mapboxMap?.style.addStyleImage("marker-15", 1.0, mbm.MbxImage(width: 120, height: 120, data: origenBytes), false, [], [], null);
  }

  Future<Uint8List> _generarBanderaFigma(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final basePaint = Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6.0..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(size * 0.3, size * 0.9), size * 0.12, basePaint);
    canvas.drawLine(const Offset(size * 0.3, size * 0.15), const Offset(size * 0.3, size * 0.9), strokePaint);
    final path = ui.Path();
    path.moveTo(size * 0.3, size * 0.15);
    path.lineTo(size * 0.9, size * 0.35);
    path.lineTo(size * 0.3, size * 0.55);
    path.close();
    canvas.drawShadow(path, Colors.black, 4.0, true);
    canvas.drawPath(path, paint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generarPuntoInicioFigma(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size/2, size/2), size * 0.3, Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(const Offset(size/2, size/2), size * 0.3, paint);
    canvas.drawCircle(const Offset(size/2, size/2), size * 0.12, whitePaint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generarImagenLimpia(IconData icon, Color color, {bool hasBackground = false}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0;
    if (hasBackground) {
      final paint = Paint()..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);
      final borderPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 4.0;
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, borderPaint);
    }
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontSize: hasBackground ? 50.0 : 80.0, fontFamily: icon.fontFamily ?? 'MaterialIcons', color: color, package: icon.fontPackage),
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
    if (_pointAnnotationManager == null || _polylineAnnotationManager == null) return;

    if (mapaProvider.rutas.isEmpty && mapaProvider.origenBusqueda == null) {
      _polylineAnnotationManager?.deleteAll();
      _pointAnnotationManager?.deleteAll();
      _lastRutaId = null;
      _lastMarkersCount = -1;
      return;
    }

    _verificarRuta(mapaProvider, forzar);
    _dibujarMarcadores(mapaProvider, notiProvider);

    if (!_routeAnimationController.isAnimating && mapaProvider.polilineas.isNotEmpty) {
      _dibujarRutaActual();
    }
  }

  void _verificarRuta(MapaProvider provider, bool forzar) {
    final currentId = provider.rutaSeleccionada?.id ?? (provider.rutas.isNotEmpty ? "list" : null);
    if (currentId != _lastRutaId || forzar) {
      _lastRutaId = currentId;
      if (provider.polilineas.isNotEmpty) {
        if (!_routeAnimationController.isAnimating) {
          _routeAnimationController.reset();
          _routeAnimationController.forward();
        }
        _ajustarCamaraARuta(provider);
      }
    }
  }

  void _ajustarCamaraARuta(MapaProvider provider) async {
    if (provider.polilineas.isEmpty) return;
    final List<LatLng> allPoints = provider.polilineas.expand((i) => i).toList();
    if (allPoints.isEmpty) return;

    final lineString = mbm.LineString(coordinates: allPoints.map<mbm.Position>((p) => mbm.Position(p.longitude, p.latitude)).toList());
    
    final camera = await _mapboxMap?.cameraForGeometry(
      lineString.toJson(), 
      mbm.MbxEdgeInsets(top: 100, left: 70, bottom: 320, right: 70), 
      null, 
      null
    );
    
    if (camera != null) {
      camera.pitch = 0.0;
      camera.bearing = 0.0;
      _mapboxMap?.flyTo(camera, mbm.MapAnimationOptions(duration: 1500));
    }
  }

  void _dibujarRutaActual() async {
    final provider = context.read<MapaProvider>();
    final theme = Theme.of(context);
    if (_polylineAnnotationManager == null || provider.polilineas.isEmpty || _isDrawingRuta) return;
    _isDrawingRuta = true;
    try {
      final selectedRuta = provider.rutaSeleccionada;
      final optionsList = <mbm.PolylineAnnotationOptions>[];
      for (int i = 0; i < provider.polilineas.length; i++) {
        final fullPoints = provider.polilineas[i];
        final isSelected = selectedRuta != null && provider.rutas[i].id == selectedRuta.id;
        double animValue = _routeAnimationController.isAnimating ? _routeAnimationController.value : 1.0;
        int visibleCount = (fullPoints.length * animValue).floor().clamp(2, fullPoints.length);
        final points = fullPoints.take(visibleCount).toList();

        optionsList.add(mbm.PolylineAnnotationOptions(
          geometry: mbm.LineString(coordinates: points.map<mbm.Position>((p) => mbm.Position(p.longitude, p.latitude)).toList()),
          lineColor: isSelected ? theme.colorScheme.primary.value : theme.colorScheme.secondary.value,
          lineWidth: isSelected ? 9.0 : 6.0, 
          lineOpacity: isSelected || (selectedRuta == null && i == 0) ? 1.0 : 0.22,
          lineJoin: mbm.LineJoin.ROUND,
        ));
      }
      await _polylineAnnotationManager?.deleteAll();
      await _polylineAnnotationManager?.createMulti(optionsList);
    } catch (e) {
      debugPrint("❌ Error dibujando rutas: $e");
    } finally {
      _isDrawingRuta = false;
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
      final imgId = ReporteMapper.normalize(alerta.tipo);
      final annotation = await _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(alerta.longitud, alerta.latitud)),
        iconImage: imgId, iconSize: 0.5,
      ));
      if (annotation != null) _idToAlerta[annotation.id] = alerta;
    }

    if (mapa.origenBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.origenBusqueda!.longitude, mapa.origenBusqueda!.latitude)),
        iconImage: "marker-15", iconSize: 0.7,
      ));
    }
    if (mapa.destinoBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.destinoBusqueda!.longitude, mapa.destinoBusqueda!.latitude)),
        iconImage: "rocket-15", iconSize: 0.8,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos read para evitar que el widget se reconstruya con cada cambio de ubicación (GPS)
    final mapaProvider = context.read<MapaProvider>();
    
    return mbm.MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: _styleUrl,
      onMapCreated: _onMapCreated,
      cameraOptions: mbm.CameraOptions(
        center: mbm.Point(coordinates: mbm.Position(mapaProvider.ubicacionActual.longitude, mapaProvider.ubicacionActual.latitude)),
        zoom: 15.0,
        pitch: 0.0,
        bearing: 0.0,
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
