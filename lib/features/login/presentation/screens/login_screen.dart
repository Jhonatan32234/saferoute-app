import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Imports hacia el core de la aplicación
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

// Import hacia el provider del mismo feature
import '../providers/auth_provider.dart';

import '../../../home/presentation/screens//main_screen.dart';

class LoginScreen extends StatefulWidget { // Renombrado a Screen
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _recordarDatos = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Agendamos la carga para después del primer render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCredencialesGuardadas();
    });
  }

  Future<void> _cargarCredencialesGuardadas() async {
    final auth = context.read<AuthProvider>();
    final creds = await auth.getCredencialesGuardadas();
    if (creds['email'] != null && creds['password'] != null) {
      setState(() {
        _emailController.text = creds['email']!;
        _passwordController.text = creds['password']!;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      recordar: _recordarDatos,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo con gradiente personalizado
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEEF6FF), // Azul muy claro (arriba)
                    Color(0xFFF0FDF4), // Verde muy claro (abajo)
                  ],
                ),
              ),
            ),
            // Círculo azul decorativo (esquina superior derecha)
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
            // Círculo verde decorativo (esquina inferior izquierda)
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
            // Contenido
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo Cuadrado
                        Center(
                          child: Container(
                            width: 90.r,
                            height: 90.r,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F87BF),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20.r,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(12.r),
                            child: Image.asset(
                              'assets/saferoute_white_nof.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'SafeRoute',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Sistema de Predicción de Riesgos Viales para flotas en Chiapas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate500,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // Card de login
                        Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: AppColors.slate200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 40.r,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate800,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Ingresa tus credenciales',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.slate400,
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Email
                              AppTextField(
                                controller: _emailController,
                                label: 'Correo electrónico',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingresa tu email';
                                  if (!v.contains('@')) return 'Email inválido';
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),

                              // Password
                              AppTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                prefixIcon: Icons.lock_outlined,
                                isPassword: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 20.r,
                                    color: AppColors.slate400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                  if (v.length < 6) return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),

                              SizedBox(height: 16.h),

                              // Recordar datos
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24.r,
                                    height: 24.r,
                                    child: Checkbox(
                                      value: _recordarDatos,
                                      onChanged: (val) =>
                                          setState(() => _recordarDatos = val ?? false),
                                      activeColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Recordar mis datos',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 24.h),

                              // Error
                              if (auth.error != null)
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: AppColors.danger.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.danger,
                                        size: 20.r,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          auth.error!,
                                          style: TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (auth.error != null) SizedBox(height: 16.h),

                              // Botón de login
                              GestureDetector(
                                onTap: auth.isLoading ? null : _login,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3F87BF),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: auth.isLoading
                                      ? SizedBox(
                                    width: 24.r,
                                    height: 24.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                      : Text(
                                    'Entrar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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