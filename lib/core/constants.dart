// lib/core/constants.dart
/// Constantes de la aplicación SafeRoute
class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://10.0.2.2:8080';
  static const int apiTimeout = 10; // segundos

  // Mapas
  static const double mapaZoomDefault = 12.0;
  static const double mapaZoomCercano = 15.0;
  static const double radioIncidentesKm = 30.0;

  // Ubicación por defecto (Tuxtla Gutiérrez)
  static const double defaultLat = 16.753;
  static const double defaultLon = -93.115;

  // Reportes
  static const int reportesRefreshSegundos = 60;
  static const int reportesMaxResultados = 50;

  // Seguridad
  static const int jwtExpiracionDias = 1;
  static const int passwordMinLength = 6;

  // UI
  static const double buttonHeight = 48.0;
  static const double cardBorderRadius = 12.0;
  static const double paddingDefault = 16.0;

  // Tipos de incidente
  static const List<Map<String, dynamic>> tiposIncidente = [
    {'tipo': 'accidente', 'icono': '🚗', 'label': 'Accidente'},
    {'tipo': 'inundacion', 'icono': '🌊', 'label': 'Inundación'},
    {'tipo': 'bache', 'icono': '🕳️', 'label': 'Bache'},
    {'tipo': 'derrumbe', 'icono': '⛰️', 'label': 'Derrumbe'},
    {'tipo': 'sin_luz', 'icono': '💡', 'label': 'Sin luz'},
    {'tipo': 'otro', 'icono': '⚠️', 'label': 'Otro'},
  ];

  // Ciudades predefinidas
  static const Map<String, Map<String, double>> ciudades = {
    'Suchiapa': {'lat': 16.723, 'lon': -93.015},
    'Berriozábal': {'lat': 16.800, 'lon': -93.270},
    'Chiapa de Corzo': {'lat': 16.707, 'lon': -93.016},
    'San Cristóbal': {'lat': 16.737, 'lon': -92.637},
    'Comitán': {'lat': 16.251, 'lon': -92.134},
    'Teopisca': {'lat': 16.543, 'lon': -92.474},
  };

  // Semáforo de seguridad
  static const double riesgoVerde = 5.0;
  static const double riesgoAmarillo = 15.0;
// > 15 = rojo
}

// ✅ ELIMINAR la clase AppColors de aquí
// Ya no está, solo existe en core/theme/app_colors.dart