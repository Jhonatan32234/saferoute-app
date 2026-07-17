import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Imports absolutos a tu propia feature
import 'package:saferoute_app/features/home/domain/repositories/home_repository.dart';
import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';

@injectable
class MapaProvider extends ChangeNotifier {
  final IHomeRepository homeRepository;
  final DotEnv _dotenv;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String _token = '';
  String _userId = '';
  bool _zonaInicializada = false;

  MapaProvider(this.homeRepository, this._dotenv);

  set token(String nuevoToken) {
    if (_token != nuevoToken) {
      _token = nuevoToken;
      if (_token.isNotEmpty) {
        cargarDestinosRecientes();
      }
    }
  }
  set userId(String id) => _userId = id;

  LatLng _ubicacionActual = const LatLng(16.753, -93.115);
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

  // --- Propiedades del Viaje ---
  String? _viajeId;
  bool _enViaje = false;
  bool _viajeCargando = false;
  bool _desviado = false;
  WebSocketChannel? _socket;
  Timer? _telemetriaTimer;
  Timer? _telemetriaNotiTimer;
  
  // --- Historial de Destinos ---
  List<DestinoReciente> _destinosRecientes = [];
  bool _cargandoDestinos = false;

  // Getters
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

  bool get enViaje => _enViaje;
  bool get viajeCargando => _viajeCargando;
  bool get desviado => _desviado;
  String? get viajeId => _viajeId;

  List<DestinoReciente> get destinosRecientes => _destinosRecientes;
  bool get cargandoDestinos => _cargandoDestinos;

  void guardarTextosBusqueda({String? origen, String? destino, bool? usarUbicacion}) {
    if (origen != null) _textoOrigen = origen;
    if (destino != null) _textoDestino = destino;
    if (usarUbicacion != null) _usarUbicacionActualPersistente = usarUbicacion;
    notifyListeners();
  }

  Future<void> inicializarUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (e) {
          pos = await Geolocator.getLastKnownPosition();
        }

