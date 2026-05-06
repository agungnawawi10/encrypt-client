// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:encryption_app/core/websocket_network.dart';
import 'package:encryption_app/core/speech_to_text.dart' as stt;
import 'package:encryption_app/core/theme.dart';
import 'package:encryption_app/features/encrypt_screen.dart';
import 'package:encryption_app/features/login_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encryption Chat',
      theme: AppTheme.lightTheme,
      home: const MyHomePage(title: 'Encryption Chat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController controller;
  String serverResponse = "";
  String senderName = "";
  String plaintextMessage = "";
  String encryptedMessage = "";
  bool isStreaming = false;
  Timer? debounceTimer;
  String? _username;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  void _handleLogin(String username) {
    setState(() {
      _username = username;
      _isLoggedIn = true;
    });
    _initializeWebSocket(username);
  }

  void _initializeWebSocket(String username) {
    // Initialize WebSocket connection
    wsService.connect(username: username);

    // Initialize speech recognition
    stt.initSpeech().then((success) {
      if (success) {
        print("Speech recognition initialized successfully");
      } else {
        print("Failed to initialize speech recognition");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Inisialisasi speech failed")));
      }
    });

    // Listen to WebSocket messages menggunakan messageStream
    wsService.messageStream.listen((jsonMessage) {
      setState(() {
        senderName = jsonMessage['sender'] ?? "Unknown";
        plaintextMessage = jsonMessage['plaintext'] ?? "";
        encryptedMessage = jsonMessage['encrypted'] ?? "";

        // Format response untuk ditampilkan
        serverResponse =
            "📤 From: $senderName\n"
            "📝 Plaintext: $plaintextMessage\n"
            "🔐 Encrypted: $encryptedMessage";
      });

      print("Message dari $senderName:");
      print("- Plaintext: $plaintextMessage");
      print("- Encrypted: $encryptedMessage");
    });
  }

  @override
  void dispose() {
    controller.dispose();
    debounceTimer?.cancel();
    wsService.webSocket?.sink.close();
    super.dispose();
  }

  void sendMessage() {
    String text = controller.text;
    if (text.isNotEmpty) {
      stt.sendMessage(text);
      if (!isStreaming) {
        controller.clear();
      }
    }
  }

  void toggleStreaming() {
    setState(() {
      isStreaming = !isStreaming;
    });
  }

  void onTextChanged(String value) {
    if (!isStreaming) return;

    // Cancel previous timer
    debounceTimer?.cancel();

    // Set new timer - send after 500ms of no typing
    debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (value.isNotEmpty) {
        stt.sendMessage(value);
        print("Streaming text: $value");
      }
    });
  }

  void sendMessageStreaming() {
    String text = controller.text;
    if (text.isNotEmpty) {
      stt.sendMessage(text);
      print("Streaming message: $text");
    }
  }

  void startSpeechToText() {
    stt
        .startListening()
        .then((_) {
          setState(() {});
        })
        .catchError((e) {
          print("Error starting speech: $e");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal memulai recording")));
        });
  }

  void stopSpeechToText() {
    stt.stopListening().then((_) {
      setState(() {
        if (stt.textResult.isNotEmpty) {
          controller.text = stt.textResult;
          // If streaming is on, send voice result
          if (isStreaming) {
            sendMessageStreaming();
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _handleLogin);
    }

    return EncryptScreen(
      controller: controller,
      serverResponse: serverResponse,
      currentUsername: _username ?? '',
      isStreaming: isStreaming,
      onSendMessage: sendMessage,
      onStartSpeech: startSpeechToText,
      onStopSpeech: stopSpeechToText,
      onToggleStreaming: toggleStreaming,
      onTextChanged: onTextChanged,
    );
  }
}
