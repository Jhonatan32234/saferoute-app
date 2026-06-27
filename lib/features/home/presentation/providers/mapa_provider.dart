import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:injectable/injectable.dart';

// Imports absolutos a tu propia feature
import 'package:saferoute_app/features/home/domain/repositories/home_repository.dart';
import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';

import '../../../notifications/presentation/providers/notificacion_provider.dart';

@injectable
class MapaProvider extends ChangeNotifier {
  // Ahora usamos el repositorio específico del Home
  final IHomeRepository homeRepository;
  String _token = '';
  bool _zonaInicializada = false;

  MapaProvider(this.homeRepository);

  set token(String nuevoToken) {
    _token = nuevoToken;
  }

  String get token => _token;

  LatLng _ubicacionActual = const LatLng(16.753, -93.115);

  // ¡CAMBIO CLAVE! Ahora es una lista de entidades, no de mapas crudos
  List<RutaEntity> _rutas = [];
  bool _cargandoRutas = false;
  String? _error;

  RutaEntity? _rutaSeleccionada;
  List<List<LatLng>> _polilineas = [];
  bool _mostrarSoloSeleccionada = false;

  LatLng? _origenBusqueda;
  LatLng? _destinoBusqueda;

  String _textoOrigen = '';
  String _textoDestino = '';
  bool _usarUbicacionActualPersistente = true;

  StreamSubscription<Position>? _posicionStream;
  bool _rastreoActivo = false;

  // Getters actualizados
  LatLng get ubicacionActual => _ubicacionActual;
  List<RutaEntity> get rutas => _rutas;
  bool get cargandoRutas => _cargandoRutas;
  String? get error => _error;
  RutaEntity? get rutaSeleccionada => _rutaSeleccionada;
  List<List<LatLng>> get polilineas => _polilineas;
  bool get mostrarSoloSeleccionada => _mostrarSoloSeleccionada;
  LatLng? get origenBusqueda => _origenBusqueda;
  LatLng? get destinoBusqueda => _destinoBusqueda;

  String get textoOrigen => _textoOrigen;
  String get textoDestino => _textoDestino;
  bool get usarUbicacionActualPersistente => _usarUbicacionActualPersistente;
  bool get zonaInicializada => _zonaInicializada;
  bool get rastreoActivo => _rastreoActivo;

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

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _ubicacionActual = LatLng(pos.latitude, pos.longitude);
      notifyListeners();

      _iniciarRastreoGPS();
    } catch (e) {
      debugPrint("GPS error: $e");
    }
  }

  void _iniciarRastreoGPS() {
    _rastreoActivo = true;
    _posicionStream?.cancel();

    _posicionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
          (Position posicion) {
        if (!_rastreoActivo) return;
        _ubicacionActual = LatLng(posicion.latitude, posicion.longitude);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error GPS stream: $error');
      },
    );
  }

  void detenerRastreoGPS() {
    _rastreoActivo = false;
    _posicionStream?.cancel();
    notifyListeners();
  }

  void actualizarZonaUbicacion(NotificacionProvider notiProvider) {
    if (_zonaInicializada) return;
    _zonaInicializada = true;
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
      // Llamada al repositorio puro que devuelve List<RutaEntity>
      _rutas = await homeRepository.getRutas(
        origenLat: origenLat,
        origenLon: origenLon,
        destinoLat: destinoLat,
        destinoLon: destinoLon,
        token: _token,
      );

      _polilineas = [];
      for (final ruta in _rutas) {
        // Accedemos a la propiedad .coordenadas del objeto
        if (ruta.coordenadas.isNotEmpty) {
          _polilineas.add(ruta.coordenadas
              .map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()))
              .toList());
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

  Future<void> cargarClusters() async {}

  @override
  void dispose() {
    _posicionStream?.cancel();
    super.dispose();
  }
}