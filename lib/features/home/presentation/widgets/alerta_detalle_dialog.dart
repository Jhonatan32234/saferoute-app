import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';
import '../../../../core/utils/reporte_mapper.dart';

class AlertaDetalleDialog extends StatelessWidget {
  final NotificacionEntity alerta;

  const AlertaDetalleDialog({
    super.key,
    required this.alerta,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = ReporteMapper.getIconFromType(alerta.tipo);
    final Color color = ReporteMapper.getColorFromType(alerta.tipo);
    final String label = ReporteMapper.getLabelFromType(alerta.tipo);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Diálogo (Figma Style)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono circular
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.r),
                ),
                SizedBox(width: 16.w),
                // Título y Mensaje
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        alerta.mensaje,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón Cerrar
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: const Color(0xFF94A3B8), size: 22.r),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Cuerpo: Descripción (Figma Style)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESCRIPCIÓN',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  alerta.notaVoz.isNotEmpty ? alerta.notaVoz : 'Sin descripción adicional reportada.',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF475569),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
