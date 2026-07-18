import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';
import 'package:saferoute_app/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:saferoute_app/features/notificaciones/presentation/providers/notificacion_provider.dart';

class NotificacionesPanelV2 extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanelV2({super.key, this.onNotificacionTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notiProvider = context.watch<NotificacionProvider>();
    
    final notifications = notiProvider.notificaciones
        .where((n) => n.esAdmin)
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
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
              color: theme.dividerColor,
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
                        'Centro de Mensajes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${notiProvider.sinLeer} mensajes de administración',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty && notiProvider.sinLeer > 0)
                  TextButton.icon(
                    onPressed: () => notiProvider.marcarTodasLeidas(),
                    icon: Icon(Icons.done_all, size: 18.r),
                    label: Text(
                      'Leer todos',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.r,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          // Lista
          if (notifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 48.r,
                      color: theme.disabledColor.withOpacity(0.3),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No tienes mensajes del administrador',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
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
      NotificacionEntity n,
      NotificacionProvider provider,
      ) {
    final theme = Theme.of(context);
    final color = n.esAdmin ? theme.colorScheme.primary : _getTipoColor(n.tipo);
    final icon = n.esAdmin ? Icons.admin_panel_settings : _getTipoIcon(n.tipo);

    return GestureDetector(
      onTap: () => _mostrarDetalles(context, n),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: n.leida ? theme.colorScheme.surface : theme.colorScheme.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: n.leida ? theme.dividerColor : theme.colorScheme.primary.withOpacity(0.2),
          ),
          boxShadow: n.leida
              ? null
              : [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
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
                        color: theme.hintColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Hace ${_calcularTiempo(n.timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
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
                  padding: EdgeInsets.all(8.r),
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20.r,
                    color: theme.colorScheme.primary,
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
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  Color _getTipoColor(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('accident')) return AppColors.danger;
    if (t.contains('inundacion') || t.contains('flood')) return AppColors.primary;
    if (t.contains('bache') || t.contains('pothole')) return AppColors.warning;
    if (t.contains('bloqueo') || t.contains('blockage')) return AppColors.purple;
    if (t.contains('derrumbe') || t.contains('landslide')) return const Color(0xFFEA580C);
    if (t.contains('niebla') || t.contains('fog')) return const Color(0xFF0EA5E9);
    if (t.contains('luz') || t.contains('nolight')) return const Color(0xFFEAB308);
    return AppColors.slate500;
  }

  IconData _getTipoIcon(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('accident')) return Icons.car_crash;
    if (t.contains('inundacion') || t.contains('flood')) return Icons.water_drop;
    if (t.contains('bache') || t.contains('pothole')) return Icons.circle;
    if (t.contains('bloqueo') || t.contains('blockage')) return Icons.block;
    if (t.contains('derrumbe') || t.contains('landslide')) return Icons.landslide;
    if (t.contains('niebla') || t.contains('fog')) return Icons.foggy;
    if (t.contains('luz') || t.contains('nolight')) return Icons.lightbulb_outline;
    return Icons.notification_important;
  }

  void _mostrarDetalles(BuildContext context, NotificacionEntity n) {
    showDialog(
      context: context,
      builder: (context) => _NotificacionDetalleDialog(
        n: n, 
        onNotificacionTap: onNotificacionTap,
        getTipoColor: _getTipoColor,
        getTipoIcon: _getTipoIcon,
        calcularTiempo: _calcularTiempo,
      ),
    );
  }
}

class _NotificacionDetalleDialog extends StatelessWidget {
  final NotificacionEntity n;
  final Function(double lat, double lon)? onNotificacionTap;
  final Color Function(String) getTipoColor;
  final IconData Function(String) getTipoIcon;
  final String Function(DateTime) calcularTiempo;

  const _NotificacionDetalleDialog({
    required this.n,
    this.onNotificacionTap,
    required this.getTipoColor,
    required this.getTipoIcon,
    required this.calcularTiempo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = n.esAdmin ? theme.colorScheme.primary : getTipoColor(n.tipo);
    final accentIcon = n.esAdmin ? Icons.admin_panel_settings : getTipoIcon(n.tipo);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(accentIcon, color: accentColor, size: 20.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.esAdmin ? 'Instrucción de Admin' : 'Detalle de Alerta',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        n.tipo.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accentColor,
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
                      color: theme.colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16.r, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.mensaje,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.r, color: theme.hintColor),
                      SizedBox(width: 4.w),
                      Text(
                        'Enviado ${calcularTiempo(n.timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                  if (n.notaVoz.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.description, size: 14.r, color: theme.hintColor),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            n.notaVoz,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      if (onNotificacionTap != null) {
                        onNotificacionTap!(n.latitud, n.longitud);
                      }
                    },
                    icon: const Icon(Icons.location_searching, size: 16),
                    label: const Text('Localizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
