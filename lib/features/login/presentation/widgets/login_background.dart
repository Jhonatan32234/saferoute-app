import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEEF6FF),
                Color(0xFFF0FDF4),
              ],
            ),
          ),
        ),
        Positioned(
          top: -60.h,
          right: -60.w,
          child: Container(
            width: 240.r,
            height: 240.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB).withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -50.h,
          left: -50.w,
          child: Container(
            width: 200.r,
            height: 200.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF16A34A).withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }
}
