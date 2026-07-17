import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login/presentation/providers/auth_provider.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/mapa_provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool online;
  final VoidCallback onNotificationsTap;

  const HomeAppBar({
    super.key,
    required this.online,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final mapaProvider = context.watch<MapaProvider>();
    final notiProvider = context.watch<NotificacionProvider>();

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.88),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LogoIcon(),
          SizedBox(width: 8.w),
          Text(
            'SafeRoute',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.18,
            ),
          ),
          SizedBox(width: 8.w),
          _OnlineStatusDot(online: online),
        ],
      ),
      actions: [
        _AppBarAction(
          icon: Icons.notifications_outlined,
          onTap: onNotificationsTap,
          badgeCount: notiProvider.sinLeer,
        ),
        SizedBox(width: 8.w),
        _AppBarAction(
          icon: Icons.person_outline,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
        ),
        SizedBox(width: 8.w),
        _AppBarAction(
          icon: Icons.logout,
          onTap: () async {
            if (mapaProvider.enViaje) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Finaliza el viaje activo antes de cerrar sesión'),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            await auth.logout();
          },
          color: mapaProvider.enViaje ? theme.disabledColor : theme.colorScheme.onSurface,
        ),
        SizedBox(width: 12.w),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28.r,
      height: 28.r,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4.r,
          ),
        ],
      ),
      padding: EdgeInsets.all(2.r),
      child: Image.asset(
        'assets/saferoute_blue_nof.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shield,
          color: theme.colorScheme.primary,
          size: 20.r,
        ),
      ),
    );
  }
}

class _OnlineStatusDot extends StatelessWidget {
  final bool online;
  const _OnlineStatusDot({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.r,
      height: 8.r,
      decoration: BoxDecoration(
        color: online ? AppColors.success : AppColors.danger,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? color;

  const _AppBarAction({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 18.r,
              color: color ?? theme.colorScheme.onSurface,
            ),
            if (badgeCount > 0)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5.r,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
