import 'package:encryption_app/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/session/session_manager.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  final SessionManager sessionManager;
  final VoidCallback onSwitchToRegister;

  const LoginScreen({
    super.key,
    required this.sessionManager,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Memicu browser/OS untuk menyimpan kredensial secara aman jika login sukses
    TextInput.finishAutofillContext();

    await widget.sessionManager.login(
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
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                'assets/icon/icon_encrypt.png',
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Masuk ke Chat',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Session token akan disimpan secara aman dan dipakai ulang saat app dibuka kembali.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              if (widget.sessionManager.errorMessage != null) ...[
                                _ErrorBanner(
                                  message: widget.sessionManager.errorMessage!,
                                  onDismiss: widget.sessionManager.clearError,
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _usernameController,
                                enabled: !widget.sessionManager.isBusy,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [AutofillHints.username],
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
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
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
                                      : const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: widget.sessionManager.isBusy
                                    ? null
                                    : widget.onSwitchToRegister,
                                child: Text(
                                  'Belum punya akun? Daftar',
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