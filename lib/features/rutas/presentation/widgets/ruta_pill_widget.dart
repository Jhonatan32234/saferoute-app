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
  bool _showFeedback = false;
  String? _lastRutaId;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _triggerFeedback() {
    _feedbackTimer?.cancel();
    setState(() => _showFeedback = true);
    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapaProvider = context.watch<MapaProvider>();

    final currentRuta = mapaProvider.rutaSeleccionada?.id ?? (mapaProvider.rutas.isNotEmpty ? "list" : null);
    if (currentRuta != _lastRutaId && currentRuta != null) {
      _lastRutaId = currentRuta;
      Future.microtask(() => _triggerFeedback());
    }

    if (mapaProvider.cargandoRutas || mapaProvider.viajeCargando) {
      return _buildStatusPill(context, mapaProvider.viajeCargando ? 'Iniciando viaje...' : 'Calculando rutas...', isLoading: true);
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
    final selectedRuta = provider.rutaSeleccionada ?? (provider.rutas.isNotEmpty ? provider.rutas.first : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showFeedback)
          _buildStatusPill(context, 'Ruta a ${provider.textoDestino} calculada', isSuccess: true),
        
        SizedBox(height: 12.h),

        // 1. Cabecera de Destino (Maldita sea el diseño Figma Perfect)
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 42.r, height: 42.r,
                  decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.textoDestino.isNotEmpty ? provider.textoDestino : (selectedRuta?.nombre ?? 'Destino'),
                        style: TextStyle(
                          fontSize: 17.sp, 
                          fontWeight: FontWeight.w900, // Más fuerte tal cual Figma
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${selectedRuta?.distanciaKm.toStringAsFixed(1)} km  ·  ${selectedRuta?.tiempoMinutos} min',
                        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22, color: Color(0xFF94A3B8)),
                  onPressed: () => provider.limpiarBusqueda(),
                  constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                ),
                SizedBox(width: 12.w),
                Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF94A3B8), size: 26),
              ],
            ),
          ),
        ),

        if (_isExpanded) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('OPCIONES DE RUTA', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.1)),
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
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text('Iniciar navegación', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, width: 2.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatRutaLabel(ruta.tipo),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.black)
            ),
            Text(
              '${ruta.distanciaKm.toStringAsFixed(1)} km · ${ruta.tiempoMinutos} min', 
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF475569), fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String message, {bool isLoading = false, bool isSuccess = false, String? subtitle}) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isSuccess ? const Color(0xFFBBF7D0) : Colors.transparent),
      ),
      child: Row(
        children: [
          if (isLoading) SizedBox(width: 18.r, height: 18.r, child: const CircularProgressIndicator(strokeWidth: 2))
          else Container(
            padding: EdgeInsets.all(2.r),
            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: isSuccess ? const Color(0xFF16A34A) : Colors.black)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF16A34A), fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildViajeActivo(BuildContext context, MapaProvider provider) {
    if (_showFeedback) {
      return Column(
        children: [
          _buildStatusPill(context, '¡Navegación iniciada!', subtitle: 'Dirígete hacia ${provider.textoDestino}', isSuccess: true),
          SizedBox(height: 12.h),
          _buildActiveHeader(provider),
        ],
      );
    }
    return _buildActiveHeader(provider);
  }

  Widget _buildActiveHeader(MapaProvider provider) {
    final distanciaM = provider.calcularDistanciaAlDestino();
    final ruta = provider.rutaSeleccionada;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42.r, height: 42.r, 
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), 
            child: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20)
          ),
          SizedBox(width: 14.w),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.textoDestino.isNotEmpty ? provider.textoDestino : (ruta?.nombre ?? 'Destino'), 
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)), 
                maxLines: 1, overflow: TextOverflow.ellipsis
              ),
              Text(
                '${distanciaM > 1000 ? (distanciaM / 1000).toStringAsFixed(1) : distanciaM.toInt()} ${distanciaM > 1000 ? "km" : "m"} restantes · ${ruta?.tiempoMinutos ?? ""} min', 
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 22), 
            onPressed: () => _confirmarFinalizacion(context, provider, distanciaM <= 50)
          ),
          SizedBox(width: 12.w),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 26),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]);
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
