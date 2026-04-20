import 'package:encryption_app/core/speech_to_text.dart' as stt;
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
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text("Encryption Chat"),
          ],
        ),
        centerTitle: false,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(context, messages[index]);
                    },
                  ),
          ),
          // Divider
          Divider(height: 1),
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
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            "Mulai Percakapan",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Ketik pesan atau gunakan voice untuk mulai",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.smart_toy, size: 18, color: Colors.grey[700]),
            ),
          if (!message.isUser) SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.orange.shade500
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.shade500,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streaming Mode Indicator
            if (widget.isStreaming)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Streaming Mode ON",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: widget.onToggleStreaming,
                        child: Text(
                          "Matikan",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Input Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
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
                      decoration: InputDecoration(
                        hintText: "Ketik pesan...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Microphone Button
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: Icon(
                        stt.isListening ? Icons.stop : Icons.mic,
                        color: stt.isListening ? Colors.red : Colors.grey[600],
                      ),
                      onPressed: stt.isListening
                          ? widget.onStopSpeech
                          : widget.onStartSpeech,
                      tooltip: stt.isListening
                          ? "Hentikan Rekam"
                          : "Mulai Rekam",
                    ),
                  ),
                  // Send Button
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.orange),
                      onPressed: _sendMessage,
                      tooltip: "Kirim Pesan",
                    ),
                  ),
                ],
              ),
            ),
            // Toggle Streaming Button
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: widget.onToggleStreaming,
                icon: Icon(
                  widget.isStreaming ? Icons.stream : Icons.stop,
                  size: 16,
                ),
                label: Text(
                  widget.isStreaming ? "Streaming: ON" : "Streaming: OFF",
                  style: TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: widget.isStreaming
                      ? Colors.green
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
