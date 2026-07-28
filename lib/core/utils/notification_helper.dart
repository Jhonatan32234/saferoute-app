import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 Notificación interactuada: ${response.payload}');
        },
      );

      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestNotificationsPermission();

        // Canal V7 con ID nuevo para resetear caché del sistema en el dispositivo
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'saferoute_critical_v7',
          'Alertas Críticas SafeRoute',
          description: 'Instrucciones urgentes del Centro de Control',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF991B1B),
          showBadge: true,
        );

        await androidImplementation?.createNotificationChannel(channel);
        debugPrint('✅ Canal de notificaciones v7 (HEADS-UP) inicializado');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  static Future<void> mostrarAlertaUrgente({
    required String title,
    required String body,
  }) async {
    try {
      debugPrint('🚀 Lanzando notificación Heads-up: $title');

      final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);

      final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'saferoute_critical_v7',
        'Alertas Críticas SafeRoute',
        channelDescription: 'Instrucciones urgentes del Centro de Control',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'ALERTA CRÍTICA',
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF991B1B),
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(body),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        DateTime.now().hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: 'critical_alert',
      );
    } catch (e) {
      debugPrint('❌ Error al mostrar notificación: $e');
    }
  }
}
