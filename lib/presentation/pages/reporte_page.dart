import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';

class ReportePage extends StatefulWidget {
  const ReportePage({super.key});

  @override
  State<ReportePage> createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {
  String? _tipoSeleccionado;
  bool _enviando = false;

  final _tiposIncidente = [
    {'tipo': 'accidente', 'icono': Icons.car_crash, 'label': 'Accidente', 'color': Colors.red},
    {'tipo': 'inundacion', 'icono': Icons.water, 'label': 'Inundación', 'color': Colors.blue},
    {'tipo': 'bache', 'icono': Icons.dangerous, 'label': 'Bache', 'color': Colors.orange},
    {'tipo': 'derrumbe', 'icono': Icons.landslide, 'label': 'Derrumbe', 'color': Colors.brown},
    {'tipo': 'sin_luz', 'icono': Icons.lightbulb_outline, 'label': 'Sin luz', 'color': Colors.purple},
    {'tipo': 'otro', 'icono': Icons.help_outline, 'label': 'Otro', 'color': Colors.grey},
  ];

  Future<void> _enviarReporte() async {
    if (_tipoSeleccionado == null) return;

    setState(() => _enviando = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final auth = context.read<AuthProvider>();
      await auth.api.crearReporte(
        tipo: _tipoSeleccionado!,
        latitud: position.latitude,
        longitud: position.longitude,
        notaVoz: _tipoSeleccionado!,
        rutaId: 'ruta-actual',
        token: auth.token!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte enviado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Incidente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Qué ves?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona el tipo de incidente',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Grid de opciones
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _tiposIncidente.length,
                itemBuilder: (_, index) {
                  final tipo = _tiposIncidente[index];
                  final isSelected = _tipoSeleccionado == tipo['tipo'];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _tipoSeleccionado = tipo['tipo'] as String);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (tipo['color'] as Color).withOpacity(0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (tipo['color'] as Color)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tipo['icono'] as IconData,
                            size: 36,
                            color: tipo['color'] as Color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tipo['label'] as String,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? (tipo['color'] as Color) : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Botón enviar
            AppButton(
              label: _tipoSeleccionado != null
                  ? 'Reportar ${_tipoSeleccionado!.replaceAll('_', ' ')}'
                  : 'Selecciona un tipo',
              onPressed: _tipoSeleccionado != null && !_enviando ? _enviarReporte : null,
              isLoading: _enviando,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }
}