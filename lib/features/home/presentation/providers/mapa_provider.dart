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

import 'package:saferoute_app/features/home/domain/repositories/home_repository.dart';
import 'package:saferoute_app/features/home/domain/entities/ruta_entity.dart';
import 'package:saferoute_app/features/home/domain/entities/destino_reciente_entity.dart';
import 'package:saferoute_app/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:saferoute_app/core/utils/notification_helper.dart';
import 'mapa_state.dart';

@injectable
class MapaProvider extends ChangeNotifier {
  final IHomeRepository homeRepository;
  final DotEnv _dotenv;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String _userId = '';
  bool _zonaInicializada = false;

  MapaState _state = const MapaInitial();

  NotificacionEntity? _ultimaAlertaAdmin;
  NotificacionEntity? get ultimaAlertaAdmin => _ultimaAlertaAdmin;

  MapaProvider(this.homeRepository, this._dotenv) {
    cargarDestinosRecientes();
  }

  MapaState get state => _state;

  set userId(String id) {
    if (id.isNotEmpty) {
      _userId = id;
      debugPrint("🆔 MapaProvider: userId actualizado a $_userId");
    }
  }
  
  String get userId => _userId;

  LatLng _ubicacionActual = const LatLng(16.753, -93.115);
  LatLng? _origenBusqueda;
  LatLng? _destinoBusqueda;
  String _textoOrigen = '';
  String _textoDestino = '';
  bool _usarUbicacionActualPersistente = true;

  StreamSubscription<Position>? _posicionStream;
  bool _rastreoActivo = false;

  WebSocketChannel? _socket;
  Timer? _telemetriaTimer;
  
  List<DestinoReciente> _destinosRecientes = [];
  bool _cargandoDestinos = false;

  // Getters
  LatLng get ubicacionActual => _ubicacionActual;
  bool get cargandoRutas => _state is MapaLoading;
  String? get error => _state is MapaError ? (_state as MapaError).message : null;
  
  List<RutaEntity> get rutas {
    if (_state is MapaRoutesLoaded) return (_state as MapaRoutesLoaded).rutas;
    if (_state is MapaInTrip) return [(_state as MapaInTrip).ruta];
    return [];
  }

  List<List<LatLng>> get polilineas {
    if (_state is MapaRoutesLoaded) return (_state as MapaRoutesLoaded).polilineas;
    if (_state is MapaInTrip) {
      final ruta = (_state as MapaInTrip).ruta;
      return [ruta.coordenadas.map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList()];
    }
    return [];
  }

  RutaEntity? get rutaSeleccionada {
    if (_state is MapaInTrip) return (_state as MapaInTrip).ruta;
    if (_state is MapaRoutesLoaded) {
      final s = _state as MapaRoutesLoaded;
      if (s.selectedIndex != null) return s.rutas[s.selectedIndex!];
    }
    return null;
  }

  bool get mostrarSoloSeleccionada => _state is MapaInTrip || (_state is MapaRoutesLoaded && (_state as MapaRoutesLoaded).selectedIndex != null);
  LatLng? get origenBusqueda => _origenBusqueda;
  LatLng? get destinoBusqueda => _destinoBusqueda;
  
  String get textoOrigen => _textoOrigen;
  String get textoDestino => _textoDestino;
  bool get usarUbicacionActualPersistente => _usarUbicacionActualPersistente;
  bool get zonaInicializada => _zonaInicializada;
  bool get rastreoActivo => _rastreoActivo;

  bool get enViaje => _state is MapaInTrip;
  bool get viajeCargando => _state is MapaLoading;
  bool get desviado => _state is MapaInTrip && (_state as MapaInTrip).desviado;
  String? get viajeId => _state is MapaInTrip ? (_state as MapaInTrip).viajeId : null;

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
    _state = const MapaLoading();
    _origenBusqueda = LatLng(origenLat, origenLon);
    _destinoBusqueda = LatLng(destinoLat, destinoLon);
    notifyListeners();

