import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/mapa_provider.dart';

class RutaPillWidget extends StatefulWidget {
  const RutaPillWidget({super.key});

  @override
  State<RutaPillWidget> createState() => _RutaPillWidgetState();
}

class _RutaPillWidgetState extends State<RutaPillWidget> {
  bool _isExpanded = true;
  String? _lastRutaId;

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();

    final currentRuta = mapaProvider.rutaSeleccionada?.id ?? (mapaProvider.rutas.isNotEmpty ? "list" : null);
    if (currentRuta != _lastRutaId && currentRuta != null) {
      _lastRutaId = currentRuta;
    }

    if (mapaProvider.cargandoRutas || mapaProvider.viajeCargando) {
      return const SizedBox.shrink();
    }

    if (mapaProvider.enViaje) {
      return _buildViajeActivo(context, mapaProvider);
    }

    if (mapaProvider.rutas.isNotEmpty) {
      return _buildRutaOptions(context, mapaProvider);
    }

    return const SizedBox.shrink();
  }

  Widget _buildRutaOptions(BuildContext context, MapaProvider provider) {
    final theme = Theme.of(context);
    final selectedRuta = provider.rutaSeleccionada ?? (provider.rutas.isNotEmpty ? provider.rutas.first : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12.h),

        // 1. Cabecera de Destino
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: _cardDecoration(theme),
            child: Row(
              children: [
                Container(
                  width: 42.r, height: 42.r,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.4), shape: BoxShape.circle),
                  child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.textoDestino.isNotEmpty ? provider.textoDestino : (selectedRuta?.nombre ?? 'Destino'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${selectedRuta?.distanciaKm.toStringAsFixed(1)} km  ·  ${selectedRuta?.tiempoMinutos} min',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 22, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => provider.limpiarBusqueda(),
                  constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                ),
                SizedBox(width: 12.w),
                Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant, size: 26),
              ],
            ),
          ),
        ),

        if (_isExpanded) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: _cardDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('OPCIONES DE RUTA', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.1)),
                SizedBox(height: 12.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 180.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: provider.rutas.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final ruta = provider.rutas[index];
                      final isSelected = selectedRuta?.id == ruta.id;
                      return _buildRutaItem(context, ruta, isSelected, () {
                        provider.seleccionarRuta(index);
                      });
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity, height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.iniciarViaje();
                      setState(() => _isExpanded = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: const Text('Iniciar navegación', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRutaItem(BuildContext context, dynamic ruta, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.4) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.transparent, width: 2.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatRutaLabel(ruta.tipo),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)
            ),
            Text(
              '${ruta.distanciaKm.toStringAsFixed(1)} km · ${ruta.tiempoMinutos} min', 
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViajeActivo(BuildContext context, MapaProvider provider) {
    return _buildActiveHeader(provider);
  }

  Widget _buildActiveHeader(MapaProvider provider) {
    final theme = Theme.of(context);
    final distanciaM = provider.calcularDistanciaAlDestino();
    final ruta = provider.rutaSeleccionada;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: _cardDecoration(theme),
      child: Row(
        children: [
          Container(
            width: 42.r, height: 42.r, 
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.4), shape: BoxShape.circle), 
            child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20)
          ),
          SizedBox(width: 14.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.textoDestino.isNotEmpty ? provider.textoDestino : (ruta?.nombre ?? 'Destino'), 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), 
                maxLines: 1, overflow: TextOverflow.ellipsis
              ),
              Text(
                '${distanciaM > 1000 ? (distanciaM / 1000).toStringAsFixed(1) : distanciaM.toInt()} ${distanciaM > 1000 ? "km" : "m"} restantes · ${ruta?.tiempoMinutos ?? ""} min', 
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)
              ),
            ],
          )),
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 22), 
            onPressed: () => _confirmarFinalizacion(context, provider, distanciaM <= 50)
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizacion(BuildContext context, MapaProvider provider, bool normal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(normal ? '¿Has llegado?' : 'Finalización Anticipada'),
        content: Text(normal 
          ? 'Confirma que has llegado a tu destino de forma segura.' 
          : 'Aún estás lejos. Por seguridad, ingresa tu contraseña para detener el viaje.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          ElevatedButton(
            onPressed: () async {
              if (normal) {
                Navigator.pop(ctx);
                await provider.finalizarViaje();
              } else {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => _FinalizacionAnticipadaDialog(provider: provider),
                );
              }
            },
            child: Text(normal ? 'Llegué seguro' : 'Continuar'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface, 
      borderRadius: BorderRadius.circular(20.r), 
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.08), 
          blurRadius: 20, 
          offset: const Offset(0, 8)
        )
      ]
    );
  }

  String _formatRutaLabel(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('rapida') || t.contains('corta')) return 'Ruta más corta';
    if (t.contains('equilibrada') || t.contains('disponible')) return 'Ruta equilibrada';
    if (t.contains('segura') || t.contains('larga')) return 'Ruta larga';
    return tipo;
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
    final theme = Theme.of(context);
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
              decoration: InputDecoration(
                border: const OutlineInputBorder(), 
                labelText: 'Contraseña',
                hintText: 'Tu contraseña de acceso',
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
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
            backgroundColor: theme.colorScheme.error, 
            foregroundColor: theme.colorScheme.onError,
          ),
          child: _isLoading 
            ? SizedBox(width: 20.r, height: 20.r, child: CircularProgressIndicator(color: theme.colorScheme.onError, strokeWidth: 2))
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
