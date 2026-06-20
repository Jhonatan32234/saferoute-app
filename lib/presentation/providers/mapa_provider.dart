import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_app/presentation/providers/notificacion_provider.dart';
import '../../data/datasources/api_datasources.dart';

class MapaProvider extends ChangeNotifier {
  final ApiDataSource api;
  String _token;
  bool _zonaInicializada = false;

  MapaProvider({required this.api, required String token}) : _token = token;

  // Setter para actualizar el token sin recrear el Provider
  set token(String nuevoToken) {
    _token = nuevoToken;
  }

  String get token => _token;

  LatLng _ubicacionActual = const LatLng(16.753, -93.115);
  List<Map<String, dynamic>> _rutas = [];
  List<Map<String, dynamic>> _clusters = [];
  bool _cargandoRutas = false;
  bool _cargandoClusters = false;
  String? _error;

  Map<String, dynamic>? _rutaSeleccionada;
  List<List<LatLng>> _polilineas = [];
  bool _mostrarSoloSeleccionada = false;

  LatLng? _origenBusqueda;
  LatLng? _destinoBusqueda;

  String _textoOrigen = '';
  String _textoDestino = '';
  bool _usarUbicacionActualPersistente = true;

  LatLng get ubicacionActual => _ubicacionActual;
  List<Map<String, dynamic>> get rutas => _rutas;
  List<Map<String, dynamic>> get clusters => _clusters;
  bool get cargandoRutas => _cargandoRutas;
  bool get cargandoClusters => _cargandoClusters;
  String? get error => _error;
  Map<String, dynamic>? get rutaSeleccionada => _rutaSeleccionada;
  List<List<LatLng>> get polilineas => _polilineas;
  bool get mostrarSoloSeleccionada => _mostrarSoloSeleccionada;
  LatLng? get origenBusqueda => _origenBusqueda;
  LatLng? get destinoBusqueda => _destinoBusqueda;

  String get textoOrigen => _textoOrigen;
  String get textoDestino => _textoDestino;
  bool get usarUbicacionActualPersistente => _usarUbicacionActualPersistente;

  void setZonaInicializada(bool valor) {
    _zonaInicializada = valor;
  }
  bool get zonaInicializada => _zonaInicializada;


  void guardarTextosBusqueda({String? origen, String? destino, bool? usarUbicacion}) {
    if (origen != null) _textoOrigen = origen;
    if (destino != null) _textoDestino = destino;
    if (usarUbicacion != null) _usarUbicacionActualPersistente = usarUbicacion;
    notifyListeners();
  }

  Future<void> inicializarUbicacion() async {
    try {
      final servicio = await Geolocator.isLocationServiceEnabled();
      if (!servicio) return;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso != LocationPermission.whileInUse && permiso != LocationPermission.always) return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _ubicacionActual = LatLng(pos.latitude, pos.longitude);
      notifyListeners();

      // <-- AGREGAR: Inicializar zona solo si no se ha hecho antes
      if (!_zonaInicializada) {
        _inicializarZonaUbicacion();
      }
    } catch (e) {
      debugPrint("GPS error: $e");
    }
  }

  // <-- AGREGAR ESTE MÉTODO NUEVO
  void _inicializarZonaUbicacion() {
    // Solo enviar la zona una vez al inicio
    if (_zonaInicializada) return;

    try {
      // Obtener el NotificacionProvider del contexto
      // Nota: Esto asume que tienes acceso al context o al provider
      // Si no, puedes pasar el NotificacionProvider como parámetro
      debugPrint('📍 Inicializando zona de ubicación: ${_ubicacionActual.latitude}, ${_ubicacionActual.longitude}');
      _zonaInicializada = true;
    } catch (e) {
      debugPrint('❌ Error inicializando zona: $e');
    }
  }

  void actualizarZonaUbicacion(NotificacionProvider notiProvider) {
    if (_zonaInicializada) return;

    final zona = [{
      'zona_nombre': 'mi_ubicacion',
      'latitud': _ubicacionActual.latitude,
      'longitud': _ubicacionActual.longitude,
      'radio_km': 15.0,
    }];

    notiProvider.actualizarZonasCobertura(zona);
    _zonaInicializada = true;
    debugPrint('✅ Zona de ubicación inicializada');
  }

  Future<void> cargarClusters() async {
    _cargandoClusters = true;
    notifyListeners();
    try {
      String urlBase = api.baseUrl.replaceAll('/api', '');
      final response = await api.client.get(
        Uri.parse('$urlBase/clusters'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _clusters = List<Map<String, dynamic>>.from(data['clusters'] ?? []);
      }
    } catch (e) {
      debugPrint("Clusters error: $e");
    } finally {
      _cargandoClusters = false;
      notifyListeners();
    }
  }

  Future<void> buscarRutas({
    required double origenLat,
    required double origenLon,
    required double destinoLat,
    required double destinoLon,
  }) async {
    _cargandoRutas = true;
    _error = null;
    _rutaSeleccionada = null;
    _polilineas = [];
    _mostrarSoloSeleccionada = false;

    _origenBusqueda = LatLng(origenLat, origenLon);
    _destinoBusqueda = LatLng(destinoLat, destinoLon);
    notifyListeners();

    try {
      final rutasRaw = await api.getRutas(
        origenLat: origenLat,
        origenLon: origenLon,
        destinoLat: destinoLat,
        destinoLon: destinoLon,
        token: _token,
      );
      _rutas = List<Map<String, dynamic>>.from(rutasRaw);

      _polilineas = [];
      for (final ruta in _rutas) {
        final geometria = ruta['geometria_osrm'] as List<dynamic>?;
        if (geometria != null) {
          _polilineas.add(geometria.map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList());
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargandoRutas = false;
      notifyListeners();
    }
  }

  void seleccionarRuta(int index) {
    if (index >= 0 && index < _rutas.length) {
      _rutaSeleccionada = _rutas[index];
      _mostrarSoloSeleccionada = true;
      notifyListeners();
    }
  }

  void mostrarTodasLasRutas() {
    _mostrarSoloSeleccionada = false;
    _rutaSeleccionada = null;
    notifyListeners();
  }

  void limpiarBusqueda() {
    _rutas = [];
    _polilineas = [];
    _rutaSeleccionada = null;
    _mostrarSoloSeleccionada = false;
    _origenBusqueda = null;
    _destinoBusqueda = null;
    notifyListeners();
  }

  void actualizarPuntoBusqueda({required double lat, required double lon, required bool esOrigen}) {
    if (esOrigen) {
      _origenBusqueda = LatLng(lat, lon);
    } else {
      _destinoBusqueda = LatLng(lat, lon);
    }
    notifyListeners();
  }
}
