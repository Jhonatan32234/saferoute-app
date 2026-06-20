import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/notificacion.dart';

class NotificacionProvider extends ChangeNotifier {
  final String baseUrl;
  final String token;

  List<Notificacion> _notificaciones = [];
  WebSocketChannel? _channel;
  bool _conectado = false;
  String? _ultimaZonaEnviada;
  String? _currentRutaId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  List<Notificacion> get notificaciones => _notificaciones;
  int get sinLeer => _notificaciones.where((n) => !n.leida).length;
  bool get conectado => _conectado;

  NotificacionProvider({required this.baseUrl, required this.token});

  Future<void> cargarHistorial() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/notificaciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
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
    if (zonas.isEmpty) return;

    // Verificar si es la misma zona que ya enviamos
    if (zonas.length == 1) {
      final zona = zonas.first;
      final key = "${zona['zona_nombre']}_${zona['latitud']}_${zona['longitud']}_${zona['radio_km']}";
      if (_ultimaZonaEnviada == key) {
        debugPrint('⏭️ Zona duplicada, omitiendo: $key');
        return;
      }
      _ultimaZonaEnviada = key;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/zonas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'zonas': zonas}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Cobertura sincronizada: ${zonas.length} puntos');
      } else {
        debugPrint('⚠️ Error sincronización (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error de red zonas: $e');
    }
  }

  void escucharRuta(String rutaId, {List<Map<String, dynamic>>? puntosGeograficos}) {
    if (_currentRutaId == rutaId && _conectado) return;

    debugPrint("🔄 Alertas inteligentes: $rutaId");
    _currentRutaId = rutaId;
    _desconectarWS();
    _cancelReconnect();

    if (puntosGeograficos != null && puntosGeograficos.isNotEmpty) {
      actualizarZonasCobertura(puntosGeograficos);
    }

    try {
      final baseUri = Uri.parse(baseUrl);
      final wsUri = baseUri.replace(
        scheme: baseUri.isScheme('https') ? 'wss' : 'ws',
        path: '/ws/alertas/$rutaId',
        queryParameters: {'ngrok-skip-browser-warning': 'true'},
      );

      _channel = IOWebSocketChannel.connect(
        wsUri,
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $token',
        },
      );

      _conectado = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _procesarMensajeWS(data);
          } catch (e) {
            debugPrint("⚠️ Error WS: $e");
          }
        },
        onDone: () {
          _conectado = false;
          notifyListeners();
          _intentarReconexion(rutaId);
        },
        onError: (error) {
          _conectado = false;
          notifyListeners();
          _intentarReconexion(rutaId);
        },
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (t) {
        if (_conectado) _channel?.sink.add('ping');
      });

      notifyListeners();
    } catch (e) {
      _conectado = false;
      notifyListeners();
    }
  }

  void desconectarRuta({List<Map<String, dynamic>>? puntosFallback}) {
    _currentRutaId = null;
    _desconectarWS();
    _cancelReconnect();
    
    // En lugar de enviar [], enviamos la zona de fallback (ej: ubicación actual)
    if (puntosFallback != null && puntosFallback.isNotEmpty) {
      actualizarZonasCobertura(puntosFallback);
    }
    
    notifyListeners();
  }

  void _procesarMensajeWS(Map<String, dynamic> data) {
    final tipoMsg = data['tipo']?.toString();
    if (tipoMsg == 'ping' || tipoMsg == 'pong') return;

    if (tipoMsg == 'historial_inicial') {
      final List list = data['notificaciones'] ?? [];
      _notificaciones = list.map((item) => _mapJsonToNotificacion(item)).toList();
      notifyListeners();
      return;
    }

    debugPrint("🔔 Alerta recibida. Recargando historial...");
    cargarHistorial();
  }

  void _intentarReconexion(String rutaId) {
    if (_currentRutaId != rutaId) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => escucharRuta(rutaId));
  }

  void _cancelReconnect() => _reconnectTimer?.cancel();

  Future<void> marcarLeida(String id) async {
    final index = _notificaciones.indexWhere((n) => n.id == id);
    if (index != -1 && !_notificaciones[index].leida) {
      _notificaciones[index].leida = true;
      notifyListeners();

      try {
        final uri = Uri.parse('$baseUrl/api/user/notificaciones/marcar').replace(
          queryParameters: {'id': id},
        );

        await http.put(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true'
          },
          body: jsonEncode({'leida': true}),
        );
      } catch (e) {
        debugPrint("❌ Error marcar leída: $e");
      }
    }
  }

  void _desconectarWS() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _conectado = false;
  }

  @override
  void dispose() {
    _desconectarWS();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}
