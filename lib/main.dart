import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/session/session_manager.dart';
import 'core/theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final sessionManager = SessionManager();
  await sessionManager.bootstrap();

  runApp(
    DevicePreview(
      enabled: false,
      tools: const [...DevicePreview.defaultTools],
      builder: (context) => MyApp(sessionManager: sessionManager),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SessionManager sessionManager;

  const MyApp({super.key, required this.sessionManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encryption Chat',
      theme: AppTheme.lightTheme,
      home: AuthGate(sessionManager: sessionManager),
      debugShowCheckedModeBanner: false,
      builder: DevicePreview.appBuilder,
    );
  }
}
