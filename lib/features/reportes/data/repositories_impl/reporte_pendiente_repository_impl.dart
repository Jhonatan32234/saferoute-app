import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/reporte_pendiente.dart';
import '../../domain/repositories/reporte_pendiente_repository.dart';

@LazySingleton(as: IReportePendienteRepository)
class ReportePendienteRepositoryImpl implements IReportePendienteRepository {
  static const _storageKey = 'reportes_pendientes';

  final FlutterSecureStorage _storage;

  ReportePendienteRepositoryImpl(this._storage);

  @override
  Future<List<ReportePendiente>> obtenerTodos() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return [];
      final items = jsonDecode(raw) as List<dynamic>;
      return items
          .map((item) => _fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
    } catch (error) {
      throw CacheException(
          'No fue posible leer los reportes pendientes: $error');
    }
  }

  @override
  Future<void> guardar(ReportePendiente reporte) async {
    final actuales = await obtenerTodos();
    await reemplazarTodos([...actuales, reporte]);
  }

  @override
  Future<void> reemplazarTodos(List<ReportePendiente> reportes) async {
    try {
      if (reportes.isEmpty) {
        await _storage.delete(key: _storageKey);
        return;
      }
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(reportes.map(_toJson).toList(growable: false)),
      );
    } catch (error) {
      throw CacheException(
          'No fue posible guardar los reportes pendientes: $error');
    }
  }

  Map<String, dynamic> _toJson(ReportePendiente reporte) => {
        'tipo': reporte.tipo,
        'latitud': reporte.latitud,
        'longitud': reporte.longitud,
        'nota_voz': reporte.notaVoz,
        'ruta_id': reporte.rutaId,
        'timestamp': reporte.timestamp.toIso8601String(),
      };

  ReportePendiente _fromJson(Map<String, dynamic> json) => ReportePendiente(
        tipo: json['tipo']?.toString() ?? '',
        latitud: (json['latitud'] as num?)?.toDouble() ?? 0,
        longitud: (json['longitud'] as num?)?.toDouble() ?? 0,
        notaVoz: json['nota_voz']?.toString() ?? '',
        rutaId: json['ruta_id']?.toString() ?? 'sin-ruta',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
}