    try {
      final rutas = await homeRepository.getRutas(
        origenLat: origenLat,
        origenLon: origenLon,
        destinoLat: destinoLat,
        destinoLon: destinoLon,
      );

      if (rutas.isEmpty) {
        _state = const MapaError('No se encontraron rutas seguras para este destino.');
        return;
      }

      final polilineas = <List<LatLng>>[];
      for (final ruta in rutas) {
        if (ruta.coordenadas.isNotEmpty) {
          polilineas.add(ruta.coordenadas
              .map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()))
              .toList());
        }
      }

      _state = MapaRoutesLoaded(rutas: rutas, polilineas: polilineas);
    } catch (e) {
      _state = MapaError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  void seleccionarRuta(int index) {
    if (_state is MapaRoutesLoaded) {
      _state = (_state as MapaRoutesLoaded).copyWith(selectedIndex: index);
      notifyListeners();
    }
  }

  void mostrarTodasLasRutas() {
    if (_state is MapaRoutesLoaded) {
      _state = (_state as MapaRoutesLoaded).copyWith(clearSelection: true);
      notifyListeners();
    }
  }

  void limpiarBusqueda() {
    _state = const MapaInitial();
    _origenBusqueda = null;
    _destinoBusqueda = null;
    _textoOrigen = '';
    _textoDestino = '';
    notifyListeners();
  }

  void actualizarPuntoBusqueda({required double lat, required double lon, required bool esOrigen}) {
    if (!lat.isFinite || !lon.isFinite) return;
    if (esOrigen) {
      _origenBusqueda = LatLng(lat, lon);
    } else {
      _destinoBusqueda = LatLng(lat, lon);
    }
    notifyListeners();
  }

  void limpiarError() {
    if (_state is MapaError) {
      _state = const MapaInitial();
      notifyListeners();
    }
  }

  Future<void> cargarClusters() async {}

  Future<void> iniciarViaje() async {
    if (_state is! MapaRoutesLoaded) return;
    final currentState = _state as MapaRoutesLoaded;
    final index = currentState.selectedIndex ?? 0;
    final ruta = currentState.rutas[index];
    
    _state = const MapaLoading();
    notifyListeners();

    try {
      final id = await homeRepository.iniciarViaje(
        origenLat: _origenBusqueda!.latitude,
        origenLon: _origenBusqueda!.longitude,
        destinoLat: _destinoBusqueda!.latitude,
        destinoLon: _destinoBusqueda!.longitude,
        polylineRuta: ruta.polyline,
        rutaId: ruta.nombre,
      );

      _state = MapaInTrip(ruta: ruta, viajeId: id);
      await _storage.write(key: 'viaje_id_activo', value: id);

      try {
        await homeRepository.guardarDestinoReciente(
          nombre: _textoDestino,
          lat: _destinoBusqueda!.latitude,
          lon: _destinoBusqueda!.longitude,
        );
        cargarDestinosRecientes();
      } catch (e) {
        debugPrint("Error guardando destino en API: $e");
      }

      await _conectarWebSocket();

      _telemetriaTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        _enviarTelemetriaActual();
      });

    } catch (e) {
      _state = MapaError("Error al iniciar viaje: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> _conectarWebSocket() async {
    if (_state is! MapaInTrip) return;
    final currentState = _state as MapaInTrip;

    if (_userId.isEmpty) {
      debugPrint("🔍 [WS Mapa] userId vacío, intentando recuperar de persistencia...");
      final savedId = await _storage.read(key: 'user_id');
      if (savedId != null && savedId.isNotEmpty) {
        _userId = savedId;
        debugPrint("✅ [WS Mapa] userId recuperado: $_userId");
      }
    }
    
    final wsBaseUrl = _dotenv.maybeGet('WS_BASE_URL') ?? 'ws://10.0.2.2:8080';
    final wsUrl = "$wsBaseUrl/ws/alertas/${currentState.ruta.nombre}?user_id=$_userId";
    
    try {
      debugPrint("🔌 [WS Mapa] Intentando conectar a: $wsUrl");
      _socket = WebSocketChannel.connect(Uri.parse(wsUrl));
      _socket!.stream.listen((message) {
        debugPrint("📥 [WS Mapa] Mensaje recibido: $message");
        final data = jsonDecode(message);
        
        if (data['tipo'] == 'telemetria_ack') {
          if (data['estado_viaje'] == 'desviado') {
            debugPrint("⚠️ [WS Mapa] ¡Ruta desviada detectada!");
            _manejarDesvio();
          } else {
            if (_state is MapaInTrip) {
              _state = (_state as MapaInTrip).copyWith(desviado: false);
              notifyListeners();
            }
          }
          return;
        }

        if (data['tipo'] == 'alerta_incidente_admin') {
           _manejarAlertaAdmin(data);
           return;
        }

        if (data['tipo'] == 'alerta_proximidad') {
          debugPrint("📍 [WS Mapa] Alerta de proximidad recibida");
          return;
        }

      }, onError: (err) {
        debugPrint("❌ [WS Mapa] Error: $err");
      }, onDone: () {
        debugPrint("🔌 [WS Mapa] Conexión cerrada");
      });
    } catch (e) {
      debugPrint("❌ [WS Mapa] Error fatal al conectar: $e");
    }
  }

  void _manejarAlertaAdmin(Map<String, dynamic> data) {
    try {
      debugPrint("🔔 [WS Mapa] Procesando alerta de administrador...");
      final notificacion = NotificacionEntity.fromJson(data);
      _ultimaAlertaAdmin = notificacion;
      
      NotificationHelper.mostrarAlertaUrgente(
        title: '¡ALERTA CRÍTICA!',
        body: notificacion.mensaje,
      );
      
      notifyListeners();
      debugPrint("✅ [WS Mapa] Alerta admin notificada a la UI");
    } catch (e) {
      debugPrint("❌ [WS Mapa] Error parseando alerta admin: $e");
    }
  }

  void limpiarAlertaAdmin() {
    _ultimaAlertaAdmin = null;
    notifyListeners();
  }

  void _enviarTelemetriaActual() async {
    if (_socket == null || _state is! MapaInTrip) {
      debugPrint("🚫 [WS Mapa] Telemetría no enviada: Socket nulo o no está en viaje");
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final payload = {
        "tipo": "telemetria",
        "lat": pos.latitude,
        "lon": pos.longitude,
        "velocidad_kmh": pos.speed * 3.6,
        "ruta_id": (_state as MapaInTrip).ruta.nombre,
        "timestamp": DateTime.now().toIso8601String()
      };
      debugPrint("📤 [WS Mapa] Enviando telemetría: $payload");
      _socket!.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint("❌ [WS Mapa] Error enviando telemetría: $e");
    }
  }

  void _manejarDesvio() {
    if (_state is MapaInTrip && !(_state as MapaInTrip).desviado) {
      _state = (_state as MapaInTrip).copyWith(desviado: true);
      HapticFeedback.vibrate();
      notifyListeners();
    }
  }

  Future<bool> finalizarViaje({String? password}) async {
    if (_state is! MapaInTrip) return false;
    final currentState = _state as MapaInTrip;

    final oldState = _state;
    _state = const MapaLoading();
    notifyListeners();

    try {
      final exito = await homeRepository.finalizarViaje(
        viajeId: currentState.viajeId,
        password: password,
      );

      if (exito) {
        _limpiarViaje();
        return true;
      }
      _state = oldState; // Restaurar si falla
      return false;
    } catch (e) {
      _state = MapaError("Error al finalizar: $e");
      return false;
    } finally {
      notifyListeners();
    }
  }

  void _limpiarViaje() {
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

  Future<void> cargarDestinosRecientes() async {
    _cargandoDestinos = true;
    notifyListeners();
    try {
      _destinosRecientes = await homeRepository.getDestinosRecientes();
    } catch (e) {
      debugPrint("Error cargando destinos recientes: $e");
    } finally {
      _cargandoDestinos = false;
      notifyListeners();
    }
  }

  Future<void> eliminarDestinoReciente(String id) async {
    try {
      await homeRepository.eliminarDestinoReciente(id);
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

extension on MapaInTrip {
  MapaInTrip copyWith({bool? desviado}) {
    return MapaInTrip(
      ruta: ruta,
      viajeId: viajeId,
      desviado: desviado ?? this.desviado,
    );
  }
}
