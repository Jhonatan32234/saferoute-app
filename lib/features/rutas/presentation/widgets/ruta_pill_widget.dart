import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/theme/app_colors.dart';
import 'package:saferoute_app/core/di/injection.dart';
import 'package:saferoute_app/core/security/security_service.dart';
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
        padding: EdgeInsets.all(10.r),
        decoration: _pillDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildIndicator(ruta.seguridad),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta.nombre, 
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ruta.distanciaKm.toStringAsFixed(1)} km · ${ruta.tiempoMinutos} min',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20.r),
                  onPressed: () => mapaProvider.mostrarTodasLasRutas(),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: () => mapaProvider.iniciarViaje(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                child: Text('INICIAR VIAJE', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      );
    }

    if (mapaProvider.rutas.isNotEmpty) {
      return Container(
        constraints: BoxConstraints(maxHeight: 220.h), 
        padding: EdgeInsets.all(10.r),
        decoration: _pillDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Rutas Seguras', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => mapaProvider.limpiarBusqueda(),
                  child: Icon(Icons.close, size: 20.r, color: theme.hintColor),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
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
      padding: EdgeInsets.all(10.r),
      decoration: _pillDecoration(context).copyWith(
        border: provider.desviado ? Border.all(color: theme.colorScheme.error, width: 2.r) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.navigation_rounded, color: theme.colorScheme.primary, size: 22.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('En camino', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  distanciaM > 1000 ? '${(distanciaM / 1000).toStringAsFixed(1)} km' : '${distanciaM.toInt()} m restantes',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36.h,
            child: ElevatedButton(
              onPressed: () => _confirmarFinalizacion(context, provider, puedeFinalizarNormal),
              style: ElevatedButton.styleFrom(
                backgroundColor: puedeFinalizarNormal ? AppColors.success : theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: const Text('Llegué'),
            ),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No aún')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.finalizarViaje();
              },
              child: const Text('Llegué seguro'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FinalizacionAnticipadaDialog(provider: provider),
      );
    }
  }

  Widget _buildLoading(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: _pillDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12.w),
          Text(msg, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildIndicator(String seguridad) {
    return Container(
      width: 4.w, height: 30.h,
      decoration: BoxDecoration(
        color: _colorSeguridad(seguridad),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  BoxDecoration _pillDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface.withOpacity(0.98),
      borderRadius: BorderRadius.circular(20.r),
      boxShadow: [
        BoxShadow(color: theme.shadowColor.withOpacity(0.12), blurRadius: 20.r, offset: const Offset(0, 8)),
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

class _FinalizacionAnticipadaDialog extends StatefulWidget {
  final MapaProvider provider;
  const _FinalizacionAnticipadaDialog({required this.provider});

  @override
  State<_FinalizacionAnticipadaDialog> createState() => _FinalizacionAnticipadaDialogState();
}

class _FinalizacionAnticipadaDialogState extends State<_FinalizacionAnticipadaDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getIt<SecurityService>().setSecureMode(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    getIt<SecurityService>().setSecureMode(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finalización Anticipada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aún estás lejos. Por seguridad, ingresa tu contraseña para detener el viaje.'),
            SizedBox(height: 16.h),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                labelText: 'Contraseña',
                hintText: 'Tu contraseña de acceso',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context), 
          child: const Text('Volver')
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger, 
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Confirmar'),
        ),
      ],
    );
  }

  Future<void> _handleConfirmar() async {
    final password = _controller.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final exito = await widget.provider.finalizarViaje(password: password);
    
    if (mounted) {
      if (exito) {
        Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta.')),
        );
      }
    }
  }
}
