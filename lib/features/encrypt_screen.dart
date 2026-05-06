import 'package:encryption_app/core/speech_to_text.dart' as stt;
import 'package:encryption_app/core/theme.dart';
import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class EncryptScreen extends StatefulWidget {
  final TextEditingController controller;
  final String serverResponse;
  final String currentUsername;
  final bool isStreaming;
  final VoidCallback onSendMessage;
  final VoidCallback onStartSpeech;
  final VoidCallback onStopSpeech;
  final VoidCallback onToggleStreaming;
  final Function(String) onTextChanged;

  const EncryptScreen({
    Key? key,
    required this.controller,
    required this.serverResponse,
    required this.currentUsername,
    required this.isStreaming,
    required this.onSendMessage,
    required this.onStartSpeech,
    required this.onStopSpeech,
    required this.onToggleStreaming,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  late ScrollController _scrollController;
  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(EncryptScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tambah server response ke chat
    if (widget.serverResponse.isNotEmpty &&
        (messages.isEmpty ||
            messages.last.text != widget.serverResponse ||
            messages.last.isUser)) {
      final responseLines = widget.serverResponse.split('\n');
      final senderLine = responseLines.isNotEmpty ? responseLines.first : '';
      final sender = senderLine.startsWith('📤 From: ')
          ? senderLine.replaceFirst('📤 From: ', '').trim()
          : '';

      if (sender.isNotEmpty && sender != widget.currentUsername) {
        setState(() {
          messages.add(
            ChatMessage(
              text: widget.serverResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (widget.controller.text.isNotEmpty) {
      setState(() {
        messages.add(
          ChatMessage(
            text: widget.controller.text,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );
      });
      widget.onSendMessage();
      widget.controller.clear();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encryption Chat"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : Container(
                    color: AppTheme.backgroundColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(context, messages[index]);
                      },
                    ),
                  ),
          ),
          // Divider
          Container(height: 1, color: AppTheme.borderColor),
          // Input Area
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Mulai Percakapan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ketik pesan atau gunakan voice untuk memulai",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.accentColor
                    : AppTheme.lightGray,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(message.isUser ? 12 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 12),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streaming Mode Indicator
            if (widget.isStreaming)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    border: Border.all(color: AppTheme.successColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Mode Streaming Aktif",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onToggleStreaming,
                        child: const Text(
                          "Matikan",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Input Field with Actions
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      onChanged: widget.onTextChanged,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: "Ketik pesan...",
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Microphone Button
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: Icon(
                        stt.isListening ? Icons.stop : Icons.mic,
                        color: stt.isListening
                            ? AppTheme.errorColor
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: stt.isListening
                          ? widget.onStopSpeech
                          : widget.onStartSpeech,
                      tooltip: stt.isListening ? "Stop" : "Microphone",
                    ),
                  ),
                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      onPressed: () {
                        _sendMessage();
                      },
                      tooltip: "Kirim",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Toggle Streaming Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: widget.onToggleStreaming,
                icon: Icon(
                  widget.isStreaming ? Icons.stream : Icons.stop_circle,
                  size: 16,
                ),
                label: Text(
                  widget.isStreaming
                      ? "Streaming Mode: ON"
                      : "Streaming Mode: OFF",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: widget.isStreaming
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
