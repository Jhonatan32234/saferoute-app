import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../login/presentation/providers/auth_provider.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../providers/mapa_provider.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const HomeAppBar({super.key, required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapaProvider = context.watch<MapaProvider>();
    final notiProvider = context.watch<NotificacionProvider>();
    final bool enViaje = mapaProvider.enViaje;

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/saferoute_blue_nof.png',
                width: 18.r,
                height: 18.r,
                fit: BoxFit.contain,
                errorBuilder: (_,__,___) => Icon(Icons.shield, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 10.w),
              Text(
                'SAFEROUTE',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        _CircularButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: notiProvider.sinLeer > 0,
          onTap: onNotificationsTap,
        ),
        SizedBox(width: 10.w),
        _CircularButton(
          icon: Icons.logout_rounded,
          iconColor: enViaje ? theme.disabledColor : theme.colorScheme.error,
          onTap: enViaje 
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Debes finalizar el viaje antes de cerrar sesión'),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
              } 
            : () => context.read<AuthProvider>().logout(),
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: iconColor ?? theme.colorScheme.onSurfaceVariant, size: 24.r),
            if (hasBadge)
              Positioned(
                top: 10.r,
                right: 10.r,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
