import 'package:flutter/material.dart';

class BarraReportesWidget extends StatelessWidget {
  final Function(String tipo) onTipoSeleccionado;

  const BarraReportesWidget({super.key, required this.onTipoSeleccionado});

  static const _tipos = [
    {'tipo': 'accidente', 'icono': Icons.car_crash, 'label': 'Accidente', 'color': Colors.red},
    {'tipo': 'inundacion', 'icono': Icons.water, 'label': 'Inundación', 'color': Colors.blue},
    {'tipo': 'bache', 'icono': Icons.dangerous, 'label': 'Bache', 'color': Colors.orange},
    {'tipo': 'derrumbe', 'icono': Icons.landslide, 'label': 'Derrumbe', 'color': Colors.brown},
    {'tipo': 'bloqueo', 'icono': Icons.block, 'label': 'Bloqueo', 'color': Colors.redAccent},
    {'tipo': 'niebla', 'icono': Icons.foggy, 'label': 'Niebla', 'color': Colors.grey},
    {'tipo': 'sin_luz', 'icono': Icons.lightbulb_outline, 'label': 'Sin luz', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Incrementado un poco para mejor respiro visual
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _tipos.map((tipo) => Padding(
              padding: const EdgeInsets.only(right: 20), // Espaciado consistente entre elementos
              child: GestureDetector(
                onTap: () => onTipoSeleccionado(tipo['tipo'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (tipo['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tipo['icono'] as IconData, 
                        color: tipo['color'] as Color, 
                        size: 28
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tipo['label'] as String,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 10,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
