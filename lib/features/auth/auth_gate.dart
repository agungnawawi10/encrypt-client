import 'package:flutter/material.dart';

import '../../core/session/session_manager.dart';
import '../../core/websocket_network.dart';
import '../chat/chat_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatefulWidget {
  final SessionManager sessionManager;

  const AuthGate({super.key, required this.sessionManager});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionManager,
      builder: (context, _) {
        if (widget.sessionManager.isBootstrapping ||
            (widget.sessionManager.status == SessionStatus.authenticating &&
                !widget.sessionManager.isAuthenticated)) {
          return _buildLoadingView(context);
        }

        if (widget.sessionManager.isAuthenticated) {
          return ChatScreen(sessionManager: widget.sessionManager);
        }

        if (_showRegister) {
          return RegisterScreen(
            sessionManager: widget.sessionManager,
            onSwitchToLogin: () {
              setState(() {
                _showRegister = false;
              });
            },
          );
        }

        return LoginScreen(
          sessionManager: widget.sessionManager,
          onSwitchToRegister: () {
            setState(() {
              _showRegister = true;
            });
          },
        );
      },
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final connectionState = widget.sessionManager.connectionState;
    final message = connectionState == WebSocketConnectionState.authenticating
        ? 'Memvalidasi session token...'
        : 'Menyiapkan koneksi...';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 44,
              width: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
