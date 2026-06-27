import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/domain/entities/notificacion.dart';

void main() {
  group('Notificacion.fromJson', () {
    test('parses alert payload into a domain entity', () {
      final payload = {
        'id': '42',
        'tipo_incidente': 'accidente',
        'mensaje': 'Choque detectado',
        'reporte_id': '7',
        'latitud': 16.75,
        'longitud': -93.11,
        'nota_voz': 'Atención',
        'ruta_id': 'ruta-1',
        'fecha_envio': '2026-06-27T10:00:00.000Z',
        'leida': false,
      };

      final notification = Notificacion.fromJson(payload);

      expect(notification.id, '42');
      expect(notification.tipo, 'accidente');
      expect(notification.mensaje, 'Choque detectado');
      expect(notification.latitud, 16.75);
      expect(notification.longitud, -93.11);
      expect(notification.leida, isFalse);
    });
  });
}
