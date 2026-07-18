import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/reporte_repository.dart';
import 'reporte_state.dart';

@injectable
class ReporteProvider extends ChangeNotifier {
  final IReporteRepository _repository;
  final FlutterSecureStorage _storage;
  StreamSubscription? _connectivitySubscription;

  ReporteState _state = const ReporteInitial();

  ReporteProvider(this._repository, this._storage) {
    _initConnectivityListener();
    sincronizarPendientes();
  }

  ReporteState get state => _state;

  // Helpers UI
  bool get enviando => _state is ReporteLoading;
  String? get ultimoResultado => _state is ReporteSuccess ? 'éxito' : (_state is ReporteError ? 'error' : null);
  String? get error => _state is ReporteError ? (_state as ReporteError).error : null;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        sincronizarPendientes();
      }
    });
  }

  Future<void> enviarReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    String notaVoz = '',
    String rutaId = 'sin-ruta',
  }) async {
    _state = const ReporteLoading();
    notifyListeners();

    try {
      await _repository.crearReporte(
        tipo: tipo,
        latitud: latitud,
        longitud: longitud,
        notaVoz: notaVoz.trim(),
        rutaId: rutaId,
      );
      _state = const ReporteSuccess();
    } catch (e) {
      final errorStr = e.toString().replaceFirst('Exception: ', '');
      if (errorStr.contains('SocketException') ||
          errorStr.contains('timeout') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection refused')) {

        await _guardarReporteLocal(tipo, latitud, longitud, notaVoz, rutaId);
        _state = const ReporteSuccess(message: 'Reporte guardado localmente');
      } else {
        _state = ReporteError(errorStr);
      }
    } finally {
      notifyListeners();

      Timer(const Duration(seconds: 4), () {
        _state = const ReporteInitial();
        notifyListeners();
      });
    }
  }

  Future<void> _guardarReporteLocal(
      String tipo, double latitud, double longitud, String notaVoz, String rutaId) async {
    try {
      final data = await _storage.read(key: 'reportes_pendientes');
      List<dynamic> pendientes = data != null ? jsonDecode(data) : [];

      pendientes.add({
        'tipo': tipo,
        'latitud': latitud,
        'longitud': longitud,
        'nota_voz': notaVoz,
        'ruta_id': rutaId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _storage.write(key: 'reportes_pendientes', value: jsonEncode(pendientes));
    } catch (e) {
      debugPrint("Error en cache local: $e");
    }
  }

  Future<void> sincronizarPendientes() async {
    try {
      final data = await _storage.read(key: 'reportes_pendientes');
      if (data == null) return;

      List<dynamic> pendientes = jsonDecode(data);
      if (pendientes.isEmpty) return;

      List<dynamic> fallidos = [];

      for (var reporte in pendientes) {
        try {
          await _repository.crearReporte(
            tipo: reporte['tipo'],
            latitud: (reporte['latitud'] as num).toDouble(),
            longitud: (reporte['longitud'] as num).toDouble(),
            notaVoz: reporte['nota_voz'],
            rutaId: reporte['ruta_id'],
          );
        } catch (e) {
          final errorStr = e.toString();
          fallidos.add(reporte);

          if (errorStr.contains('SocketException') ||
              errorStr.contains('timeout') ||
              errorStr.contains('Failed host lookup') ||
              errorStr.contains('Connection refused')) {
            break;
          }
        }
      }

      if (fallidos.isEmpty) {
        await _storage.delete(key: 'reportes_pendientes');
      } else {
        await _storage.write(key: 'reportes_pendientes', value: jsonEncode(fallidos));
      }
    } catch (e) {
      debugPrint("Error crítico de sincronización: $e");
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
