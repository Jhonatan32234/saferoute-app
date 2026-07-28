import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/utils/reporte_mapper.dart';
import 'package:saferoute_app/features/notificaciones/domain/entities/notificacion_entity.dart';
import 'package:saferoute_app/features/notificaciones/presentation/providers/notificacion_provider.dart';

class NotificacionesPanelV2 extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanelV2({super.key, this.onNotificacionTap});

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificacionProvider>();
    final alerts = notiProvider.notificaciones;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 0.85.sw, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 40.h, 20.w, 20.h),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alertas',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${alerts.length} alertas registradas',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (alerts.any((n) => !n.leida))
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => notiProvider.marcarTodasLeidas(),
                        child: Text(
                          'Marcar todas como leídas',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            
            // Lista de Alertas
            Expanded(
              child: alerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        return _AlertItem(
                          alerta: alerts[index],
                          onTap: () {
                            Navigator.pop(context);
                            onNotificacionTap?.call(alerts[index].latitud, alerts[index].longitud);
                          },
                          onMarkAsRead: () => notiProvider.marcarLeida(alerts[index].id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 48.r, color: const Color(0xFFCBD5E1)),
          SizedBox(height: 16.h),
          const Text(
            'No hay alertas en tu zona',
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final NotificacionEntity alerta;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const _AlertItem({
    required this.alerta, 
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = ReporteMapper.getIconFromType(alerta.tipo);
    final Color color = ReporteMapper.getColorFromType(alerta.tipo);

    return Container(
      color: alerta.leida ? Colors.transparent : const Color(0xFFF8FAFC),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de no leído
              if (!alerta.leida)
                Padding(
                  padding: EdgeInsets.only(top: 16.h, right: 8.w),
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                SizedBox(width: 16.w),

              // Icono
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.r),
              ),
              SizedBox(width: 16.w),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta.mensaje,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: alerta.leida ? FontWeight.w500 : FontWeight.w700,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                        SizedBox(width: 6.w),
                        Text(
                          'Hace ${_timeAgo(alerta.timestamp)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón marcar como leído
              if (!alerta.leida)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    onMarkAsRead();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }
}
