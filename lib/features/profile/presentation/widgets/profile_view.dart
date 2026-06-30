import 'package:flutter/material.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_validators.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/shared_widgets.dart';
import '../../../home/presentation/bloc/home_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.authState,
    required this.homeState,
    required this.profileFormKey,
    required this.passwordFormKey,
    required this.usernameController,
    required this.emailController,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.onUpdateProfile,
    required this.onChangePassword,
  });

  final AuthState authState;
  final HomeState homeState;
  final GlobalKey<FormState> profileFormKey;
  final GlobalKey<FormState> passwordFormKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final VoidCallback onUpdateProfile;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final profile = homeState.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hồ sơ', style: Theme.of(context).textTheme.headlineSmall),
        if (profile?.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Tạo lúc ${formatDateTime(profile!.createdAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Form(
          key: profileFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên hiển thị';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: homeState.isMutating ? null : onUpdateProfile,
                  icon: homeState.isMutating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Cập nhật hồ sơ'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Bảo mật', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: passwordFormKey,
          child: Column(
            children: [
              PasswordField(
                controller: oldPasswordController,
                labelText: 'Mật khẩu cũ',
                prefixIcon: Icons.lock_clock_outlined,
                textInputAction: TextInputAction.next,
                validator: validatePassword,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: newPasswordController,
                labelText: 'Mật khẩu mới',
                prefixIcon: Icons.lock_reset_outlined,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onChangePassword(),
                validator: validatePassword,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: authState.isChangingPassword
                      ? null
                      : onChangePassword,
                  icon: authState.isChangingPassword
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('Đổi mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
