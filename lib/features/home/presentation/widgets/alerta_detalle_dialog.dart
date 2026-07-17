import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';

class AlertaDetalleDialog extends StatelessWidget {
  final NotificacionEntity alerta;

  const AlertaDetalleDialog({
    super.key,
    required this.alerta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alerta.tipo.toUpperCase(), 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16.h),
            Text(alerta.mensaje, style: theme.textTheme.bodyMedium),
            if (alerta.notaVoz.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                alerta.notaVoz, 
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
