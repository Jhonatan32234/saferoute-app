// lib/presentation/widgets/notificaciones_panel_v2.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notificacion_provider.dart';
import '../../../../domain/entities/notificacion.dart';

class NotificacionesPanelV2 extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanelV2({super.key, this.onNotificacionTap});

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificacionProvider>();
    final notifications = notiProvider.notificaciones;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.99),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32.r,
            offset: Offset(0, -8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800,
                        ),
                      ),
                      Text(
                        '${notiProvider.sinLeer} alertas sin leer',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty && notiProvider.sinLeer > 0)
                  TextButton.icon(
                    onPressed: () => notiProvider.marcarTodasLeidas(),
                    icon: Icon(Icons.done_all, size: 18.r, color: AppColors.primary),
                    label: Text(
                      'Leer todas',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.r,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          // Lista
          if (notifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48.r,
                      color: AppColors.slate300,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No hay alertas registradas',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _buildNotificationItem(context, n, notiProvider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context,
      Notificacion n,
      NotificacionProvider provider,
      ) {
    final color = _getTipoColor(n.tipo);
    final icon = _getTipoIcon(n.tipo);

    return GestureDetector(
      onTap: () => _mostrarDetalles(context, n),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: n.leida ? AppColors.slate200 : Colors.transparent,
          ),
          boxShadow: n.leida
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Centrado verticalmente
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.mensaje,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.r,
                        color: AppColors.slate400,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Hace ${_calcularTiempo(n.timestamp)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!n.leida)
              GestureDetector(
                onTap: () => provider.marcarLeida(n.id),
                child: Container(
                  padding: EdgeInsets.all(8.r), // Aumentado padding
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check, // Cambiado a check simple
                    size: 30.r, // Aumentado tamaño (era 20, +50% ≈ 30, dejado en 26 por estética)
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _calcularTiempo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident':
      case 'accidente':
        return AppColors.danger;
      case 'flood':
      case 'inundacion':
        return AppColors.primary;
      case 'pothole':
      case 'bache':
        return AppColors.warning;
      case 'blockage':
      case 'bloqueo':
        return AppColors.purple;
      case 'landslide':
      case 'derrumbe':
        return const Color(0xFFEA580C);
      case 'fog':
      case 'niebla':
        return const Color(0xFF0EA5E9);
      case 'nolight':
      case 'sin_luz':
        return const Color(0xFFEAB308);
      default:
        return AppColors.slate500;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accident':
      case 'accidente':
        return Icons.car_crash;
      case 'flood':
      case 'inundacion':
        return Icons.water_drop;
      case 'pothole':
      case 'bache':
        return Icons.circle;
      case 'blockage':
      case 'bloqueo':
        return Icons.block;
      case 'landslide':
      case 'derrumbe':
        return Icons.landslide;
      case 'fog':
      case 'niebla':
        return Icons.foggy;
      case 'nolight':
      case 'sin_luz':
        return Icons.lightbulb_outline;
      default:
        return Icons.notification_important;
    }
  }

  void _mostrarDetalles(BuildContext context, Notificacion n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: _getTipoColor(n.tipo).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTipoIcon(n.tipo),
                      color: _getTipoColor(n.tipo),
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle de Alerta',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                          ),
                        ),
                        Text(
                          n.tipo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _getTipoColor(n.tipo),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16.r,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.mensaje,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.r,
                          color: AppColors.slate400,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Hace ${_calcularTiempo(n.timestamp)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                    if (n.notaVoz.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 14.r,
                            color: AppColors.slate400,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              n.notaVoz,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            'Cerrar',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        if (onNotificacionTap != null) {
                          onNotificacionTap!(n.latitud, n.longitud);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_searching,
                                size: 16.r,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Localizar',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}