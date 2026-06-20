import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/mapa_provider.dart';
import '../providers/reporte_provider.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/barra_reportes_widget.dart';
import '../widgets/ruta_pill_widget.dart';
import '../widgets/buscador_rutas_widget.dart';
import '../widgets/nota_voz_widget.dart';
import '../widgets/notificaciones_panel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  bool _mostrandoBarraReportes = false;
  String? _tipoReporteSeleccionado;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
    _monitorearConectividad();
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
      if (reporteProvider.ultimoResultado != null) {
        setState(() {
          _mostrandoBarraReportes = false;
          _tipoReporteSeleccionado = null;
        });
        if (reporteProvider.ultimoResultado == 'éxito') {
          mapaProvider.cargarClusters();
        }
      }
    }
  }

  void _onRutaChanged() {
    if (!mounted) return;
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    if (mapaProvider.rutaSeleccionada != null) {
      final String id = mapaProvider.rutaSeleccionada!['id']?.toString() ?? 'sin-ruta';
      final String nombreRuta = mapaProvider.rutaSeleccionada!['nombre'] ?? 'Ruta';
      
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
          // Tomar solo 30 puntos distribuidos uniformemente
          final zonasFiltradas = <Map<String, dynamic>>[];
          final stepFiltro = (zonas.length / 30).ceil();
          for (int i = 0; i < zonas.length; i += stepFiltro) {
            zonasFiltradas.add(zonas[i]);
          }
          // Asegurar incluir la última
          if (zonasFiltradas.last['zona_nombre'] != zonas.last['zona_nombre']) {
            zonasFiltradas.add(zonas.last);
          }
          notiProvider.escucharRuta(id, puntosGeograficos: zonasFiltradas);
        } else {
          notiProvider.escucharRuta(id, puntosGeograficos: zonas);
        }
      }
      
    } else {
      final List<Map<String, dynamic>> fallback = [{
        'zona_nombre': 'mi_ubicacion',
        'latitud': mapaProvider.ubicacionActual.latitude,
        'longitud': mapaProvider.ubicacionActual.longitude,
        'radio_km': 15.0,
      }];
      notiProvider.desconectarRuta(puntosFallback: fallback);
    }
  }

  void _onNotificacionActualizada() {}

  Future<void> _inicializar() async {
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    await mapaProvider.inicializarUbicacion();
    await mapaProvider.cargarClusters();
    await notiProvider.cargarHistorial();
    
    if (mounted) {
      _moverAPunto(mapaProvider.ubicacionActual);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarZonaUbicacion();
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
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    // Solo si no se ha inicializado antes
    if (!mapaProvider.zonaInicializada) {
      mapaProvider.actualizarZonaUbicacion(notiProvider);
    }
  }

  void _moverAPunto(LatLng punto) {
    _mapController.move(punto, 14.5);
  }

  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificacionesPanel(
        onNotificacionTap: (lat, lon) {
          _moverAPunto(LatLng(lat, lon));
        },
      ),
    );
  }

  void _mostrarBuscadorRutas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BuscadorRutasWidget(),
    );
  }

  void _enviarReporte(String notaVoz) {
    final reporteProvider = context.read<ReporteProvider>();
    final mapaProvider = context.read<MapaProvider>();
    if (_tipoReporteSeleccionado != null) {
      final rutaId = mapaProvider.rutaSeleccionada?['id']?.toString() ?? 'sin-ruta';
      reporteProvider.enviarReporte(
        tipo: _tipoReporteSeleccionado!,
        latitud: mapaProvider.ubicacionActual.latitude,
        longitud: mapaProvider.ubicacionActual.longitude,
        notaVoz: notaVoz,
        rutaId: rutaId,
      );
    }
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SafeRoute'),
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _online ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _mostrarNotificaciones(context),
              ),
              if (notiProvider.sinLeer > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${notiProvider.sinLeer}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            auth.logout();
            Navigator.pushReplacementNamed(context, '/');
          }),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapaProvider.ubicacionActual,
              initialZoom: 12,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
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
            top: 16, left: 16, right: 16,
            child: Column(
              children: [
                if (!tieneRutas)
                  ElevatedButton.icon(
                    onPressed: () => _mostrarBuscadorRutas(context),
                    icon: const Icon(Icons.route, color: Colors.green),
                    label: const Text('¿A dónde vas? - Ruta Segura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 6,
                    ),
                  )
                else
                  const RutaPillWidget(),
              ],
            ),
          ),

          Positioned(
            bottom: 20, left: 16, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (reporteProvider.ultimoResultado != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: reporteProvider.ultimoResultado == 'éxito' ? Colors.green : Colors.red,
                    ),
                    child: Text(
                      reporteProvider.ultimoResultado == 'éxito' ? 'Reporte enviado' : '❌ ${reporteProvider.error}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (reporteProvider.enviando)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Enviando reporte...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                if (!_mostrandoBarraReportes && _tipoReporteSeleccionado == null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FloatingActionButton.extended(
                      heroTag: 'reportar_btn',
                      backgroundColor: Colors.orange[800],
                      onPressed: () => setState(() => _mostrandoBarraReportes = true),
                      icon: const Icon(Icons.report_problem, color: Colors.white),
                      label: const Text('REPORTAR INCIDENTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                else if (_mostrandoBarraReportes && _tipoReporteSeleccionado == null)
                  Column(
                    children: [
                      BarraReportesWidget(
                        onTipoSeleccionado: (tipo) => setState(() {
                          _tipoReporteSeleccionado = tipo;
                          _mostrandoBarraReportes = false;
                        }),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _mostrandoBarraReportes = false),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else if (_tipoReporteSeleccionado != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton.filled(
                        onPressed: () => setState(() => _tipoReporteSeleccionado = null),
                        icon: const Icon(Icons.close, size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          minimumSize: const Size(72, 72),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: NotaVozWidget(onTextoListo: _enviarReporte),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
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
          color: _colorRuta(mapaProvider.rutaSeleccionada!['seguridad'] ?? 'verde'),
        ));
      }
    } else {
      for (int i = 0; i < mapaProvider.polilineas.length; i++) {
        final r = mapaProvider.rutas[i];
        polylines.add(Polyline(
          points: mapaProvider.polilineas[i],
          strokeWidth: 4,
          color: _colorRuta(r['seguridad'] ?? 'verde').withOpacity(0.8),
        ));
      }
    }
    return polylines;
  }

  List<Marker> _buildMarkers(MapaProvider mapaProvider, NotificacionProvider notiProvider) {
    final markers = <Marker>[];
    markers.add(Marker(
      point: mapaProvider.ubicacionActual,
      width: 40, height: 40,
      child: const Icon(Icons.local_shipping, color: Colors.blue, size: 30),
    ));

    for (final n in notiProvider.notificaciones) {
      if (!n.leida) {
        markers.add(Marker(
          point: LatLng(n.latitud, n.longitud),
          width: 50, height: 50,
          child: GestureDetector(
            onTap: () => _mostrarInfoAlerta(n),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 50),
                const Positioned(
                  top: 8,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ));
      }
    }

    if (mapaProvider.origenBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.origenBusqueda!,
        width: 30, height: 30,
        child: const Icon(Icons.trip_origin, color: Colors.green, size: 24),
      ));
    }
    if (mapaProvider.destinoBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.destinoBusqueda!,
        width: 30, height: 30,
        child: const Icon(Icons.location_on, color: Colors.red, size: 28),
      ));
    }

    for (final c in mapaProvider.clusters) {
      final riesgo = (c['riesgo_combinado'] ?? 0).toDouble();
      markers.add(Marker(
        point: LatLng((c['lat'] ?? 0).toDouble(), (c['lon'] ?? 0).toDouble()),
        width: 16, height: 16,
        child: Container(decoration: BoxDecoration(
          color: (riesgo > 15 ? Colors.red : riesgo > 5 ? Colors.orange : riesgo > 0.5 ? Colors.amber : Colors.green).withOpacity(0.6),
          shape: BoxShape.circle,
        )),
      ));
    }
    return markers;
  }

  void _mostrarInfoAlerta(dynamic n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Alerta en Ruta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (n.notaVoz.isNotEmpty) 
              Text('Detalles: ${n.notaVoz}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Text('Recibido: ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _moverAPunto(LatLng(n.latitud, n.longitud));
            }, 
            child: const Text('Ir al lugar')
          ),
        ],
      ),
    );
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad) {
      case 'verde': return Colors.green;
      case 'amarillo': return Colors.orange;
      case 'rojo': return Colors.red;
      default: return Colors.grey;
    }
  }
}

