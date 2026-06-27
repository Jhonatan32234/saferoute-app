import 'package:flutter/material.dart';

class SemaforoIndicador extends StatelessWidget {
  final String seguridad;
  final double size;

  const SemaforoIndicador({
    super.key,
    required this.seguridad,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (seguridad) {
      case 'verde':
        color = Colors.green;
        break;
      case 'amarillo':
        color = Colors.orange;
        break;
      case 'rojo':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}