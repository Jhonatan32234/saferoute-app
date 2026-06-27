import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'notificacion_provider.dart';
import '../../../../domain/entities/notificacion.dart';

class NotificacionesPanel extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanel({super.key, this.onNotificacionTap});

  void _mostrarDetalles(BuildContext context, Notificacion n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _getTipoColor(n.tipo), size: 24.r),
            SizedBox(width: 10.w),
            Text(
              'Detalle de Alerta',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.mensaje, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 17.sp, 
                color: Colors.black87
              )
            ),
            SizedBox(height: 16.h),
            _infoRow(Icons.category, 'Tipo: ${n.tipo.toUpperCase()}'),
            _infoRow(Icons.access_time, 'Hora: ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}'),
            if (n.notaVoz.isNotEmpty)
              _infoRow(Icons.description, 'Descripción: ${n.notaVoz}'),
            SizedBox(height: 20.h),
            Text(
              'El marcador aparecerá resaltado en el mapa para tu referencia.', 
              style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.grey[700], fontSize: 14.sp)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              if (onNotificacionTap != null) {
                onNotificacionTap!(n.latitud, n.longitud);
              }
            },
            icon: Icon(Icons.location_searching, size: 18.r),
            label: Text('Localizar', style: TextStyle(fontSize: 14.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.r, color: Colors.blueGrey[400]),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accidente': return Colors.red;
      case 'bloqueo': return Colors.orange;
      default: return Colors.amber[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificacionProvider>();
    final notifications = notiProvider.notificaciones;

    return Container(
      constraints: BoxConstraints(
        maxHeight: 0.75.sh,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w, height: 4.h,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.r)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertas de Seguridad', 
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                    Text(
                      '${notiProvider.sinLeer} alertas por revisar', 
                      style: TextStyle(color: Colors.blueGrey[600], fontSize: 13.sp)
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.black54, size: 24.r),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (notifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64.r, color: Colors.grey),
                    SizedBox(height: 16.h),
                    Text('No hay alertas en tu zona', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return Opacity(
                    opacity: n.leida ? 0.7 : 1.0,
                    child: Card(
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      elevation: n.leida ? 0 : 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: n.leida ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.only(left: 16.w, right: 8.w, top: 4.h, bottom: 4.h),
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: _getTipoColor(n.tipo).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTipoColor(n.tipo) == Colors.red ? Icons.error_outline : Icons.warning_amber_rounded, 
                            color: _getTipoColor(n.tipo), 
                            size: 24.r
                          ),
                        ),
                        title: Text(
                          n.mensaje, 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14.sp,
                            color: Colors.black87,
                          )
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'Hora de reporte • ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                          ),
                        ),
                        onTap: () => _mostrarDetalles(context, n),
                        trailing: n.leida 
                          ? IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green, size: 24.r),
                              onPressed: null,
                            )
                          : IconButton(
                              icon: Icon(Icons.radio_button_unchecked, color: Colors.blue, size: 24.r),
                              tooltip: 'Marcar como leída',
                              onPressed: () => notiProvider.marcarLeida(n.id),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
