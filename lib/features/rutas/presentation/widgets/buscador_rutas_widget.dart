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

  bool _esBusquedaValida(String text) {
    final query = text.trim();
    if (query.length < 3) return false;

    // Validación Robusta: Solo letras del alfabeto español, números y espacios.
    // Bloquea símbolos (@, #, $) y variantes de otros idiomas (Ç, Ø, etc.)
    final regex = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s]+$');
    return regex.hasMatch(query);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!_esBusquedaValida(query)) {
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
    final queryText = _destinoController.text.trim();
    
    if (!_esBusquedaValida(queryText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación no válida. Evita usar símbolos o caracteres especiales.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _estaBuscando = true);
    
    if (_sugerencias.isNotEmpty) {
      final first = _sugerencias.first;
      await _seleccionarDestino(
        first['display_name'].toString().split(',')[0],
        double.parse(first['lat']),
        double.parse(first['lon']),
      );
    } else {
      final queryLower = queryText.toLowerCase();
      final cityEntry = AppConstants.ciudades.entries.cast<MapEntry<String, Map<String, double>>?>().firstWhere(
        (e) => e!.key.toLowerCase().contains(queryLower),
        orElse: () => null,
      );
      
      if (cityEntry != null) {
        await _seleccionarDestino(cityEntry.key, cityEntry.value['lat']!, cityEntry.value['lon']!);
      } else {
        try {
          final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$queryText,chiapas&format=json&limit=1');
          final response = await http.get(url, headers: {'User-Agent': 'SafeRouteApp'}).timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List && data.isNotEmpty) {
              await _seleccionarDestino(
                data[0]['display_name'].toString().split(',')[0],
                double.parse(data[0]['lat']),
                double.parse(data[0]['lon']),
              );
              if (mounted) setState(() => _estaBuscando = false);
              return;
            }
          }
        } catch (e) {
          debugPrint("Error en búsqueda forzada: $e");
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo encontrar la ubicación. Intenta ser más específico.')),
          );
        }
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
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Responsivo para PC
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            child: SizedBox(
              height: 0.85.sh,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                    width: 40.w, height: 4.h,
                    decoration: BoxDecoration(color: theme.colorScheme.outlineVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(2.r)),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      children: [
                        Text('¿A dónde vas?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(16.r)),
                      child: TextField(
                        controller: _destinoController,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Buscar destino...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontWeight: FontWeight.normal),
                          icon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
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
                            leading: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                            title: Text(item['display_name'].toString().split(',')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _seleccionarDestino(
                              item['display_name'].toString().split(',')[0],
                              item['lat'] is String ? double.parse(item['lat']) : (item['lat'] as num).toDouble(),
                              item['lon'] is String ? double.parse(item['lon']) : (item['lon'] as num).toDouble(),
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
                            leading: Icon(Icons.near_me, color: theme.colorScheme.primary),
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
                                  leading: Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
                                  title: Text(
                                    name, 
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    )
                                  ),
                                  subtitle: const Text('Destino sugerido'),
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
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
                        ),
                        child: _estaBuscando 
                          ? SizedBox(width: 24.r, height: 24.r, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                          : const Text('BUSCAR RUTA SEGURA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
