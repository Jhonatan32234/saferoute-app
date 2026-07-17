import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAvatar extends StatelessWidget {
  final String? tipo;
  final Color primaryColor;

  const ProfileAvatar({
    super.key,
    required this.tipo,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, size: 50.r, color: primaryColor),
        ),
        if (tipo == 'admin')
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified, size: 16.r, color: Colors.white),
          ),
      ],
    );
  }
}
