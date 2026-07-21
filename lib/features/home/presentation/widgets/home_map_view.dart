import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbm;
import 'package:provider/provider.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    mbm.MapboxOptions.setAccessToken("pk.eyJ1IjoiZGV2LXNhZmVyb3V0ZSIsImEiOiJjbXJwaW4yNHYwMTAzMnpwemZ2bTZ4MGxqIn0.mrb2nZ82lE8Tn6tMKdhWZQ");
    
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
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
    
    _mapboxMap?.compass.updateSettings(mbm.CompassSettings(enabled: false));
    _mapboxMap?.scaleBar.updateSettings(mbm.ScaleBarSettings(enabled: false));
    
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
    ));
    _actualizarMapa(forzar: true);
  }

  Future<void> _registrarIconos() async {
    for (var item in ReporteMapper.tiposUI) {
      final color = Color(int.parse((item['color'] as String).replaceFirst('#', '0xFF')));
      final bytes = await _generarImagenDeIcono(item['icon'] as IconData, color);
      
      // ✅ Registramos usando el ID técnico (ej: 'accident', 'flood')
      await _mapboxMap?.style.addStyleImage(item['tipo'] as String, 1.0, mbm.MbxImage(width: 100, height: 100, data: bytes), false, [], [], null);
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
      style: TextStyle(
        fontSize: 60.0, 
        fontFamily: icon.fontFamily ?? 'MaterialIcons', 
        color: color, 
        package: icon.fontPackage
      ),
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
    final currentId = provider.rutaSeleccionada?.id ?? (provider.rutas.isNotEmpty ? "list" : null);
    
    if (provider.polilineas.isEmpty) {
      _polylineAnnotationManager?.deleteAll();
      _lastRutaId = null;
      return;
    }

    if (currentId != _lastRutaId || forzar) {
      _lastRutaId = currentId;
      _routeAnimationController.reset();
      _routeAnimationController.forward();
      _ajustarCamaraARuta(provider);
    }
  }

  void _ajustarCamaraARuta(MapaProvider provider) async {
    if (provider.polilineas.isEmpty) return;
    final allPoints = provider.polilineas.expand((i) => i).toList();
    final lineString = mbm.LineString(coordinates: allPoints.map((p) => mbm.Position(p.longitude, p.latitude)).toList());
    final camera = await _mapboxMap?.cameraForGeometry(lineString.toJson(), mbm.MbxEdgeInsets(top: 80, left: 50, bottom: 350, right: 50), null, null);
    if (camera != null) _mapboxMap?.flyTo(camera, mbm.MapAnimationOptions(duration: 1200));
  }

  void _dibujarRutaActual() async {
    final provider = context.read<MapaProvider>();
    if (_polylineAnnotationManager == null || provider.polilineas.isEmpty) return;
    await _polylineAnnotationManager?.deleteAll();
    for (int i = 0; i < provider.polilineas.length; i++) {
      final points = provider.polilineas[i].take((provider.polilineas[i].length * _routeAnimationController.value).floor().clamp(2, 100000)).toList();
      final isSelected = provider.rutaSeleccionada != null && provider.rutas[i] == provider.rutaSeleccionada;
      _polylineAnnotationManager?.create(mbm.PolylineAnnotationOptions(
        geometry: mbm.LineString(coordinates: points.map((p) => mbm.Position(p.longitude, p.latitude)).toList()),
        lineColor: _colorRuta(provider.rutas[i].seguridad).value,
        lineWidth: isSelected ? 8.0 : 4.0, lineOpacity: isSelected ? 1.0 : 0.4, lineJoin: mbm.LineJoin.ROUND,
      ));
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
      // ✅ Normalización forzada usando el nuevo mapper robusto
      final imgId = ReporteMapper.normalize(alerta.tipo);
      
      final annotation = await _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(alerta.longitud, alerta.latitud)),
        iconImage: imgId, 
        iconSize: 0.6,
      ));
      if (annotation != null) _idToAlerta[annotation.id] = alerta;
    }

    if (mapa.origenBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.origenBusqueda!.longitude, mapa.origenBusqueda!.latitude)),
        iconImage: "marker-15",
      ));
    }
    if (mapa.destinoBusqueda != null) {
      _pointAnnotationManager?.create(mbm.PointAnnotationOptions(
        geometry: mbm.Point(coordinates: mbm.Position(mapa.destinoBusqueda!.longitude, mapa.destinoBusqueda!.latitude)),
        iconImage: "rocket-15",
      ));
    }
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad.toLowerCase()) {
      case 'rojo': case 'alto': return const Color(0xFFDC2626);
      case 'naranja': case 'medio': return const Color(0xFFD97706);
      default: return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();
    final notiProvider = context.watch<NotificacionProvider>();
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
