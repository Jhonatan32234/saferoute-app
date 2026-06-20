import 'package:flutter/material.dart';

class RutaCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final String seguridad;
  final double distanciaKm;
  final int tiempoMinutos;
  final double riesgoCombinado;
  final VoidCallback onSelect;

  const RutaCard({
    super.key,
    required this.nombre,
    required this.tipo,
    required this.seguridad,
    required this.distanciaKm,
    required this.tiempoMinutos,
    required this.riesgoCombinado,
    required this.onSelect,
  });

  Color get _color {
    switch (seguridad) {
      case 'verde': return Colors.green;
      case 'amarillo': return Colors.orange;
      case 'rojo': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral de color
              Container(width: 5, color: _color),
              const SizedBox(width: 10),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${distanciaKm.toStringAsFixed(1)} km · ${tiempoMinutos} min',
                        style: TextStyle(color: Colors.grey[700], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón de acción con ancho fijo para prevenir el error de layout
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 50,
                  height: 30,
                  child: TextButton(
                    onPressed: onSelect,
                    style: TextButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Ir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
