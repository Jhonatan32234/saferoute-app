import 'package:flutter/material.dart';

class BarraReportesWidget extends StatelessWidget {
  final Function(String tipo) onTipoSeleccionado;

  const BarraReportesWidget({super.key, required this.onTipoSeleccionado});

  static const _tipos = [
    {'tipo': 'accidente', 'icono': Icons.car_crash, 'label': 'Accidente', 'color': Colors.red},
    {'tipo': 'inundacion', 'icono': Icons.water, 'label': 'Inundación', 'color': Colors.blue},
    {'tipo': 'bache', 'icono': Icons.dangerous, 'label': 'Bache', 'color': Colors.orange},
    {'tipo': 'derrumbe', 'icono': Icons.landslide, 'label': 'Derrumbe', 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _tipos.map((tipo) => GestureDetector(
          onTap: () => onTipoSeleccionado(tipo['tipo'] as String),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tipo['icono'] as IconData, color: tipo['color'] as Color, size: 35),
              const SizedBox(height: 4),
              Text(tipo['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
