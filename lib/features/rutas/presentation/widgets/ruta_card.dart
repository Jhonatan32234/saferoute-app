import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';

class RutaCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final String seguridad;
  final double distanciaKm;
  final int tiempoMinutos;
  final double riesgoCombinado;
  final VoidCallback onSelect;

  const RutaCard({
    super.key,
    required this.nombre,
    required this.tipo,
    required this.seguridad,
    required this.distanciaKm,
    required this.tiempoMinutos,
    required this.riesgoCombinado,
    required this.onSelect,
  });

  Color get _color {
    switch (seguridad) {
      case 'verde': return AppColors.success;
      case 'amarillo': return AppColors.warning;
      case 'rojo': return AppColors.danger;
      default: return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5.w, color: _color),
              SizedBox(width: 10.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombre,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${distanciaKm.toStringAsFixed(1)} km · $tiempoMinutos min',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.r),
                child: SizedBox(
                  width: 50.w,
                  height: 30.h,
                  child: TextButton(
                    onPressed: onSelect,
                    style: TextButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                    ),
                    child: Text('Ir', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
