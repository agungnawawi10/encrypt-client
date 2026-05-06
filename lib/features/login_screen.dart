import 'package:flutter/material.dart';
import 'package:encryption_app/core/theme.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onLogin;

  const LoginScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    String username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Username tidak boleh kosong")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate connection delay
    Future.delayed(Duration(milliseconds: 500), () {
      widget.onLogin(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encryption Chat"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  "Encryption Chat",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Masukkan username untuk memulai percakapan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Username Input
                TextField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: "Masukkan username",
                    prefixIcon: const Icon(Icons.person_outline),
                    prefixIconColor: AppTheme.textSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => !_isLoading ? _handleLogin() : null,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      disabledBackgroundColor: AppTheme.borderColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "Masuk ke Chat",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
