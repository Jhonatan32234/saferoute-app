import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/ruta_card.dart';

class RutasPage extends StatefulWidget {
  const RutasPage({super.key});

  @override
  State<RutasPage> createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  final _destinoController = TextEditingController();
  List<dynamic> _rutas = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _destinoController.dispose();
    super.dispose();
  }

  // Función de diagnóstico para ver qué está pasando
  void _status(String message) {
    debugPrint(">>> STATUS: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _buscarRutas() async {
    if (_destinoController.text.trim().isEmpty) {
      _status("Por favor, ingresa un destino");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _rutas = [];
    });

    try {
      _status("Iniciando búsqueda...");

      // 1. Verificar GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El GPS está apagado. Actívalo en tu celular.');
      }

      // 2. Permisos
      _status("Verificando permisos...");
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        _status("Solicitando permiso...");
        // Pequeña pausa para asegurar que la UI esté lista (ayuda en Samsung)
        await Future.delayed(const Duration(milliseconds: 500));
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos bloqueados permanentemente. Actívalos en Ajustes.');
      }

      // 3. Obtener Posición
      _status("Obteniendo coordenadas...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final auth = context.read<AuthProvider>();

      // 4. API
      _status("Consultando servidor...");
      final response = await auth.api.getRutas(
        origenLat: position.latitude,
        origenLon: position.longitude,
        destinoLat: 16.75, // Suchiapa
        destinoLon: -93.12,
        token: auth.token!,
      );

      setState(() {
        _rutas = response;
        _loading = false;
        if (_rutas.isEmpty) {
          _error = "No se encontraron rutas disponibles.";
        }
      });
      _status("¡Rutas cargadas!");

    } catch (e) {
      debugPrint("ERROR EN _buscarRutas: $e");
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      _status("Error: $_error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Ruta Segura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _destinoController,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Definimos un tamaño fijo para el botón para evitar errores de diseño
                SizedBox(
                  width: 100,
                  height: 50,
                  child: AppButton(
                    label: 'Buscar',
                    onPressed: _loading ? null : _buscarRutas,
                    isLoading: _loading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const Divider(),

            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _rutas.isEmpty
                  ? const Center(child: Text('Introduce un destino y busca'))
                  : ListView.builder(
                      itemCount: _rutas.length,
                      itemBuilder: (context, index) {
                        final ruta = _rutas[index];
                        return RutaCard(
                          nombre: ruta['nombre'] ?? 'Ruta',
                          tipo: ruta['tipo'] ?? 'estandar',
                          seguridad: ruta['seguridad'] ?? 'verde',
                          distanciaKm: (ruta['distancia_km'] ?? 0.0).toDouble(),
                          tiempoMinutos: (ruta['tiempo_minutos'] ?? 0).toInt(),
                          riesgoCombinado: (ruta['riesgo_combinado'] ?? 0.0).toDouble(),
                          onSelect: () => _mostrarDetalle(ruta),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(dynamic ruta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seleccionaste: ${ruta['nombre']}')),
    );
  }
}
