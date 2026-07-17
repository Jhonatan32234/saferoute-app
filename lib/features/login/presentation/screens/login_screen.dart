import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/login_background.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
