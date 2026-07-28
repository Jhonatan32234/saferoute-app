import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../login/presentation/providers/auth_provider.dart';
import '../../../login/presentation/screens/login_screen.dart';
import '../providers/profile_provider.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _isEditing = false;
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _profileProvider = context.read<ProfileProvider>();
    _profileProvider.addListener(_onProfileUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _profileProvider.cargarPerfil();
        if (_profileProvider.profile != null) {
          _fillFields(_profileProvider.profile!);
        }
      }
    });
  }

  void _onProfileUpdate() {
    if (!mounted || _isEditing) return;
    final profile = _profileProvider.profile;
    if (profile != null) {
      _fillFields(profile);
    }
  }

  void _fillFields(dynamic profile) {
    if (_nombreController.text != profile.nombre) _nombreController.text = profile.nombre;
    if (_emailController.text != profile.email) _emailController.text = profile.email;
    if (_telefonoController.text != profile.telefono) _telefonoController.text = profile.telefono;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_onProfileUpdate);
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _handleToggleEdit() {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        _profileProvider.actualizarPerfil(
          nombre: _nombreController.text,
          telefono: _telefonoController.text,
          email: _emailController.text,
        ).then((success) {
          if (success && mounted) {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil actualizado correctamente')),
            );
          }
        });
      }
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _handleToggleEdit,
          ),
        ],
      ),
      body: profileProvider.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => profileProvider.cargarPerfil(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20.r),
                child: Column(
                  children: [
                    ProfileForm(
                      isEditing: _isEditing,
                      formKey: _formKey,
                      nombreController: _nombreController,
                      emailController: _emailController,
                      telefonoController: _telefonoController,
                    ),
                    SizedBox(height: 40.h),
                    LogoutButton(onPressed: _handleLogout),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }
}
