import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/mapa_provider.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';

class HomeMapView extends StatelessWidget {
  final MapController mapController;
  final LatLng? puntoEnfocado;
  final Function(NotificacionEntity) onAlertTap;
  final VoidCallback onResetEnfocado;

  const HomeMapView({
    super.key,
    required this.mapController,
    this.puntoEnfocado,
    required this.onAlertTap,
    required this.onResetEnfocado,
  });

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();
    final notiProvider = context.watch<NotificacionProvider>();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: mapaProvider.ubicacionActual,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.jmj.saferoute',
        ),
        PolylineLayer(polylines: _buildPolilineas(mapaProvider)),
        MarkerLayer(markers: _buildMarkers(mapaProvider, notiProvider)),
      ],
    );
  }

  List<Polyline> _buildPolilineas(MapaProvider mapaProvider) {
    final polylines = <Polyline>[];
    if (mapaProvider.mostrarSoloSeleccionada && mapaProvider.rutaSeleccionada != null) {
      final index = mapaProvider.rutas.indexOf(mapaProvider.rutaSeleccionada!);
      if (index >= 0 && index < mapaProvider.polilineas.length) {
        polylines.add(Polyline(
          points: mapaProvider.polilineas[index],
          strokeWidth: 5,
          color: _colorRuta(mapaProvider.rutaSeleccionada!.seguridad),
        ));
      }
    } else {
      for (int i = 0; i < mapaProvider.polilineas.length; i++) {
        final r = mapaProvider.rutas[i];
        polylines.add(Polyline(
          points: mapaProvider.polilineas[i],
          strokeWidth: 4,
          color: _colorRuta(r.seguridad).withOpacity(0.8),
        ));
      }
    }
    return polylines;
  }

  Color _colorRuta(String seguridad) {
    switch (seguridad) {
      case 'rojo':
        return AppColors.riskHigh;
      case 'naranja':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  List<Marker> _buildMarkers(MapaProvider mapaProvider, NotificacionProvider notiProvider) {
    final markers = <Marker>[];

    for (var alerta in notiProvider.alertasMapa) {
      final color = _getTipoColor(alerta.tipo);
      markers.add(Marker(
        point: LatLng(alerta.latitud, alerta.longitud),
        width: 40.r,
        height: 40.r,
        child: GestureDetector(
          onTap: () => onAlertTap(alerta),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTipoIcon(alerta.tipo),
              color: color,
              size: 24.r,
            ),
          ),
        ),
      ));
    }

    if (mapaProvider.origenBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.origenBusqueda!,
        width: 40.r,
        height: 40.r,
        child: Icon(
          Icons.location_on,
          color: AppColors.success,
          size: 35.r,
        ),
      ));
    }

    if (mapaProvider.destinoBusqueda != null) {
      markers.add(Marker(
        point: mapaProvider.destinoBusqueda!,
        width: 45.r,
        height: 45.r,
        child: Icon(
          Icons.flag,
          color: AppColors.danger,
          size: 40.r,
        ),
      ));
    }

    // Ubicación actual
    markers.add(Marker(
      point: mapaProvider.ubicacionActual,
      width: 40.r,
      height: 40.r,
      child: const _CurrentLocationMarker(),
    ));

    if (puntoEnfocado != null) {
      markers.add(Marker(
        point: puntoEnfocado!,
        width: 100.r,
        height: 100.r,
        child: GestureDetector(
          onTap: onResetEnfocado,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'VER AQUÍ',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                color: AppColors.danger,
                size: 50.r,
              ),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident': case 'accidente': return AppColors.danger;
      case 'flood': case 'inundacion': return AppColors.primary;
      case 'pothole': case 'bache': return AppColors.warning;
      case 'blockage': case 'bloqueo': return AppColors.purple;
      case 'landslide': case 'derrumbe': return const Color(0xFFEA580C);
      case 'fog': case 'niebla': return const Color(0xFF0EA5E9);
      case 'nolight': case 'sin_luz': return const Color(0xFFEAB308);
      default: return AppColors.slate500;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident': case 'accidente': return Icons.car_crash;
      case 'flood': case 'inundacion': return Icons.water_drop;
      case 'pothole': case 'bache': return Icons.circle;
      case 'blockage': case 'bloqueo': return Icons.block;
      case 'landslide': case 'derrumbe': return Icons.landslide;
      case 'fog': case 'niebla': return Icons.foggy;
      case 'nolight': case 'sin_luz': return Icons.lightbulb_outline;
      default: return Icons.notification_important;
    }
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 24.r,
          height: 24.r,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2.r),
          ),
          child: Center(
            child: Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
