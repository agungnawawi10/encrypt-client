import 'package:encryption_app/core/websocket_network.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

SpeechToText speech = SpeechToText();
bool isListening = false;
String textResult = "";

Future<bool> initSpeech() async {
  try {
    // Request microphone permission
    final status = await Permission.microphone.request();

    if (status.isDenied) {
      print("Microphone permission denied");
      return false;
    }

    if (status.isPermanentlyDenied) {
      print("Microphone permission permanently denied");
      openAppSettings();
      return false;
    }

    final available = await speech.initialize(
      onError: (error) {
        print("Speech init error: $error");
      },
      onStatus: (status) {
        print("Speech status: $status");
      },
    );
    print("Speech initialized: $available");
    return available;
  } catch (e) {
    print("Error initializing speech: $e");
    return false;
  }
}

Future<void> startListening() async {
  if (!speech.isAvailable) {
    print("Speech recognition not available");
    return;
  }

  try {
    isListening = true;
    textResult = "";

    await speech.listen(
      onResult: (result) {
        textResult = result.recognizedWords;
        print("Recognized: ${result.recognizedWords}");
      },
    );
  } catch (e) {
    print("Error starting listening: $e");
    isListening = false;
  }
}

Future<void> stopListening() async {
  try {
    await speech.stop();
    isListening = false;
  } catch (e) {
    print("Error stopping listening: $e");
  }
}

void sendMessage(String text) {
  wsService.webSocket?.sink.add(text);
}
