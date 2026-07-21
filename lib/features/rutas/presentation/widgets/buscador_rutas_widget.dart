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
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _sugerencias = []);
        return;
      }
      
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query,chiapas&format=json&limit=5');
      try {
        final response = await http.get(url, headers: {'User-Agent': 'SafeRouteApp'});
        if (response.statusCode == 200) {
          setState(() => _sugerencias = jsonDecode(response.body));
        }
      } catch (e) {
        debugPrint("Error buscando: $e");
      }
    });
  }

  Future<void> _ejecutarBusquedaFinal() async {
    if (_destinoController.text.isEmpty) return;
    
    setState(() => _estaBuscando = true);
    
    if (_sugerencias.isNotEmpty) {
      final first = _sugerencias.first;
      await _seleccionarDestino(
        first['display_name'].toString().split(',')[0],
        double.parse(first['lat']),
        double.parse(first['lon']),
      );
    } else {
      final query = _destinoController.text.toLowerCase();
      final entry = AppConstants.ciudades.entries.cast<MapEntry<String, Map<String, double>>?>().firstWhere(
        (e) => e!.key.toLowerCase().contains(query),
        orElse: () => null,
      );
      
      if (entry != null) {
        await _seleccionarDestino(entry.key, entry.value['lat']!, entry.value['lon']!);
      }
    }
    if (mounted) setState(() => _estaBuscando = false);
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
        color: Colors.transparent,
        child: Container(
          height: 0.85.sh,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
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
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _ejecutarBusquedaFinal(),
                  ),
                ),
              ),

              if (_sugerencias.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _sugerencias.length,
                    itemBuilder: (context, i) {
                      final item = _sugerencias[i];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(item['display_name'].toString().split(',')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _seleccionarDestino(
                          item['display_name'].toString().split(',')[0],
                          double.parse(item['lat']),
                          double.parse(item['lon']),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.near_me, color: Color(0xFF2563EB)),
                        title: const Text('Usar ubicación actual', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Como punto de destino'),
                        onTap: () {},
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          children: AppConstants.ciudades.keys.map((name) {
                            final coords = AppConstants.ciudades[name]!;
                            return ListTile(
                              leading: const Icon(Icons.history, color: Color(0xFF64748B)),
                              title: Text(
                                name, 
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  fontSize: 16
                                )
                              ),
                              subtitle: const Text('Destino sugerido', style: TextStyle(color: Color(0xFF94A3B8))),
                              onTap: () => _seleccionarDestino(name, coords['lat']!, coords['lon']!),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
