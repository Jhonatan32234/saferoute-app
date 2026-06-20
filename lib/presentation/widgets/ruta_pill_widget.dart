import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mapa_provider.dart';
import 'ruta_card.dart';

class RutaPillWidget extends StatelessWidget {
  const RutaPillWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();

    // Estado: cargando
    if (mapaProvider.cargandoRutas) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _pillDecoration(),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Calculando rutas...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    // Estado: ruta seleccionada (viaje iniciado)
    if (mapaProvider.mostrarSoloSeleccionada && mapaProvider.rutaSeleccionada != null) {
      final ruta = mapaProvider.rutaSeleccionada!;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: _pillDecoration(),
        child: Row(
          children: [
            Container(
              width: 4, height: 32,
              decoration: BoxDecoration(
                color: _colorSeguridad(ruta['seguridad'] ?? 'verde'),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ruta['nombre'] ?? 'Ruta', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '${(ruta['distancia_km'] ?? 0).toStringAsFixed(1)} km · ${ruta['tiempo_minutos'] ?? 0} min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () => mapaProvider.mostrarTodasLasRutas(),
              tooltip: 'Ver todas las opciones',
            ),
          ],
        ),
      );
    }

    // Estado: múltiples rutas encontradas
    if (mapaProvider.rutas.isNotEmpty) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 280),
        padding: const EdgeInsets.all(10),
        decoration: _pillDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Opciones de Ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                // CORRECCIÓN: Ahora este botón limpia la búsqueda por completo
                GestureDetector(
                  onTap: () => mapaProvider.limpiarBusqueda(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
