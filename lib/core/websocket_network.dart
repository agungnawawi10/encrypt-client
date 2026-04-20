// ignore_for_file: avoid_print

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class AppConfig {
  static const String serverName = "192.168.1.103";
  static const String wsUrl = "ws://$serverName:8765";
  static const String baseUrl = "http://$serverName:8000/api";
}

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  Stream<String> get messageStream => _messageController.stream;

  void connect() {
    // Inisialisasi di sini supaya bisa dipanggil ulang jika error
    _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));

    _channel!.stream.listen(
      (data) {
        print("Data diterima: $data");
        _messageController.add(data.toString());
      },
      onError: (error) {
        print("Koneksi Error: $error");
        // Tunggu 5 detik lalu coba hubungkan lagi
        Future.delayed(Duration(seconds: 5), () => connect());
      },
      onDone: () {
        print("Koneksi ditutup, mencoba hubungkan kembali...");
        Future.delayed(Duration(seconds: 5), () => connect());
      },
    );
  }

  void sendMessage(String msg) {
    _channel?.sink.add(msg);
  }

  WebSocketChannel? get webSocket => _channel;

  void dispose() {
    _messageController.close();
    _channel?.sink.close();
  }
}

// Global instance
final wsService = WebSocketService();