import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants.dart';
import '../../../home/presentation/providers/mapa_provider.dart';

class BuscadorRutasWidget extends StatefulWidget {
  const BuscadorRutasWidget({super.key});

  @override
  State<BuscadorRutasWidget> createState() => _BuscadorRutasWidgetState();
}

class _BuscadorRutasWidgetState extends State<BuscadorRutasWidget> {
  late TextEditingController _destinoController;
  Timer? _debounce;
  List<dynamic> _sugerencias = [];
  bool _estaBuscando = false;

  @override
  void initState() {
    super.initState();
    final mapaProvider = context.read<MapaProvider>();
    _destinoController = TextEditingController(text: mapaProvider.textoDestino);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinoController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.length < 3) {
        setState(() {
          _sugerencias = [];
          _estaBuscando = false;
        });
        return;
      }
      
      setState(() => _estaBuscando = true);
      
      // Búsqueda BLINDADA a Chiapas usando Viewbox y Bounded=1
      // Coordenadas aproximadas de Chiapas: -94.2, 17.6 (NW) y -90.3, 14.5 (SE)
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10&viewbox=-94.2,17.6,-90.3,14.5&bounded=1&countrycodes=mx&addressdetails=1');
      
      try {
        final response = await http.get(url, headers: {
          'User-Agent': 'SafeRoute_App_Final_${DateTime.now().millisecondsSinceEpoch}',
          'Accept-Language': 'es'
        });
        
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _sugerencias = jsonDecode(response.body);
              _estaBuscando = false;
            });
          }
        }
      } catch (e) {
        debugPrint("❌ Error en sugerencias: $e");
        if (mounted) setState(() => _estaBuscando = false);
      }
    });
  }

  Future<void> _ejecutarBusquedaFinal() async {
    final queryText = _destinoController.text.trim();
    if (queryText.isEmpty) return;
    
    // Si no hay sugerencias seleccionadas pero hay texto, buscamos el primer resultado RELEVANTE en Chiapas
    if (_sugerencias.isEmpty) {
      setState(() => _estaBuscando = true);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$queryText&format=json&limit=1&viewbox=-94.2,17.6,-90.3,14.5&bounded=1&countrycodes=mx');
      try {
        final response = await http.get(url, headers: {'User-Agent': 'SafeRoute_Manual'});
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          await _seleccionarDestino(
            data[0]['display_name'].toString().split(',')[0],
            double.parse(data[0]['lat']),
            double.parse(data[0]['lon']),
          );
          return;
        }
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación no encontrada en Chiapas. Intenta elegir de la lista.')),
        );
        setState(() => _estaBuscando = false);
      }
    }
  }

  Future<void> _seleccionarDestino(String nombre, double lat, double lon) async {
    final mapaProvider = context.read<MapaProvider>();
    mapaProvider.guardarTextosBusqueda(destino: nombre, usarUbicacion: true);
    Navigator.pop(context);
    await mapaProvider.buscarRutas(
      origenLat: mapaProvider.ubicacionActual.latitude,
      origenLon: mapaProvider.ubicacionActual.longitude,
      destinoLat: lat,
      destinoLon: lon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.white, // ✅ Color movido aquí para corregir ListTile error
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        child: SizedBox(
          height: 0.85.sh,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2.r)),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Text('¿A dónde vas?', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16.r)),
                  child: TextField(
                    controller: _destinoController,
                    style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Buscar destino...',
                      hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                      icon: const Icon(Icons.search, color: Color(0xFF64748B)),
                      suffixIcon: _estaBuscando 
                        ? Padding(
                            padding: EdgeInsets.all(12.r),
                            child: SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (_destinoController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                                _destinoController.clear();
                                setState(() => _sugerencias = []);
                              }) 
                            : null),
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _ejecutarBusquedaFinal(),
                  ),
                ),
              ),

              if (_sugerencias.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: _sugerencias.length,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    separatorBuilder: (_, __) => SizedBox(height: 4.h),
                    itemBuilder: (context, i) {
                      final item = _sugerencias[i];
                      final name = item['display_name'].toString().split(',')[0];
                      final full = item['display_name'].toString();
                      
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          leading: Container(
                            width: 40.r, height: 40.r,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6), size: 20),
                          ),
                          title: Text(
                            name, 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, color: const Color(0xFF1E293B), letterSpacing: -0.2)
                          ),
                          subtitle: Text(
                            full, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)
                          ),
                          onTap: () => _seleccionarDestino(name, double.parse(item['lat']), double.parse(item['lon'])),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Consumer<MapaProvider>(
                    builder: (context, mapa, _) {
                      final historial = mapa.destinosRecientes;

                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.near_me, color: Color(0xFF2563EB)),
                            title: const Text('Usar ubicación actual', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Como punto de destino'),
                            onTap: () {
                              _seleccionarDestino(
                                'Mi ubicación',
                                mapa.ubicacionActual.latitude,
                                mapa.ubicacionActual.longitude,
                              );
                            },
                          ),
                          const Divider(),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                            child: Row(
                              children: [
                                Text(
                                  historial.isEmpty ? 'SIN HISTORIAL' : 'DESTINOS RECIENTES',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (historial.isEmpty)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20.r),
                                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
                                      child: Icon(Icons.history_toggle_off_rounded, size: 40.r, color: const Color(0xFFCBD5E1)),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Sin viajes recientes todavía',
                                      style: TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 14.sp),
                                    ),
                                    Text(
                                      'Tus destinos aparecerán aquí',
                                      style: TextStyle(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                itemCount: historial.length,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                separatorBuilder: (_, __) => SizedBox(height: 4.h),
                                itemBuilder: (context, index) {
                                  final destino = historial[index];
                                  return Material(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16.r),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.only(left: 12.w, right: 4.w),
                                      leading: Container(
                                        width: 40.r, height: 40.r,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 18),
                                      ),
                                      title: Text(
                                        destino.nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1E293B),
                                          fontSize: 15.sp,
                                          letterSpacing: -0.2
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Viaje reciente', 
                                        style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12.sp, fontWeight: FontWeight.w500)
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Color(0xFFCBD5E1)),
                                        onPressed: () => mapa.eliminarDestinoReciente(destino.id),
                                      ),
                                      onTap: () => _seleccionarDestino(destino.nombre, destino.lat, destino.lon),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

              Padding(
                padding: EdgeInsets.all(24.r),
                child: SizedBox(
                  width: double.infinity, height: 56.h,
                  child: ElevatedButton(
                    onPressed: _estaBuscando ? null : _ejecutarBusquedaFinal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: _estaBuscando 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('BUSCAR RUTA SEGURA', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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
