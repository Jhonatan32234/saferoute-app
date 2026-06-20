import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/repositories/reporte_repository.dart';

class ReporteProvider extends ChangeNotifier {
  final IReporteRepository _repository;
  final String _token;

  ReporteProvider({required IReporteRepository repository, required String token})
      : _repository = repository,
        _token = token;

  bool _enviando = false;
  String? _ultimoResultado;
  String? _error;

  bool get enviando => _enviando;
  String? get ultimoResultado => _ultimoResultado;
  String? get error => _error;

  Future<void> enviarReporte({
    required String tipo,
    required double latitud,
    required double longitud,
    String notaVoz = '',
    String rutaId = 'sin-ruta',
  }) async {
    // SEGURO DE CONCURRENCIA: Evita dobles peticiones por el dictado de voz
    if (_enviando) return;

    _enviando = true;
    _error = null;
    _ultimoResultado = null;
    notifyListeners();

    try {
      await _repository.crearReporte(
        tipo: tipo,
        latitud: latitud,
        longitud: longitud,
        notaVoz: notaVoz.trim(),
        rutaId: rutaId,
        token: _token,
      );
      _ultimoResultado = 'éxito';
      _error = null;
    } catch (e) {
      _ultimoResultado = 'error';
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint("Error al enviar reporte: $e");
    } finally {
      _enviando = false;
      notifyListeners();

      // El mensaje desaparece después de 4 segundos
      Timer(const Duration(seconds: 4), () {
        _ultimoResultado = null;
        _error = null;
        notifyListeners();
      });
    }
  }
}
