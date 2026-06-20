import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../providers/mapa_provider.dart';

class BuscadorRutasWidget extends StatefulWidget {
  const BuscadorRutasWidget({super.key});

  @override
  State<BuscadorRutasWidget> createState() => _BuscadorRutasWidgetState();
}

class _BuscadorRutasWidgetState extends State<BuscadorRutasWidget> {
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late bool _usarUbicacionActual;
  bool _buscando = false;
  String? _error;

  Timer? _debounce;
  List<dynamic> _sugerencias = [];

  @override
  void initState() {
    super.initState();
    final mapaProvider = context.read<MapaProvider>();
    
    // Inicializar con valores persistentes del provider
    _origenController = TextEditingController(text: mapaProvider.textoOrigen);
    _destinoController = TextEditingController(text: mapaProvider.textoDestino);
    _usarUbicacionActual = mapaProvider.usarUbicacionActualPersistente;

    _origenController.addListener(_persistirCambios);
    _destinoController.addListener(_persistirCambios);

    _origenController.addListener(() => _onSearchChanged(esOrigen: true));
    _destinoController.addListener(() => _onSearchChanged(esOrigen: false));
  }

  void _persistirCambios() {
    context.read<MapaProvider>().guardarTextosBusqueda(
      origen: _origenController.text,
      destino: _destinoController.text,
      usarUbicacion: _usarUbicacionActual,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _origenController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  void _onSearchChanged({required bool esOrigen}) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final texto = esOrigen ? _origenController.text : _destinoController.text;
      if (texto.length > 3) {
        _previsualizarPunto(texto, esOrigen);
      }
    });
  }

  Future<void> _previsualizarPunto(String direccion, bool esOrigen) async {
    final mapaProvider = context.read<MapaProvider>();
    final ciudadPredefinida = _buscarCiudadLocal(direccion);
    
    if (ciudadPredefinida != null) {
      mapaProvider.actualizarPuntoBusqueda(
        lat: ciudadPredefinida['lat']!,
        lon: ciudadPredefinida['lon']!,
        esOrigen: esOrigen,
      );
      return;
    }

    final coords = await _geocodificar(direccion);
    if (coords != null && mounted) {
      mapaProvider.actualizarPuntoBusqueda(
        lat: coords['lat']!,
        lon: coords['lon']!,
        esOrigen: esOrigen,
      );
    }
  }

  Future<Map<String, double>?> _geocodificar(String direccion) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(direccion)},chiapas,mexico'
            '&format=json&limit=5&accept-language=es',
      );
      final response = await http.get(url, headers: {'User-Agent': 'SafeRouteApp/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          if (mounted) setState(() => _sugerencias = data);
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
          };
        }
      }
    } catch (e) {
      debugPrint("Error geocodificación: $e");
    }
    return null;
  }

  Map<String, double>? _buscarCiudadLocal(String nombre) {
    final normalizado = nombre.trim().toLowerCase();
    for (final entry in AppConstants.ciudades.entries) {
      if (entry.key.toLowerCase().contains(normalizado)) return entry.value;
    }
    return null;
  }

  Future<void> _buscarRutaFinal() async {
    final mapaProvider = context.read<MapaProvider>();
    
    if (_destinoController.text.isEmpty) {
      setState(() => _error = 'Especifica un destino');
      return;
    }

    setState(() => _buscando = true);

    double? latOri, lonOri;
    double? latDes, lonDes;

    if (_usarUbicacionActual) {
      latOri = mapaProvider.ubicacionActual.latitude;
      lonOri = mapaProvider.ubicacionActual.longitude;
    } else if (mapaProvider.origenBusqueda != null) {
      latOri = mapaProvider.origenBusqueda!.latitude;
      lonOri = mapaProvider.origenBusqueda!.longitude;
    }

    if (mapaProvider.destinoBusqueda != null) {
      latDes = mapaProvider.destinoBusqueda!.latitude;
      lonDes = mapaProvider.destinoBusqueda!.longitude;
    }

    if (latOri == null || lonOri == null) {
      setState(() {
        _error = 'No se ha detectado el origen. Escribe una dirección.';
        _buscando = false;
      });
      return;
    }
    if (latDes == null || lonDes == null) {
      setState(() {
        _error = 'No se ha localizado el destino. Intenta ser más específico.';
        _buscando = false;
      });
      return;
    }

    try {
      Navigator.pop(context);
      await mapaProvider.buscarRutas(
        origenLat: latOri,
        origenLon: lonOri,
        destinoLat: latDes,
        destinoLon: lonDes,
      );
    } catch (e) {
      debugPrint("Error final de ruta: $e");
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Planificar Viaje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!_usarUbicacionActual)
            TextField(
              controller: _origenController,
              decoration: InputDecoration(
                labelText: 'Origen',
                prefixIcon: const Icon(Icons.trip_origin, color: Colors.green),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, size: 20),
                  onPressed: () {
                    setState(() => _usarUbicacionActual = true);
                    _persistirCambios();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Desde mi ubicación actual', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500))),
                  TextButton(
                    onPressed: () {
                      setState(() => _usarUbicacionActual = false);
                      _persistirCambios();
                    },
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 12),

          TextField(
            controller: _destinoController,
            decoration: const InputDecoration(
              labelText: '¿A dónde vas?',
              prefixIcon: Icon(Icons.location_on, color: Colors.red),
              border: OutlineInputBorder(),
            ),
          ),

          if (_sugerencias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sugerencias.length,
                  itemBuilder: (context, index) {
                    final sug = _sugerencias[index]['display_name'].toString().split(',')[0];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(sug, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _destinoController.text = sug;
                          _onSearchChanged(esOrigen: false);
                          setState(() => _sugerencias = []);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          const SizedBox(height: 20),
          
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _buscando ? null : _buscarRutaFinal,
              icon: _buscando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.map),
              label: Text(_buscando ? 'Calculando...' : 'Ver Rutas Seguras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
