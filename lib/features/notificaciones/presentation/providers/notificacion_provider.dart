import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/session_service.dart';
import '../../domain/entities/notificacion_entity.dart';
import '../../domain/repositories/notification_repository.dart';

@lazySingleton
class NotificacionProvider extends ChangeNotifier {
  final INotificacionRepository repository;
  final SessionService _sessionService;

  List<NotificacionEntity> _notificaciones = [];
  List<NotificacionEntity> _alertasMapa = []; 
  WebSocketChannel? _channel;
  bool _conectado = false;
  String? _currentRutaId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _historialRefreshTimer; 

  NotificacionEntity? _ultimaAlertaUrgente;
  NotificacionEntity? get ultimaAlertaUrgente => _ultimaAlertaUrgente;

  NotificacionProvider(this.repository, this._sessionService) {
    _iniciarRefrescoHistorial();
  }

  List<NotificacionEntity> get notificaciones => _notificaciones;
  List<NotificacionEntity> get alertasMapa => _alertasMapa;
  int get sinLeer => _notificaciones.where((n) => !n.leida && n.esAdmin).length;
  bool get conectado => _conectado;

  void limpiarAlertaUrgente() {
    _ultimaAlertaUrgente = null;
    notifyListeners();
  }

  void _iniciarRefrescoHistorial() {
    _historialRefreshTimer?.cancel();
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
    if (!_sessionService.hasToken) return;
    try {
      _notificaciones = await repository.getHistorial();
      notifyListeners();
      
      // Si no hay un timer activo, lo iniciamos al cargar el historial exitosamente
      if (_historialRefreshTimer == null || !_historialRefreshTimer!.isActive) {
        _iniciarRefrescoHistorial();
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
        await repository.marcarLeida(id);
      } catch (e) {
        debugPrint('❌ Error marcando como leída: $e');
      }
    }
  }

  Future<void> marcarTodasLeidas() async {
    if (!_sessionService.hasToken) return;
    for (var n in _notificaciones) {
      if (n.esAdmin) n.leida = true;
    }
    notifyListeners();

    try {
      await repository.marcarTodasLeidas();
    } catch (e) {
      debugPrint('❌ Error marcando todas como leídas: $e');
      cargarHistorial();
    }
  }

  void escucharRuta(String rutaId) {
    if (_currentRutaId == rutaId && _conectado) return;
    if (!_sessionService.hasToken) return;

    _currentRutaId = rutaId;
    _desconectarWS();

    try {
      final baseUri = Uri.parse(repository.baseUrl);
      final wsUri = baseUri.replace(
        scheme: baseUri.isScheme('https') ? 'wss' : 'ws',
        path: '/ws/alertas/$rutaId',
      );

      _channel = IOWebSocketChannel.connect(wsUri, headers: {'Authorization': 'Bearer ${_sessionService.token}'});
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
      return;
    }

    if (data['tipo'] == 'alerta_proximidad') {
      final notificacion = NotificacionEntity.fromJson(data);
      if (!_alertasMapa.any((n) => n.reporteId == notificacion.reporteId)) {
        _alertasMapa.add(notificacion);
        notifyListeners();
      }
      return;
    }

    if (data['tipo'] == 'alerta_incidente_admin') {
      debugPrint('🔔 Alerta de administrador recibida via WS');
      _ultimaAlertaUrgente = NotificacionEntity.fromJson(data);
      cargarHistorial(); 
      notifyListeners();
      return;
    }

    cargarHistorial();
  }

  void agregarAlertaLocal(NotificacionEntity alerta) {
    if (!_alertasMapa.any((n) => n.id == alerta.id)) {
      _alertasMapa.add(alerta);
      notifyListeners();
    }
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

  void resetTotal() {
    desconectarRuta();
    _notificaciones = [];
    _alertasMapa = [];
    _ultimaAlertaUrgente = null;
    _historialRefreshTimer?.cancel();
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
