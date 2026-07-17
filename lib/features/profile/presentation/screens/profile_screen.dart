import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../login/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  bool _isEditing = false;
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    
    _profileProvider = context.read<ProfileProvider>();
    _profileProvider.addListener(_onProfileUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileProvider.cargarPerfil();
      if (_profileProvider.profile != null) {
        _fillFields(_profileProvider.profile!);
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

  void _toggleEdit() {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        context.read<ProfileProvider>().actualizarPerfil(
          nombre: _nombreController.text,
          telefono: _telefonoController.text,
          email: _emailController.text,
        ).then((success) {
          if (success) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEdit,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _ProfileAvatar(
                        profile: profile,
                        primaryColor: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        profile?.nombre ?? 'Usuario',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile?.tipo.toUpperCase() ?? '',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      if (profile != null)
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Reportes',
                                value: profile.reportesCreados.toString(),
                                icon: Icons.add_location_alt_outlined,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _StatCard(
                                label: 'Confirmados',
                                value: profile.reportesConfirmados.toString(),
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      
                      SizedBox(height: 24.h),
                      _ProfileField(
                        label: 'Nombre Completo',
                        controller: _nombreController,
                        icon: Icons.person_outline,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 16.h),
                      _ProfileField(
                        label: 'Correo Electrónico',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      _ProfileField(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        icon: Icons.phone_android_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 24.h),
                      if (profile != null) ...[
                        const Divider(),
                        SizedBox(height: 16.h),
                        _InfoRow(label: 'Miembro desde', value: _formatDate(profile.createdAt)),
                        _InfoRow(label: 'Último acceso', value: _formatDate(profile.ultimoAcceso)),
                      ],
                      SizedBox(height: 40.h),
                      _LogoutButton(onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _ProfileAvatar extends StatelessWidget {
  final dynamic profile;
  final Color primaryColor;

  const _ProfileAvatar({required this.profile, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, size: 50.r, color: primaryColor),
        ),
        if (profile?.tipo == 'admin')
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified, size: 16.r, color: Colors.white),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24.r),
          SizedBox(height: 8.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.r),
            filled: true,
            fillColor: enabled ? theme.colorScheme.surface : theme.disabledColor.withOpacity(0.05),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.error,
        minimumSize: Size(double.infinity, 50.h),
        elevation: 0,
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
