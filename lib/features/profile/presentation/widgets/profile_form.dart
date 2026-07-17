import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'info_row.dart';
import 'profile_avatar.dart';
import 'profile_field.dart';
import 'stat_card.dart';

class ProfileForm extends StatefulWidget {
  final bool isEditing;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;

  const ProfileForm({
    super.key,
    required this.isEditing,
    required this.formKey,
    required this.nombreController,
    required this.emailController,
    required this.telefonoController,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    if (profile == null) return const SizedBox.shrink();

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          ProfileAvatar(
            tipo: profile.tipo,
            primaryColor: theme.colorScheme.primary,
          ),
          SizedBox(height: 10.h),
          Text(
            profile.nombre,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            profile.tipo.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Reportes',
                  value: profile.reportesCreados.toString(),
                  icon: Icons.add_location_alt_outlined,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: StatCard(
                  label: 'Confirmados',
                  value: profile.reportesConfirmados.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          ProfileField(
            label: 'Nombre Completo',
            controller: widget.nombreController,
            icon: Icons.person_outline,
            enabled: widget.isEditing,
          ),
          SizedBox(height: 16.h),
          ProfileField(
            label: 'Correo Electrónico',
            controller: widget.emailController,
            icon: Icons.email_outlined,
            enabled: widget.isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16.h),
          ProfileField(
            label: 'Teléfono',
            controller: widget.telefonoController,
            icon: Icons.phone_android_outlined,
            enabled: widget.isEditing,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 24.h),
          const Divider(),
          SizedBox(height: 16.h),
          InfoRow(label: 'Miembro desde', value: _formatDate(profile.createdAt)),
          InfoRow(label: 'Último acceso', value: _formatDate(profile.ultimoAcceso)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
