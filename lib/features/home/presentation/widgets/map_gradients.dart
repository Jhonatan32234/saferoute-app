import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapGradients extends StatelessWidget {
  const MapGradients({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Leve degradado superior para visibilidad del texto blanco/oscuro
        Positioned(
          top: 0, left: 0, right: 0, height: 120.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
