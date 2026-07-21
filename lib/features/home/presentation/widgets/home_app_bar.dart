import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../login/presentation/providers/auth_provider.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const HomeAppBar({super.key, required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo y Texto (Sin fondo, igual al Figma)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icono.png', width: 22.r, height: 22.r, 
                  errorBuilder: (_,__,___) => const Icon(Icons.shield, color: Color(0xFF2563EB))),
              SizedBox(width: 10.w),
              Text(
                'SAFEROUTE',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        // Botones flotantes a la derecha
        _CircularButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: true,
          onTap: onNotificationsTap,
        ),
        SizedBox(width: 10.w),
        _CircularButton(
          icon: Icons.logout_rounded,
          iconColor: const Color(0xFFEF4444),
          onTap: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircularButton({
    required this.icon,
    this.hasBadge = false,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 24.r),
            if (hasBadge)
              Positioned(
                top: 10.r,
                right: 10.r,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
