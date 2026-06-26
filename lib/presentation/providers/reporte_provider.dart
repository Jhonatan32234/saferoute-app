import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/reporte_repository.dart';

@injectable
class ReporteProvider extends ChangeNotifier {
  final IReporteRepository _repository;
  final FlutterSecureStorage _storage;
  String _token = '';
  StreamSubscription? _connectivitySubscription;

  ReporteProvider(this._repository, this._storage) {
    _initConnectivityListener();
    sincronizarPendientes();
  }

  set token(String nuevoToken) {
    if (_token != nuevoToken) {
      _token = nuevoToken;
      if (_token.isNotEmpty) {
        sincronizarPendientes();
      }
    }
  }

  bool _enviando = false;
  String? _ultimoResultado;
  String? _error;
  bool _sincronizando = false;

  bool get enviando => _enviando;
  String? get ultimoResultado => _ultimoResultado;
  String? get error => _error;
  bool get sincronizando => _sincronizando;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        sincronizarPendientes();
      }
    });
  }

  // lib/presentation/providers/reporte_provider.dart
// En el método enviarReporte, eliminar la línea que reemplaza el texto

  Future<void> enviarReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    String notaVoz = '',
    String rutaId = 'sin-ruta',
  }) async {
    if (_enviando) return;

    _enviando = true;
    _error = null;
    _ultimoResultado = null;
    notifyListeners();

    try {
      // ✅ ELIMINAR esta línea que reemplaza el texto:
      // notaVoz: notaVoz.trim().isEmpty ? tipo : notaVoz.trim(),

      // ✅ Usar el texto directamente
      await _repository.crearReporte(
        tipo: tipo,
        latitud: latitud,
        longitud: longitud,
        notaVoz: notaVoz.trim(),  // ✅ Solo trim, sin reemplazo
        rutaId: rutaId,
        token: _token,
      );
      _ultimoResultado = 'éxito';
      _error = null;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('timeout') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Connection refused')) {

        await _guardarReporteLocal(tipo, latitud, longitud, notaVoz, rutaId);
        _ultimoResultado = 'éxito';
        _error = 'Reporte guardado. Se sincronizará al recuperar la conexión.';
      } else {
        _ultimoResultado = 'error';
        _error = errorStr.replaceAll('Exception: ', '');
      }
    } finally {
      _enviando = false;
      notifyListeners();

      Timer(const Duration(seconds: 4), () {
        _ultimoResultado = null;
        _error = null;
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
    if (_sincronizando || _token.isEmpty) return;

    try {
      final data = await _storage.read(key: 'reportes_pendientes');
      if (data == null) return;

      List<dynamic> pendientes = jsonDecode(data);
      if (pendientes.isEmpty) return;

      _sincronizando = true;
      notifyListeners();

      List<dynamic> fallidos = [];

      for (var reporte in pendientes) {
        try {
          await _repository.crearReporte(
            tipo: reporte['tipo'],
            latitud: (reporte['latitud'] as num).toDouble(),
            longitud: (reporte['longitud'] as num).toDouble(),
            notaVoz: reporte['nota_voz'],
            rutaId: reporte['ruta_id'],
            token: _token,
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
      _sincronizando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
