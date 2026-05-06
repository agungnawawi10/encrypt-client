// ignore_for_file: avoid_print

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class AppConfig {
  static const String serverName = "192.168.1.105";
  static const String wsUrl = "ws://$serverName:8765";
  static const String baseUrl = "http://$serverName:8000/api";
}

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  void connect({String username = "Anonymous"}) {
    // Inisialisasi di sini supaya bisa dipanggil ulang jika error
    _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
    _isConnected = true;

    // Send join message setelah connect
    _sendJoinMessage(username);

    _channel!.stream.listen(
      (data) {
        print("Data diterima: $data");
        try {
          final jsonData = jsonDecode(data.toString()) as Map<String, dynamic>;
          _messageController.add(jsonData);
        } catch (e) {
          print("Error parsing JSON: $e");
        }
      },
      onError: (error) {
        print("Koneksi Error: $error");
        _isConnected = false;
        // Tunggu 5 detik lalu coba hubungkan lagi
        Future.delayed(Duration(seconds: 5), () => connect(username: username));
      },
      onDone: () {
        print("Koneksi ditutup, mencoba hubungkan kembali...");
        _isConnected = false;
        Future.delayed(Duration(seconds: 5), () => connect(username: username));
      },
    );
  }

  void _sendJoinMessage(String username) {
    final joinMessage = jsonEncode({"type": "join", "username": username});
    _channel?.sink.add(joinMessage);
    print("Join message sent: $joinMessage");
  }

  void sendMessage(String msg) {
    if (!_isConnected) {
      print("WebSocket not connected");
      return;
    }
    final messagePayload = jsonEncode({"type": "message", "message": msg});
    _channel?.sink.add(messagePayload);
    print("Message sent: $messagePayload");
  }

  WebSocketChannel? get webSocket => _channel;

  void dispose() {
    _messageController.close();
    _channel?.sink.close();
  }
}

// Global instance
final wsService = WebSocketService();
