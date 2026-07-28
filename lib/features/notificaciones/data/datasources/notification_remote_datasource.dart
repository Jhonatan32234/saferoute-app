import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_service.dart';
import '../../domain/entities/notificacion_realtime_event.dart';
import '../models/notificacion_model.dart';
import '../../domain/entities/notificacion_entity.dart';

@lazySingleton
class NotificacionRemoteDataSource {
  final ApiClient client;
  final DotEnv dotenv;
  final SessionService _sessionService;

  WebSocketChannel? _channel;
  StreamController<NotificacionRealtimeEvent>? _streamController;

  String get baseUrl => dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8080';

  NotificacionRemoteDataSource(this.client, this.dotenv, this._sessionService);

  Future<List<NotificacionModel>> getHistorial() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/user/notificaciones?limite=50'),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body)['notificaciones'] ?? [];
      return list.map((json) => NotificacionModel.fromJson(json)).toList();
    }
    throw Exception('Error cargando historial');
  }

  Future<void> marcarLeida(String id) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/user/notificaciones/marcar?id=$id'),
      body: jsonEncode({'leida': true}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error marcando notificación como leída');
    }
  }

  Future<void> marcarTodasLeidas() async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/user/notificaciones/marcar-todas'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error marcando todas las notificaciones como leídas');
    }
  }

  Stream<NotificacionRealtimeEvent> observarRuta(String rutaId) {
    _desconectarWS();
    _streamController = StreamController<NotificacionRealtimeEvent>.broadcast();

    try {
      final baseUri = Uri.parse(baseUrl);
      final wsUri = baseUri.replace(
        scheme: baseUri.isScheme('https') ? 'wss' : 'ws',
        path: '/ws/alertas/$rutaId',
      );

      debugPrint('🔌 [WS DataSource] Intentando conectar a: $wsUri');
      
      _channel = IOWebSocketChannel.connect(
        wsUri, 
        headers: {'Authorization': 'Bearer ${_sessionService.token}'}
      );

      _streamController?.add(const NotificacionConexionCambiada(true));

      _channel!.stream.listen(
        (msg) {
          debugPrint('📥 [WS DataSource] Mensaje recibido: $msg');
          _procesarMensajeWS(jsonDecode(msg));
        },
        onDone: () {
          debugPrint('🔌 [WS DataSource] Conexión cerrada');
          _streamController?.add(const NotificacionConexionCambiada(false));
        },
        onError: (err) {
          debugPrint('❌ [WS DataSource] Error: $err');
          _streamController?.add(NotificacionConexionCambiada(false, message: err.toString()));
        },
      );

    } catch (e) {
      debugPrint('❌ [WS DataSource] Error fatal al conectar: $e');
      _streamController?.add(NotificacionConexionCambiada(false, message: e.toString()));
    }

    return _streamController!.stream;
  }

  void _procesarMensajeWS(Map<String, dynamic> data) {
    if (data['tipo'] == 'ping' || data['tipo'] == 'pong') return;

    if (data['tipo'] == 'telemetria_ack') {
      _streamController?.add(NotificacionTelemetriaConfirmada(
        desviado: data['estado_viaje'] == 'desviado'
      ));
      return;
    }

    if (data['tipo'] == 'alerta_proximidad') {
      _streamController?.add(NotificacionAlertaProximidad(
        NotificacionEntity.fromJson(data)
      ));
      return;
    }

    if (data['tipo'] == 'alerta_incidente_admin') {
      _streamController?.add(NotificacionAlertaAdministrativa(
        NotificacionEntity.fromJson(data)
      ));
      return;
    }

    _streamController?.add(const NotificacionHistorialInvalidado());
  }

  Future<void> enviarTelemetria({
    required double lat,
    required double lon,
    required double velocidad,
    required String rutaId,
  }) async {
    if (_channel == null) {
      debugPrint('🚫 [WS DataSource] No se puede enviar telemetría: Socket nulo');
      return;
    }
    
    final payload = {
      'tipo': 'telemetria',
      'lat': lat,
      'lon': lon,
      'velocidad_kmh': velocidad,
      'ruta_id': rutaId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    
    debugPrint('📤 [WS DataSource] Enviando telemetría: $payload');
    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> desconectarRuta() async {
    _desconectarWS();
  }

  void _desconectarWS() {
    debugPrint('🔌 [WS DataSource] Desconectando...');
    _channel?.sink.close();
    _channel = null;
    _streamController?.close();
    _streamController = null;
  }
}