        if (pos != null) {
          _ubicacionActual = LatLng(pos.latitude, pos.longitude);
          notifyListeners();
        }
        _iniciarRastreoGPS();
      }
    } catch (e) {
      debugPrint("📍 [GPS] Error: $e");
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
    ).listen((Position pos) {
      if (!_rastreoActivo) return;
      _ubicacionActual = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    });
  }

  void detenerRastreoGPS() {
    _rastreoActivo = false;
    _posicionStream?.cancel();
    notifyListeners();
  }

  void actualizarZonaUbicacion() {
    if (_zonaInicializada) return;
    _zonaInicializada = true;
    notifyListeners();
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
      _rutas = await homeRepository.getRutas(
        origenLat: origenLat,
        origenLon: origenLon,
        destinoLat: destinoLat,
        destinoLon: destinoLon,
        token: _token,
      );

      _polilineas = [];
      for (final ruta in _rutas) {
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

  // --- LÓGICA DE VIAJES ---

  Future<void> iniciarViaje() async {
    if (_rutaSeleccionada == null) return;
    
    _viajeCargando = true;
    notifyListeners();

    try {
      final id = await homeRepository.iniciarViaje(
        origenLat: _origenBusqueda!.latitude,
        origenLon: _origenBusqueda!.longitude,
        destinoLat: _destinoBusqueda!.latitude,
        destinoLon: _destinoBusqueda!.longitude,
        polylineRuta: _rutaSeleccionada!.polyline,
        rutaId: _rutaSeleccionada!.nombre,
        token: _token,
      );

      _viajeId = id;
      _enViaje = true;
      await _storage.write(key: 'viaje_id_activo', value: id);

      // Guardar en el historial de la API
      try {
        await homeRepository.guardarDestinoReciente(
          nombre: _textoDestino,
          lat: _destinoBusqueda!.latitude,
          lon: _destinoBusqueda!.longitude,
          token: _token,
        );
        cargarDestinosRecientes(); // Refrescar lista
      } catch (e) {
        debugPrint("Error guardando destino en API: $e");
      }

      _conectarWebSocket();

      _telemetriaTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        _enviarTelemetriaActual();
      });

    } catch (e) {
      _error = "Error al iniciar viaje: $e";
    } finally {
      _viajeCargando = false;
      notifyListeners();
    }
  }

  void _conectarWebSocket() {
    if (_viajeId == null) return;
    
    final wsBaseUrl = _dotenv.maybeGet('WS_BASE_URL') ?? 'ws://10.0.2.2:8080';
    final wsUrl = "$wsBaseUrl/ws/alertas/${_rutaSeleccionada?.nombre}?user_id=$_userId";
    
    try {
      _socket = WebSocketChannel.connect(Uri.parse(wsUrl));
      _socket!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['tipo'] == 'telemetria_ack') {
          if (data['estado_viaje'] == 'desviado') {
            _manejarDesvio();
          } else {
            _desviado = false;
            notifyListeners();
          }
        }
      }, onError: (err) {
        debugPrint("WS Error: $err");
      }, onDone: () {
        debugPrint("WS Cerrado");
      });
    } catch (e) {
      debugPrint("Error conectando WS: $e");
    }
  }

  void _enviarTelemetriaActual() async {
    if (_socket == null || !_enViaje) return;

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final payload = {
        "tipo": "telemetria",
        "lat": pos.latitude,
        "lon": pos.longitude,
        "velocidad_kmh": pos.speed * 3.6,
        "ruta_id": _rutaSeleccionada?.nombre,
        "timestamp": DateTime.now().toIso8601String()
      };
      _socket!.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint("Error enviando telemetria: $e");
    }
  }

  void _manejarDesvio() {
    if (!_desviado) {
      _desviado = true;
      HapticFeedback.vibrate();
      notifyListeners();
    }
  }

  Future<bool> finalizarViaje({String? password}) async {
    if (_viajeId == null) return false;

    _viajeCargando = true;
    notifyListeners();

    try {
      final exito = await homeRepository.finalizarViaje(
        viajeId: _viajeId!,
        password: password,
        token: _token,
      );

      if (exito) {
        _limpiarViaje();
        return true;
      }
      return false;
    } catch (e) {
      _error = "Error al finalizar: $e";
      return false;
    } finally {
      _viajeCargando = false;
      notifyListeners();
    }
  }

  void _limpiarViaje() {
    _enViaje = false;
    _viajeId = null;
    _desviado = false;
    _telemetriaTimer?.cancel();
    _socket?.sink.close();
    _storage.delete(key: 'viaje_id_activo');
    limpiarBusqueda();
  }

  double calcularDistanciaAlDestino() {
    if (_destinoBusqueda == null) return double.infinity;
    return Geolocator.distanceBetween(
      _ubicacionActual.latitude,
      _ubicacionActual.longitude,
      _destinoBusqueda!.latitude,
      _destinoBusqueda!.longitude,
    );
  }

  // --- DESTINOS RECIENTES ---
  
  Future<void> cargarDestinosRecientes() async {
    if (_token.isEmpty) return;
    _cargandoDestinos = true;
    notifyListeners();
    try {
      _destinosRecientes = await homeRepository.getDestinosRecientes(_token);
    } catch (e) {
      debugPrint("Error cargando destinos recientes: $e");
    } finally {
      _cargandoDestinos = false;
      notifyListeners();
    }
  }

  Future<void> eliminarDestinoReciente(String id) async {
    try {
      await homeRepository.eliminarDestinoReciente(id, _token);
      _destinosRecientes.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error eliminando destino: $e");
    }
  }

  @override
  void dispose() {
    _telemetriaTimer?.cancel();
    _socket?.sink.close();
    _posicionStream?.cancel();
    super.dispose();
  }
}
