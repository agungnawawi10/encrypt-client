import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

SpeechToText speech = SpeechToText();
bool isListening = false;
String textResult = '';

typedef MessageSender = FutureOr<void> Function(String text);

MessageSender? _messageSender;

void setMessageSender(MessageSender? sender) {
  _messageSender = sender;
}

Future<bool> initSpeech() async {
  try {
    final status = await Permission.microphone.request();

    if (status.isDenied) {
      return false;
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    final available = await speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return available;
  } catch (e) {
    return false;
  }
}

Future<void> startListening() async {
  if (!speech.isAvailable) {
    return;
  }

  try {
    isListening = true;
    textResult = '';

    await speech.listen(
      onResult: (result) {
        textResult = result.recognizedWords;
      },
    );
  } catch (e) {
    isListening = false;
  }
}

Future<void> stopListening() async {
  try {
    await speech.stop();
    isListening = false;
  } catch (e) {
    isListening = false;
  }
}

Future<void> sendMessage(String text) async {
  final sender = _messageSender;
  if (sender == null) {
    return;
  }

  await sender(text);
}
