import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';

class AdminAlertDialog extends StatelessWidget {
  final NotificacionEntity alerta;

  const AdminAlertDialog({
    super.key,
    required this.alerta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.primary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: theme.colorScheme.onPrimary, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'INSTRUCCIÓN DE CONTROL', 
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
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
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onPrimary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instrucción directa del administrador.', 
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: theme.colorScheme.onPrimary, 
            foregroundColor: theme.colorScheme.primary,
          ),
          child: const Text('ENTENDIDO'),
        ),
      ],
    );
  }
}
