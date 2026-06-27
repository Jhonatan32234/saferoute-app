import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:injectable/injectable.dart';
import '../../../../domain/entities/notificacion.dart';
import '../../../../data/datasources/api_datasources.dart';

@injectable
class NotificacionProvider extends ChangeNotifier {
  final ApiDataSource api;
  String _token = '';

  List<Notificacion> _notificaciones = [];
  List<Notificacion> _alertasMapa = []; // Alertas de proximidad activas
  WebSocketChannel? _channel;
  bool _conectado = false;
  String? _currentRutaId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _historialRefreshTimer; // NUEVO: Timer para refrescar historial

  NotificacionProvider(this.api);

  set token(String nuevoToken) {
    if (_token != nuevoToken) {
      _token = nuevoToken;
      if (_token.isNotEmpty) {
        _iniciarRefrescoHistorial();
      } else {
        _historialRefreshTimer?.cancel();
      }
    }
  }
  String get token => _token;

  List<Notificacion> get notificaciones => _notificaciones;
  List<Notificacion> get alertasMapa => _alertasMapa;
  int get sinLeer => _notificaciones.where((n) => !n.leida).length;
  bool get conectado => _conectado;

  // Inicia el refresco automático del historial cada 60 segundos
  void _iniciarRefrescoHistorial() {
    _historialRefreshTimer?.cancel();
    cargarHistorial();
    _historialRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      cargarHistorial();
    });
  }

  void enviarTelemetria(double lat, double lon, double velocidad, String rutaId) {
    if (!_conectado || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({
        'tipo': 'telemetria',
        'lat': lat,
        'lon': lon,
        'velocidad_kmh': velocidad,
        'ruta_id': rutaId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('❌ Error enviando telemetría: $e');
    }
  }

  Future<void> cargarHistorial() async {
    if (_token.isEmpty) return;
    try {
      final response = await api.client.get(
        Uri.parse('${api.baseUrl}/api/user/notificaciones?limite=50'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['notificaciones'] ?? [];
        _notificaciones = list.map((json) => _mapJsonToNotificacion(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error cargando historial: $e");
    }
  }

  Future<void> marcarLeida(String id) async {
    final index = _notificaciones.indexWhere((n) => n.id == id);
    if (index != -1 && !_notificaciones[index].leida) {
      _notificaciones[index].leida = true;
      notifyListeners();
      try {
        await api.client.put(
          Uri.parse('${api.baseUrl}/api/user/notificaciones/marcar?id=$id'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'leida': true}),
        );
      } catch (e) {
        debugPrint('❌ Error marcando como leída: $e');
      }
    }
  }

  Future<void> marcarTodasLeidas() async {
    if (_token.isEmpty) return;
    for (var n in _notificaciones) {
      n.leida = true;
    }
    notifyListeners();

    try {
      await api.client.put(
        Uri.parse('${api.baseUrl}/api/user/notificaciones/marcar-todas'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json'
        },
      );
    } catch (e) {
      debugPrint('❌ Error marcando todas como leídas: $e');
      cargarHistorial();
    }
  }

  Notificacion _mapJsonToNotificacion(Map<String, dynamic> json) {
    return Notificacion(
      id: (json['id'] ?? json['reporte_id'] ?? '').toString(),
      tipo: json['tipo_incidente'] ?? json['tipo'] ?? 'nuevo_reporte',
      mensaje: json['mensaje'] ?? '',
      reporteId: (json['reporte_id'] ?? '').toString(),
      latitud: (json['latitud'] ?? json['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lon'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      timestamp: DateTime.tryParse(json['fecha_envio'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      leida: json['leida'] ?? false,
    );
  }

  void escucharRuta(String rutaId) {
    if (_currentRutaId == rutaId && _conectado) return;
    if (_token.isEmpty) return;

    _currentRutaId = rutaId;
    _desconectarWS();

    try {
      final baseUri = Uri.parse(api.baseUrl);
      final wsUri = baseUri.replace(
        scheme: baseUri.isScheme('https') ? 'wss' : 'ws',
        path: '/ws/alertas/$rutaId',
      );

      _channel = IOWebSocketChannel.connect(wsUri, headers: {'Authorization': 'Bearer $_token'});
      _conectado = true;

      _channel!.stream.listen(
            (msg) => _procesarMensajeWS(jsonDecode(msg)),
        onDone: () { _conectado = false; _intentarReconexion(rutaId); notifyListeners(); },
        onError: (err) { _conectado = false; _intentarReconexion(rutaId); notifyListeners(); },
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (t) => _channel?.sink.add('ping'));
      notifyListeners();
    } catch (_) {}
  }

  void _procesarMensajeWS(Map<String, dynamic> data) {
    if (data['tipo'] == 'ping' || data['tipo'] == 'pong') return;
    
    if (data['tipo'] == 'telemetria_ack') {
      _alertasMapa = [];
      notifyListeners();
      return;
    }

    if (data['tipo'] == 'alerta_proximidad') {
      final notificacion = _mapJsonToNotificacion(data);
      
      // ✅ SOLO añadir a la lista de marcadores activos en el mapa
      // Ya NO se añade al historial local (_notificaciones) para evitar duplicidad o spam
      if (!_alertasMapa.any((n) => n.reporteId == notificacion.reporteId)) {
        _alertasMapa.add(notificacion);
        notifyListeners();
      }
      return;
    }

    // Para cualquier otro mensaje de tipo notificación real que el servidor envíe por WS,
    // refrescamos el historial desde la API.
    cargarHistorial();
  }

  void _intentarReconexion(String rutaId) {
    if (_currentRutaId != rutaId) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () => escucharRuta(rutaId));
  }

  void _desconectarWS() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _conectado = false;
    _alertasMapa = [];
  }

  void desconectarRuta() {
    _currentRutaId = null;
    _desconectarWS();
    notifyListeners();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _historialRefreshTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}