import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Imports absolutos
import 'package:saferoute_app/features/home/presentation/providers/mapa_provider.dart';
// Asumiendo que ruta_card.dart está en la misma carpeta
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
                // CAMBIO: ruta.seguridad
                color: _colorSeguridad(ruta.seguridad),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CAMBIO: ruta.nombre
                  Text(ruta.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                  // CAMBIO: ruta.distanciaKm y ruta.tiempoMinutos
                  Text(
                    '${ruta.distanciaKm.toStringAsFixed(1)} km · ${ruta.tiempoMinutos} min',
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
                    // CAMBIO: Todas las propiedades usan sintaxis de punto
                    nombre: ruta.nombre,
                    tipo: ruta.tipo,
                    seguridad: ruta.seguridad,
                    distanciaKm: ruta.distanciaKm,
                    tiempoMinutos: ruta.tiempoMinutos,
                    riesgoCombinado: ruta.riesgoCombinado,
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