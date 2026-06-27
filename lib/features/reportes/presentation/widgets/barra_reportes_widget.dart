import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BarraReportesWidget extends StatelessWidget {
  final Function(String tipo) onTipoSeleccionado;

  const BarraReportesWidget({super.key, required this.onTipoSeleccionado});

  static const _tipos = [
    {'tipo': 'accidente', 'icono': Icons.car_crash, 'label': 'Accidente', 'color': Colors.red},
    {'tipo': 'inundacion', 'icono': Icons.water, 'label': 'Inundación', 'color': Colors.blue},
    {'tipo': 'bache', 'icono': Icons.dangerous, 'label': 'Bache', 'color': Colors.orange},
    {'tipo': 'derrumbe', 'icono': Icons.landslide, 'label': 'Derrumbe', 'color': Colors.brown},
    {'tipo': 'bloqueo', 'icono': Icons.block, 'label': 'Bloqueo', 'color': Colors.redAccent},
    {'tipo': 'niebla', 'icono': Icons.foggy, 'label': 'Niebla', 'color': Colors.grey},
    {'tipo': 'sin_luz', 'icono': Icons.lightbulb_outline, 'label': 'Sin luz', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: _tipos.map((tipo) => Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: GestureDetector(
                onTap: () => onTipoSeleccionado(tipo['tipo'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: (tipo['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tipo['icono'] as IconData, 
                        color: tipo['color'] as Color, 
                        size: 28.r
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      tipo['label'] as String,
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
