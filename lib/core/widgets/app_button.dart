import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;
  final bool isOutlined;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
    this.isOutlined = false,
    this.width,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
    this.width,
  }) : isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    final minSize = Size(width?.w ?? 80.w, 48.h);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _buildChild(context, buttonColor),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: minSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 0,
      ),
      child: _buildChild(context, theme.colorScheme.onPrimary),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    final theme = Theme.of(context);
    if (isLoading) {
      return SizedBox(
        height: 20.r,
        width: 20.r,
        child: CircularProgressIndicator(
          strokeWidth: 2, 
          color: textColor,
        ),
      );
    }

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.r, color: textColor),
          SizedBox(width: 8.w),
          Text(label, style: textStyle),
        ],
      );
    }

    return Text(label, style: textStyle);
  }
}
