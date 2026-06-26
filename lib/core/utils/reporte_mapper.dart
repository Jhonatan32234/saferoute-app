// lib/core/utils/reporte_mapper.dart
class ReporteMapper {
  // Mapeo de tipos UI (inglés) a tipos Backend (español)
  static const Map<String, String> _tipoMap = {
    'accident': 'accidente',
    'flood': 'inundacion',
    'pothole': 'bache',
    'blockage': 'bloqueo',
    'landslide': 'derrumbe',
    'fog': 'niebla',
    'nolight': 'sin_luz',
  };

  // Mapeo inverso para mostrar en UI
  static const Map<String, String> _tipoInverso = {
    'accidente': 'accident',
    'inundacion': 'flood',
    'bache': 'pothole',
    'bloqueo': 'blockage',
    'derrumbe': 'landslide',
    'niebla': 'fog',
    'sin_luz': 'nolight',
  };

  // Tipos válidos para el backend (según el código Go)
  static const List<String> tiposValidosBackend = [
    'accidente',
    'inundacion',
    'bache',
    'bloqueo',
    'derrumbe',
    'niebla',
    'sin_luz',
    'otro',  // También acepta 'otro'
  ];

  // Tipos para la UI con colores y nombres en español
  static const List<Map<String, dynamic>> tiposUI = [
    {'tipo': 'accident', 'label': 'Accidente', 'color': '#DC2626', 'icon': 'car_crash'},
    {'tipo': 'flood', 'label': 'Inundación', 'color': '#2563EB', 'icon': 'water_drop'},
    {'tipo': 'pothole', 'label': 'Bache', 'color': '#D97706', 'icon': 'circle'},
    {'tipo': 'blockage', 'label': 'Bloqueo', 'color': '#7C3AED', 'icon': 'block'},
    {'tipo': 'landslide', 'label': 'Derrumbe', 'color': '#EA580C', 'icon': 'landslide'},
    {'tipo': 'fog', 'label': 'Niebla', 'color': '#0EA5E9', 'icon': 'foggy'},
    {'tipo': 'nolight', 'label': 'Sin luz', 'color': '#EAB308', 'icon': 'lightbulb_outline'},
  ];

  // Convertir tipo UI (inglés) a tipo Backend (español)
  static String uiToBackend(String tipoUI) {
    return _tipoMap[tipoUI] ?? tipoUI;
  }

  // Convertir tipo Backend (español) a tipo UI (inglés)
  static String backendToUI(String tipoBackend) {
    return _tipoInverso[tipoBackend] ?? tipoBackend;
  }

  // Validar si un tipo es válido para el backend
  static bool isValidForBackend(String tipo) {
    return tiposValidosBackend.contains(tipo);
  }

  // Obtener el nombre en español de un tipo UI
  static String getLabelFromUIType(String tipoUI) {
    final found = tiposUI.firstWhere(
          (t) => t['tipo'] == tipoUI,
      orElse: () => {'label': tipoUI},
    );
    return found['label'] as String;
  }

  // Obtener el color de un tipo UI
  static String getColorFromUIType(String tipoUI) {
    final found = tiposUI.firstWhere(
          (t) => t['tipo'] == tipoUI,
      orElse: () => {'color': '#64748B'},
    );
    return found['color'] as String;
  }
}