// lib/presentation/widgets/fake_gps_blocker.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/fake_gps_checker.dart';

class FakeGpsBlocker extends StatefulWidget {
  final Widget child;

  const FakeGpsBlocker({super.key, required this.child});

  @override
  State<FakeGpsBlocker> createState() => _FakeGpsBlockerState();
}

class _FakeGpsBlockerState extends State<FakeGpsBlocker> with WidgetsBindingObserver {
  bool _isBlocked = false;
  String _culpableInfo = "";
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFakeGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkFakeGps();
    }
  }

  Future<void> _checkFakeGps() async {
    if (!_isBlocked) setState(() => _checking = true);

    final result = await FakeGpsChecker.checkFakeGps();

    if (mounted) {
      setState(() {
        _isBlocked = result != "CLEAN";
        _culpableInfo = result;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking && !_isBlocked) {
      return Scaffold(
        backgroundColor: AppColors.slate50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40.r,
                height: 40.r,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 4.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Verificando integridad del GPS...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isBlocked) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.danger,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(32.r),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gpp_bad,
                        size: 100.r,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'ENTORNO NO SEGURO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildSecurityInfo(),
                      SizedBox(height: 32.h),
                      _buildRetryButton(),
                      SizedBox(height: 24.h),
                      GestureDetector(
                        onTap: () => SystemNavigator.pop(),  // ✅ Usar onTap
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                size: 20.r,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'SALIR DE LA APP',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'GPS Falso Detectado',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'SafeRoute ha detectado que se están utilizando coordenadas simuladas. Detalle técnico: $_culpableInfo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: _checkFakeGps,  // ✅ Usar onTap
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.white.withOpacity(0.3),
              blurRadius: 16.r,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 20.r, color: AppColors.danger),
            SizedBox(width: 8.w),
            Text(
              'REINTENTAR VERIFICACIÓN',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}