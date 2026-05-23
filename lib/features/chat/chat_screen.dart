import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_manager.dart';
import '../../core/theme.dart';
import '../../core/websocket_network.dart';

class ChatEntry {
  final String title;
  final String subtitle;
  final String? sender;
  final String? plaintext;
  final bool isOwnMessage;
  final bool isSystem;
  final DateTime timestamp;

  const ChatEntry({
    required this.title,
    required this.subtitle,
    this.sender,
    this.plaintext,
    required this.isOwnMessage,
    required this.isSystem,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final SessionManager sessionManager;

  const ChatScreen({super.key, required this.sessionManager});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<ChatEntry> _messages = [];
  StreamSubscription<WebSocketEvent>? _eventSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _eventSubscription = widget.sessionManager.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleEvent(WebSocketEvent event) {
    if (!mounted) {
      return;
    }

    switch (event.kind) {
      case WebSocketEventKind.message:
        _appendMessage(
          ChatEntry(
            title: event.sender ?? 'Server',
            subtitle: _formatPayload(event),
            sender: event.sender,
            plaintext: event.plaintext,
            isOwnMessage: event.isOwnMessage(widget.sessionManager.username),
            isSystem: false,
            timestamp: DateTime.now(),
          ),
        );
        break;
      case WebSocketEventKind.join:
      case WebSocketEventKind.left:
        _appendMessage(
          ChatEntry(
            title: event.detail ?? _friendlyTitle(event.kind),
            subtitle: event.detail ?? _friendlyTitle(event.kind),
            isOwnMessage: false,
            isSystem: true,
            timestamp: DateTime.now(),
          ),
        );
        break;
      case WebSocketEventKind.authRequired:
      case WebSocketEventKind.invalidToken:
      case WebSocketEventKind.rateLimited:
      case WebSocketEventKind.raw:
      case WebSocketEventKind.error:
        if (event.detail != null && event.detail!.isNotEmpty) {
          _appendMessage(
            ChatEntry(
              title: 'Sistem',
              subtitle: event.detail!,
              isOwnMessage: false,
              isSystem: true,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;
      case WebSocketEventKind.authenticated:
        break;
    }
  }

  void _appendMessage(ChatEntry entry) {
    setState(() {
      _messages.add(entry);
    });
    _scrollToBottom();
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    await widget.sessionManager.sendMessage(text);
  }

  String _friendlyTitle(WebSocketEventKind kind) {
    switch (kind) {
      case WebSocketEventKind.join:
        return 'Pengguna bergabung';
      case WebSocketEventKind.left:
        return 'Pengguna keluar';
      default:
        return 'Sistem';
    }
  }

  String _formatPayload(WebSocketEvent event) {
    return event.plaintext ?? event.message ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionManager,
      builder: (context, _) {
        final connectionState = widget.sessionManager.connectionState;
        final username = widget.sessionManager.username ?? 'anonymous';

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Encryption Chat'),
                Text(username, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            actions: [
              _ConnectionChip(state: connectionState),
              IconButton(
                onPressed: widget.sessionManager.isBusy
                    ? null
                    : widget.sessionManager.logout,
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Column(
            children: [
              if (widget.sessionManager.errorMessage != null)
                _StatusBanner(
                  message: widget.sessionManager.errorMessage!,
                  tone: _bannerTone(widget.sessionManager.connectionState),
                  onDismiss: widget.sessionManager.clearError,
                ),
              Expanded(
                child: _messages.isEmpty
                    ? _EmptyState(
                        connectionState: connectionState,
                        username: username,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _MessageBubble(entry: _messages[index]);
                        },
                      ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            AppTheme.accentColor,
                          ),
                        ),
                        onPressed: widget.sessionManager.isAuthenticated
                            ? _send
                            : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _BannerTone _bannerTone(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.rateLimited:
        return _BannerTone.warning;
      case WebSocketConnectionState.invalidToken:
      case WebSocketConnectionState.authRequired:
        return _BannerTone.error;
      default:
        return _BannerTone.info;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final String username;

  const _EmptyState({required this.connectionState, required this.username});

  @override
  Widget build(BuildContext context) {
    final label = switch (connectionState) {
      WebSocketConnectionState.connected => 'Siap mengirim pesan',
      WebSocketConnectionState.authenticating =>
        'Memverifikasi session token...',
      WebSocketConnectionState.reconnecting => 'Menyambung ulang...',
      WebSocketConnectionState.rateLimited => 'Terlalu banyak permintaan',
      WebSocketConnectionState.invalidToken => 'Session tidak valid',
      WebSocketConnectionState.authRequired => 'Autentikasi dibutuhkan',
      WebSocketConnectionState.error => 'Koneksi bermasalah',
      WebSocketConnectionState.connecting => 'Menyambung ke server...',
      WebSocketConnectionState.disconnected => 'Terputus dari server',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 56,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Halo, $username',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatEntry entry;

  const _MessageBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                entry.subtitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ),
      );
    }

    final alignment = entry.isOwnMessage
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final bubbleColor = entry.isOwnMessage
        ? AppTheme.accentColor
        : Colors.white;

    final textColor = entry.isOwnMessage ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.sender ?? entry.title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _MessageLine(
                label: '',
                value: entry.plaintext ?? entry.subtitle,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MessageLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.isEmpty ? value : '$label: $value',
      style: TextStyle(color: color, height: 1.35),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final WebSocketConnectionState state;

  const _ConnectionChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      WebSocketConnectionState.connected => 'Connected',
      WebSocketConnectionState.authenticating => 'Auth',
      WebSocketConnectionState.connecting => 'Connecting',
      WebSocketConnectionState.reconnecting => 'Reconnecting',
      WebSocketConnectionState.rateLimited => 'Rate limited',
      WebSocketConnectionState.invalidToken => 'Token invalid',
      WebSocketConnectionState.authRequired => 'Auth required',
      WebSocketConnectionState.error => 'Error',
      WebSocketConnectionState.disconnected => 'Offline',
    };

    final color = switch (state) {
      WebSocketConnectionState.connected => AppTheme.successColor,
      WebSocketConnectionState.authenticating => AppTheme.warningColor,
      WebSocketConnectionState.connecting => AppTheme.textSecondary,
      WebSocketConnectionState.reconnecting => AppTheme.warningColor,
      WebSocketConnectionState.rateLimited => AppTheme.warningColor,
      WebSocketConnectionState.invalidToken => AppTheme.errorColor,
      WebSocketConnectionState.authRequired => AppTheme.errorColor,
      WebSocketConnectionState.error => AppTheme.errorColor,
      WebSocketConnectionState.disconnected => AppTheme.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(color: color, fontSize: 12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        backgroundColor: color.withValues(alpha: 0.08),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

enum _BannerTone { info, warning, error }

class _StatusBanner extends StatelessWidget {
  final String message;
  final _BannerTone tone;
  final VoidCallback onDismiss;

  const _StatusBanner({
    required this.message,
    required this.tone,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _BannerTone.info => AppTheme.accentColor,
      _BannerTone.warning => AppTheme.warningColor,
      _BannerTone.error => AppTheme.errorColor,
    };

    return Material(
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.info_outline, color: color),
        title: Text(message, style: TextStyle(color: color)),
        trailing: IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close),
          color: color,
        ),
      ),
    );
  }
}
