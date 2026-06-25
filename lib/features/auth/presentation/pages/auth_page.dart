import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_validators.dart';
import '../widgets/password_field.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AuthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isLogin) {
        await widget.controller.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _showMessage('Đăng nhập thành công');
      } else {
        final message = await widget.controller.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _showMessage(message);
        setState(() => _isLogin = true);
      }
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Không thể kết nối máy chủ');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Đăng nhập' : 'Đăng ký';
    final actionText = _isLogin ? 'Đăng nhập' : 'Tạo tài khoản';
    final isSubmitting = widget.controller.isSubmitting;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      labelText: 'Mật khẩu',
                      prefixIcon: Icons.lock_outline,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isSubmitting ? null : _submit,
                      icon: isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(actionText),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Chưa có tài khoản? Đăng ký'
                            : 'Đã có tài khoản? Đăng nhập',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
