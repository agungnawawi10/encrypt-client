import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_session.dart';

class AuthFailure implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AuthFailure(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'AuthFailure($statusCode, $code): $message';
}

class AuthService {
  const AuthService();

  Future<AppSession> login({
    required String username,
    required String password,
  }) {
    return _authenticate(
      path: '/login',
      username: username,
      password: password,
    );
  }

  Future<void> register({required String username, required String password}) {
    return _authenticateWithoutToken(
      path: '/register',
      username: username,
      password: password,
    );
  }

  Future<AppSession> _authenticate({
    required String path,
    required String username,
    required String password,
  }) async {
    final uri = AppConfig.authBaseUri.resolve(path);
    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final dynamic payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure(
        _extractErrorMessage(payload) ??
            'Autentikasi gagal (${response.statusCode}).',
        statusCode: response.statusCode,
        code: _extractErrorCode(payload),
      );
    }

    final token = _extractToken(payload);
    if (token == null || token.isEmpty) {
      throw const AuthFailure('Server tidak mengembalikan session token.');
    }

    final returnedUsername = _extractUsername(payload) ?? username;
    return AppSession(
      token: token,
      username: returnedUsername,
      authenticatedAt: DateTime.now(),
    );
  }

  Future<void> _authenticateWithoutToken({
    required String path,
    required String username,
    required String password,
  }) async {
    final uri = AppConfig.authBaseUri.resolve(path);
    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final dynamic payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure(
        _extractErrorMessage(payload) ??
            'Autentikasi gagal (${response.statusCode}).',
        statusCode: response.statusCode,
        code: _extractErrorCode(payload),
      );
    }
  }

  dynamic _decodePayload(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractToken(dynamic payload) {
    return _extractStringValue(payload, const [
      'token',
      'session_token',
      'access_token',
    ]);
  }

  String? _extractUsername(dynamic payload) {
    return _extractStringValue(payload, const ['username', 'user', 'account']);
  }

  String? _extractErrorMessage(dynamic payload) {
    return _extractStringValue(payload, const [
      'message',
      'detail',
      'error',
      'description',
    ]);
  }

  String? _extractErrorCode(dynamic payload) {
    return _extractStringValue(payload, const ['code', 'error_code', 'type']);
  }

  String? _extractStringValue(dynamic payload, List<String> keys) {
    if (payload is Map<String, dynamic>) {
      for (final key in keys) {
        final value = payload[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }

      for (final nestedKey in ['data', 'result', 'payload']) {
        final nestedValue = _extractStringValue(payload[nestedKey], keys);
        if (nestedValue != null) {
          return nestedValue;
        }
      }
    }

    return null;
  }
}
