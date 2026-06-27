// lib/presentation/widgets/buscador_rutas_widget.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';  // ✅ Solo importar de aquí
import '../../../../core/constants.dart';
import '../../../home/presentation/providers/mapa_provider.dart';

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
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32.r,
            offset: Offset(0, -8.h),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Planificar Viaje',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16.r,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Origen
            if (!_usarUbicacionActual)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: TextField(
                  controller: _origenController,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.slate800),
                  decoration: InputDecoration(
                    labelText: 'Origen',
                    labelStyle: TextStyle(fontSize: 14.sp, color: AppColors.slate600),
                    prefixIcon: Icon(Icons.trip_origin, color: AppColors.success, size: 20.r),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.my_location, size: 20.r, color: AppColors.primary),
                      onPressed: () {
                        setState(() => _usarUbicacionActual = true);
                        _persistirCambios();
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: AppColors.primary, size: 20.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Desde mi ubicación actual',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _usarUbicacionActual = false);
                        _persistirCambios();
                      },
                      child: Text(
                        'Cambiar',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 12.h),

            // Destino
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.slate200),
              ),
              child: TextField(
                controller: _destinoController,
                style: TextStyle(fontSize: 14.sp, color: AppColors.slate800),
                decoration: InputDecoration(
                  labelText: '¿A dónde vas?',
                  labelStyle: TextStyle(fontSize: 14.sp, color: AppColors.slate600),
                  prefixIcon: Icon(Icons.location_on, color: AppColors.danger, size: 20.r),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ),

            // Sugerencias
            if (_sugerencias.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: SizedBox(
                  height: 40.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sugerencias.length,
                    itemBuilder: (context, index) {
                      final sug = _sugerencias[index]['display_name'].toString().split(',')[0];
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ActionChip(
                          label: Text(
                            sug,
                            style: TextStyle(fontSize: 11.sp, color: AppColors.slate700),
                          ),
                          backgroundColor: AppColors.slate100,
                          padding: EdgeInsets.zero,
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

            // Error
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.danger, fontSize: 12.sp),
                ),
              ),

            SizedBox(height: 20.h),

            // Botón de buscar
            GestureDetector(
              onTap: _buscando ? null : _buscarRutaFinal,
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16.r,
                    ),
                  ],
                ),
                child: Center(
                  child: _buscando
                      ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, color: AppColors.white, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        'Ver Rutas Seguras',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}