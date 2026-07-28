import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';

class AdminAlertDialog extends StatelessWidget {
  final NotificacionEntity alerta;
  final VoidCallback? onAceptar;

  const AdminAlertDialog({
    super.key,
    required this.alerta,
    this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: const Color(0xFF991B1B), // Rojo oscuro para alerta administrativa
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'INSTRUCCIÓN DE CONTROL', 
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18.sp,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alerta.mensaje, 
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Esta es una instrucción directa del centro de control. Por favor, acátela de inmediato.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (onAceptar != null) onAceptar!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF991B1B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text(
              'ENTENDIDO',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }
}
