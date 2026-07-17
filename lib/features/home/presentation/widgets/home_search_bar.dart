import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 24.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: theme.colorScheme.primary,
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '¿A dónde vas?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.hintColor,
                ),
              ),
            ),
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.navigation,
                color: theme.colorScheme.primary,
                size: 16.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
