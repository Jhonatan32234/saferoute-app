import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';
import 'package:saferoute_app/features/home/presentation/providers/mapa_provider.dart';
import 'ruta_card.dart';

class RutaPillWidget extends StatelessWidget {
  const RutaPillWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapaProvider = context.watch<MapaProvider>();

    if (mapaProvider.cargandoRutas || mapaProvider.viajeCargando) {
      return _buildLoading(context, mapaProvider.viajeCargando ? 'Iniciando viaje...' : 'Calculando rutas...');
    }

    if (mapaProvider.enViaje) {
      return _buildViajeActivo(context, mapaProvider);
    }

    if (mapaProvider.mostrarSoloSeleccionada && mapaProvider.rutaSeleccionada != null) {
      final ruta = mapaProvider.rutaSeleccionada!;
      return Container(
        padding: EdgeInsets.all(12.r),
        decoration: _pillDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildIndicator(ruta.seguridad),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta.nombre, 
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${ruta.distanciaKm.toStringAsFixed(1)} km · ${ruta.tiempoMinutos} min',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 22.r),
                  onPressed: () => mapaProvider.mostrarTodasLasRutas(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => mapaProvider.iniciarViaje(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 0,
                ),
                child: Text('Iniciar Viaje Seguro', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
              ),
            ),
          ],
        ),
      );
    }

    if (mapaProvider.rutas.isNotEmpty) {
      return Container(
        constraints: BoxConstraints(maxHeight: 300.h),
        padding: EdgeInsets.all(12.r),
        decoration: _pillDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Rutas encontradas', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => mapaProvider.limpiarBusqueda(),
                  child: Icon(Icons.close, size: 22.r, color: theme.hintColor),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mapaProvider.rutas.length,
                itemBuilder: (context, index) {
                  final ruta = mapaProvider.rutas[index];
                  return RutaCard(
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

  Widget _buildViajeActivo(BuildContext context, MapaProvider provider) {
    final theme = Theme.of(context);
    final distanciaM = provider.calcularDistanciaAlDestino();
    final puedeFinalizarNormal = distanciaM <= 50;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: _pillDecoration(context).copyWith(
        border: provider.desviado ? Border.all(color: theme.colorScheme.error, width: 2.r) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.desviado)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
              decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(6.r)),
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.onError, size: 16.r),
                  SizedBox(width: 8.w),
                  Text('DESVÍO DETECTADO', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onError, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Row(
            children: [
              Icon(Icons.navigation, color: theme.colorScheme.primary, size: 24.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('En trayecto a destino', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      distanciaM > 1000 ? '${(distanciaM / 1000).toStringAsFixed(1)} km restantes' : '${distanciaM.toInt()} metros restantes',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _confirmarFinalizacion(context, provider, puedeFinalizarNormal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: puedeFinalizarNormal ? AppColors.success : theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizacion(BuildContext context, MapaProvider provider, bool normal) {
    if (normal) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Has llegado?'),
          content: const Text('Confirma que has llegado a tu destino de forma segura.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.finalizarViaje();
              },
              child: const Text('Llegué seguro'),
            ),
          ],
        ),
      );
    } else {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Finalización Anticipada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Aún estás lejos del destino. Por seguridad, ingresa tu contraseña para detener el seguimiento.'),
              SizedBox(height: 16.h),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver al viaje')),
            ElevatedButton(
              onPressed: () async {
                final exito = await provider.finalizarViaje(password: controller.text);
                if (exito) {
                  if (context.mounted) Navigator.pop(ctx);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña incorrecta. El seguimiento continúa.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Detener seguimiento'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoading(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: _pillDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12.w),
          Text(msg, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildIndicator(String seguridad) {
    return Container(
      width: 6.w, height: 35.h,
      decoration: BoxDecoration(
        color: _colorSeguridad(seguridad),
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }

  BoxDecoration _pillDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 15.r, offset: const Offset(0, 4)),
      ],
    );
  }

  Color _colorSeguridad(String seguridad) {
    switch (seguridad) {
      case 'verde': return AppColors.riskLow;
      case 'amarillo': return AppColors.riskMedium;
      case 'rojo': return AppColors.riskHigh;
      default: return Colors.grey;
    }
  }
}
