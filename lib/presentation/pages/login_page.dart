import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _recordarDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarCredencialesGuardadas();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.route,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SafeRoute',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema de Predicción de Riesgos Viales\npara Flotas en Chiapas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu email';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock_outlined,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  
                  // Nuevo Checkbox para recordar datos
                  CheckboxListTile(
                    value: _recordarDatos,
                    onChanged: (val) => setState(() => _recordarDatos = val ?? false),
                    title: const Text('Recordar mis datos', style: TextStyle(fontSize: 14)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),

                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  AppButton(
                    label: 'Iniciar Sesión',
                    onPressed: auth.isLoading ? null : _login,
                    isLoading: auth.isLoading,
                    icon: Icons.login,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
