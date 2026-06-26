import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mapa_provider.dart';
import 'ruta_card.dart';

class RutaPillWidget extends StatelessWidget {
  const RutaPillWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();

    if (mapaProvider.cargandoRutas) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: _pillDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12.w),
            Text('Calculando rutas...', style: TextStyle(fontSize: 13.sp)),
          ],
        ),
      );
    }

    if (mapaProvider.mostrarSoloSeleccionada && mapaProvider.rutaSeleccionada != null) {
      final ruta = mapaProvider.rutaSeleccionada!;
      return Container(
        padding: EdgeInsets.all(10.r),
        decoration: _pillDecoration(),
        child: Row(
          children: [
            Container(
              width: 4.w, height: 32.h,
              decoration: BoxDecoration(
                color: _colorSeguridad(ruta['seguridad'] ?? 'verde'),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ruta['nombre'] ?? 'Ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                  Text(
                    '${(ruta['distancia_km'] ?? 0).toStringAsFixed(1)} km · ${ruta['tiempo_minutos'] ?? 0} min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20.r, color: Colors.grey),
              onPressed: () => mapaProvider.mostrarTodasLasRutas(),
              tooltip: 'Ver todas las opciones',
            ),
          ],
        ),
      );
    }

    if (mapaProvider.rutas.isNotEmpty) {
      return Container(
        constraints: BoxConstraints(maxHeight: 280.h),
        padding: EdgeInsets.all(10.r),
        decoration: _pillDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Opciones de Ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                const Spacer(),
                GestureDetector(
                  onTap: () => mapaProvider.limpiarBusqueda(),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(Icons.close, size: 20.r, color: Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mapaProvider.rutas.length,
                itemBuilder: (context, index) {
                  final ruta = mapaProvider.rutas[index];
                  return RutaCard(
                    nombre: ruta['nombre'] ?? 'Ruta',
                    tipo: ruta['tipo'] ?? 'estandar',
                    seguridad: ruta['seguridad'] ?? 'verde',
                    distanciaKm: (ruta['distancia_km'] ?? 0).toDouble(),
                    tiempoMinutos: (ruta['tiempo_minutos'] ?? 0).toInt(),
                    riesgoCombinado: (ruta['riesgo_combinado'] ?? 0).toDouble(),
                    onSelect: () => mapaProvider.seleccionarRuta(index),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  BoxDecoration _pillDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.r)],
    );
  }

  Color _colorSeguridad(String seguridad) {
    switch (seguridad) {
      case 'verde': return Colors.green;
      case 'amarillo': return Colors.orange;
      case 'rojo': return Colors.red;
      default: return Colors.grey;
    }
  }
}
