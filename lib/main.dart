// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:encryption_app/core/websocket_network.dart';
import 'package:encryption_app/core/speech_to_text.dart' as stt;
import 'package:encryption_app/features/encrypt_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  bool isStreaming = false;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    // Initialize WebSocket connection
    wsService.connect();

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
    wsService.messageStream.listen((message) {
      setState(() {
        serverResponse = message;
      });

      print("Encrypted dari server: $message");
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
    return EncryptScreen(
      controller: controller,
      serverResponse: serverResponse,
      isStreaming: isStreaming,
      onSendMessage: sendMessage,
      onStartSpeech: startSpeechToText,
      onStopSpeech: stopSpeechToText,
      onToggleStreaming: toggleStreaming,
      onTextChanged: onTextChanged,
    );
  }
}
