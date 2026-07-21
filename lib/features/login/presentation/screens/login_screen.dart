import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:saferoute_app/core/di/injection.dart';
import 'package:saferoute_app/core/security/security_service.dart';
import '../widgets/login_background.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Bloquear capturas al entrar al Login
    getIt<SecurityService>().setSecureMode(true);
  }

  @override
  void dispose() {
    // Desbloquear al salir (aunque si la app se cierra el flag se limpia)
    getIt<SecurityService>().setSecureMode(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const SafeArea(
        child: Stack(
          children: [
            LoginBackground(),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: _LoginContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400.w),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginHeader(),
          SizedBox(height: 32),
          LoginForm(),
        ],
      ),
    );
  }
}
