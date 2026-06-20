import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/notificacion.dart';

class NotificacionProvider extends ChangeNotifier {
  final String baseUrl;
  String _token;
  
  List<Notificacion> _notificaciones = [];
  WebSocketChannel? _channel;
  bool _conectado = false;
  String? _currentRutaId;
  String? _ultimaZonaKey;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  NotificacionProvider({required this.baseUrl, required String token}) : _token = token;

  set token(String nuevoToken) => _token = nuevoToken;
  String get token => _token;

  List<Notificacion> get notificaciones => _notificaciones;
  int get sinLeer => _notificaciones.where((n) => !n.leida).length;
  bool get conectado => _conectado;

  Future<void> cargarHistorial() async {
    if (_token.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/notificaciones'),
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

  Notificacion _mapJsonToNotificacion(Map<String, dynamic> json) {
    return Notificacion(
      id: (json['id'] ?? '').toString(),
      tipo: json['tipo'] ?? json['tipo_alerta'] ?? 'nuevo_reporte',
      mensaje: json['mensaje'] ?? '',
      reporteId: (json['reporte_id'] ?? '').toString(),
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      notaVoz: json['nota_voz'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      timestamp: DateTime.tryParse(json['fecha_envio'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      leida: json['leida'] ?? false,
    );
  }

  Future<void> actualizarZonasCobertura(List<Map<String, dynamic>> zonas) async {
    if (zonas.isEmpty || _token.isEmpty) return;

    final String zonaKey = jsonEncode(zonas.first); 
    if (_ultimaZonaKey == zonaKey && zonas.length == 1) return;
    _ultimaZonaKey = zonaKey;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/zonas'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'zonas': zonas}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Cobertura sincronizada: ${zonas.length} puntos');
      }
    } catch (e) {
      debugPrint('❌ Error red zonas: $e');
    }
  }

  void escucharRuta(String rutaId, {List<Map<String, dynamic>>? puntosGeograficos}) {
    if (_currentRutaId == rutaId && _conectado) return;
    if (_token.isEmpty) return;

    _currentRutaId = rutaId;
    _desconectarWS();
    
    if (puntosGeograficos != null) actualizarZonasCobertura(puntosGeograficos);

    try {
      final baseUri = Uri.parse(baseUrl);
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

  void desconectarRuta({List<Map<String, dynamic>>? puntosFallback}) {
    _currentRutaId = null;
    _desconectarWS();
    if (puntosFallback != null) actualizarZonasCobertura(puntosFallback);
    notifyListeners();
  }

  void _procesarMensajeWS(Map<String, dynamic> data) {
    if (data['tipo'] == 'ping' || data['tipo'] == 'pong') return;
    if (data['tipo'] == 'historial_inicial') {
      final List list = data['notificaciones'] ?? [];
      _notificaciones = list.map((item) => _mapJsonToNotificacion(item)).toList();
      notifyListeners();
      return;
    }
    cargarHistorial();
  }

  void _intentarReconexion(String rutaId) {
    if (_currentRutaId != rutaId) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => escucharRuta(rutaId));
  }

  Future<void> marcarLeida(String id) async {
    final index = _notificaciones.indexWhere((n) => n.id == id);
    if (index != -1 && !_notificaciones[index].leida) {
      _notificaciones[index].leida = true;
      notifyListeners();
      try {
        await http.put(
          Uri.parse('$baseUrl/api/user/notificaciones/marcar?id=$id'),
          headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
          body: jsonEncode({'leida': true}),
        );
      } catch (_) {}
    }
  }

  void _desconectarWS() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _conectado = false;
  }
}
