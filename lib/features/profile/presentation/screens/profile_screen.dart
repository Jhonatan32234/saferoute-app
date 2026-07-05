import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../login/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../login/presentation/screens/login_screen.dart'; // Importado para redirección

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
    
    // Guardamos referencia al provider y escuchamos cambios
    _profileProvider = context.read<ProfileProvider>();
    _profileProvider.addListener(_onProfileUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Consultar datos frescos inmediatamente al entrar
      _profileProvider.cargarPerfil();
      
      // 2. Poblar campos si ya hay algo en el provider (caché)
      if (_profileProvider.profile != null) {
        _fillFields(_profileProvider.profile!);
      }
    });
  }

  // Se llama cuando el provider notifica cambios (ej. cuando cargarPerfil termina)
  void _onProfileUpdate() {
    if (!mounted || _isEditing) return;
    final profile = _profileProvider.profile;
    if (profile != null) {
      _fillFields(profile);
    }
  }

  void _fillFields(dynamic profile) {
    // Actualizamos solo si el texto es distinto para no perder el foco o cursor
    if (_nombreController.text != profile.nombre) _nombreController.text = profile.nombre;
    if (_emailController.text != profile.email) _emailController.text = profile.email;
    if (_telefonoController.text != profile.telefono) _telefonoController.text = profile.telefono;
    // Forzamos un rebuild para actualizar el resto de la UI (estadísticas, etc)
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Es vital remover el listener para evitar fugas de memoria y errores
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
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
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
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Icon(Icons.person, size: 50.r, color: AppColors.primary),
                          ),
                          if (profile?.tipo == 'admin')
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified, size: 16.r, color: Colors.white),
                            ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        profile?.nombre ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      Text(
                        profile?.tipo.toUpperCase() ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      // Estadísticas
                      if (profile != null)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Reportes',
                                profile.reportesCreados.toString(),
                                Icons.add_location_alt_outlined,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatCard(
                                'Confirmados',
                                profile.reportesConfirmados.toString(),
                                Icons.check_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      
                      SizedBox(height: 24.h),
                      _buildField(
                        label: 'Nombre Completo',
                        controller: _nombreController,
                        icon: Icons.person_outline,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: 'Correo Electrónico',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
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
                        _buildInfoRow('Miembro desde', _formatDate(profile.createdAt)),
                        _buildInfoRow('Último acceso', _formatDate(profile.ultimoAcceso)),
                      ],
                      SizedBox(height: 40.h),
                      ElevatedButton(
                        onPressed: () async {
                          // Cerrar sesión en el provider
                          await context.read<AuthProvider>().logout();
                          if (mounted) {
                            // Limpiar toda la pila de navegación y volver al LoginScreen
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.danger,
                          minimumSize: Size(double.infinity, 50.h),
                          elevation: 0,
                          side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24.r),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp, color: AppColors.slate800),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.r, color: AppColors.slate400),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.slate100.withOpacity(0.5),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.slate200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.slate100),
            ),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.slate500, fontSize: 13.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: AppColors.slate800)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
