import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_session.dart';

class SecureStorageHelper {
  static const String _tokenKey = 'chat_session_token';
  static const String _usernameKey = 'chat_session_username';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveSession({
    required String token,
    required String username,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<AppSession?> readSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    final username = await _storage.read(key: _usernameKey) ?? '';
    return AppSession(
      token: token,
      username: username,
      authenticatedAt: DateTime.now(),
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
