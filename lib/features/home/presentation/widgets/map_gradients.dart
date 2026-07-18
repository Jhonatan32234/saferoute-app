import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapGradients extends StatelessWidget {
  const MapGradients({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0, height: 100.h, // Reducido de 140 a 100
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor.withOpacity(0.6), Colors.transparent], // Más sutil
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, height: 120.h, // Reducido
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bgColor.withOpacity(0.5), Colors.transparent], // Más sutil
              ),
            ),
          ),
        ),
      ],
    );
  }
}
