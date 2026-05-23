// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:encryption_app/core/models/app_session.dart';
import 'package:encryption_app/core/session/session_manager.dart';
import 'package:encryption_app/core/storage/secure_storage_helper.dart';
import 'package:encryption_app/main.dart';

class _FakeSecureStorageHelper extends SecureStorageHelper {
  @override
  Future<void> clearSession() async {}

  @override
  Future<AppSession?> readSession() async => null;

  @override
  Future<void> saveSession({
    required String token,
    required String username,
  }) async {}
}

void main() {
  testWidgets('renders the login shell', (WidgetTester tester) async {
    final sessionManager = SessionManager(storage: _FakeSecureStorageHelper());
    addTearDown(sessionManager.dispose);

    await sessionManager.bootstrap();
    await tester.pumpWidget(MyApp(sessionManager: sessionManager));
    await tester.pump();

    expect(find.text('Masuk ke Chat'), findsOneWidget);
  });
}
