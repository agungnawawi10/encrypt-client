import 'package:flutter/material.dart';

import '../../core/session/session_manager.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  final SessionManager sessionManager;
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({
    super.key,
    required this.sessionManager,
    required this.onSwitchToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await widget.sessionManager.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AnimatedBuilder(
                  animation: widget.sessionManager,
                  builder: (context, _) {
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 44,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Buat Akun',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Akun baru akan langsung mendapat session token dari auth server.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              if (widget.sessionManager.successMessage != null)
                                _SuccessBanner(
                                  message:
                                      widget.sessionManager.successMessage!,
                                  onDismiss: widget.sessionManager.clearSuccess,
                                ),
                              if (widget.sessionManager.successMessage != null)
                                const SizedBox(height: 16),
                              if (widget.sessionManager.errorMessage != null)
                                _ErrorBanner(
                                  message: widget.sessionManager.errorMessage!,
                                  onDismiss: widget.sessionManager.clearError,
                                ),
                              if (widget.sessionManager.errorMessage != null)
                                const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                enabled: !widget.sessionManager.isBusy,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !widget.sessionManager.isBusy,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.key_outlined),
                                  suffixIcon: IconButton(
                                    onPressed: widget.sessionManager.isBusy
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !widget.sessionManager.isBusy,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Password',
                                  prefixIcon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: widget.sessionManager.isBusy
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Konfirmasi password wajib diisi';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Password tidak sama';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: widget.sessionManager.isBusy
                                      ? null
                                      : _submit,
                                  child: widget.sessionManager.isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text('Register'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: widget.sessionManager.isBusy
                                    ? null
                                    : widget.onSwitchToLogin,
                                child: Text(
                                  'Sudah punya akun? Login',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.errorColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.error_outline, color: AppTheme.errorColor),
        title: Text(
          message,
          style: const TextStyle(color: AppTheme.errorColor),
        ),
        trailing: IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close),
          color: AppTheme.errorColor,
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _SuccessBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.successColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.check_circle_outline,
          color: AppTheme.successColor,
        ),
        title: Text(
          message,
          style: const TextStyle(color: AppTheme.successColor),
        ),
        trailing: IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close),
          color: AppTheme.successColor,
        ),
      ),
    );
  }
}
