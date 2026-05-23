import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _hostOverride = String.fromEnvironment(
    'CHAT_BACKEND_HOST',
    defaultValue: '',
  );
  static const bool useSecureScheme =
    bool.fromEnvironment('CHAT_USE_SECURE_SCHEME', defaultValue: false);

  static String get host {
    if (_hostOverride.isNotEmpty) {
      return _hostOverride;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }

  static String get httpScheme => useSecureScheme ? 'https' : 'http';
  static String get wsScheme => useSecureScheme ? 'wss' : 'ws';

  static Uri get authBaseUri {
    final envUrl = dotenv.env['CHAT_AUTH_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return Uri.parse(envUrl);
    }
    return Uri.parse('$httpScheme://$host:8000');
  }

  static Uri get websocketUri {
    final envUrl = dotenv.env['CHAT_WS_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return Uri.parse(envUrl);
    }
    return Uri.parse('$wsScheme://$host:8765');
  }
}
