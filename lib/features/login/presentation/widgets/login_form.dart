import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _recordarDatos = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
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
    await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      recordar: _recordarDatos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 40.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Iniciar sesión',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Ingresa tus credenciales',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
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
            AppTextField(
              controller: _passwordController,
              label: 'Contraseña',
              prefixIcon: Icons.lock_outlined,
              isPassword: !_showPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20.r,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _RecordarDatosCheckbox(
              value: _recordarDatos,
              onChanged: (val) => setState(() => _recordarDatos = val),
            ),
            SizedBox(height: 24.h),
            if (auth.error != null) _ErrorMessage(message: auth.error!),
            if (auth.error != null) SizedBox(height: 16.h),
            AppButton(
              label: 'Entrar',
              onPressed: auth.isLoading ? null : _login,
              isLoading: auth.isLoading,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordarDatosCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RecordarDatosCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 24.r,
          height: 24.r,
          child: Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'Recordar mis datos',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
