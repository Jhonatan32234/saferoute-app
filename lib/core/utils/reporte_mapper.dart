import 'package:flutter/material.dart';

class ReporteMapper {
  static const List<Map<String, dynamic>> tiposUI = [
    {'tipo': 'accident', 'label': 'Accidente', 'color': '#F44336', 'icon': Icons.car_crash},
    {'tipo': 'flood', 'label': 'Inundación', 'color': '#2196F3', 'icon': Icons.water},
    {'tipo': 'pothole', 'label': 'Bache', 'color': '#FF9800', 'icon': Icons.dangerous},
    {'tipo': 'blockage', 'label': 'Bloqueo', 'color': '#FF5252', 'icon': Icons.block},
    {'tipo': 'landslide', 'label': 'Derrumbe', 'color': '#795548', 'icon': Icons.landslide},
    {'tipo': 'fog', 'label': 'Niebla', 'color': '#9E9E9E', 'icon': Icons.foggy},
    {'tipo': 'nolight', 'label': 'Sin luz', 'color': '#9C27B0', 'icon': Icons.lightbulb_outline},
  ];

  /// Convierte cualquier entrada (inglés, español, id) a un ID técnico único (ej: 'accident')
  static String normalize(String input) {
    final t = input.toLowerCase().trim();
    if (t.contains('accident')) return 'accident';
    if (t.contains('flood') || t.contains('inundacion')) return 'flood';
    if (t.contains('pothole') || t.contains('bache')) return 'pothole';
    if (t.contains('block') || t.contains('bloqueo')) return 'blockage';
    if (t.contains('landslide') || t.contains('derrumbe')) return 'landslide';
    if (t.contains('fog') || t.contains('niebla')) return 'fog';
    if (t.contains('light') || t.contains('luz')) return 'nolight';
    return 'accident'; // Fallback seguro
  }

  /// Para enviar al servidor (español)
  static String toBackend(String technicalId) {
    switch (technicalId) {
      case 'accident': return 'accidente';
      case 'flood': return 'inundacion';
      case 'pothole': return 'bache';
      case 'blockage': return 'bloqueo';
      case 'landslide': return 'derrumbe';
      case 'fog': return 'niebla';
      case 'nolight': return 'sin_luz';
      default: return technicalId;
    }
  }

  static String getLabel(String input) {
    final id = normalize(input);
    return tiposUI.firstWhere((t) => t['tipo'] == id, orElse: () => tiposUI[0])['label'];
  }

  static IconData getIcon(String input) {
    final id = normalize(input);
    return tiposUI.firstWhere((t) => t['tipo'] == id, orElse: () => tiposUI[0])['icon'];
  }

  static Color getColor(String input) {
    final id = normalize(input);
    final hex = tiposUI.firstWhere((t) => t['tipo'] == id, orElse: () => tiposUI[0])['color'];
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  // Compatibilidad con código anterior (alias)
  static String uiToBackend(String uiType) => toBackend(normalize(uiType));
  static String backendToUI(String backendType) => normalize(backendType);
  static String getLabelFromType(String type) => getLabel(type);
  static IconData getIconFromType(String type) => getIcon(type);
  static Color getColorFromType(String type) => getColor(type);
}
