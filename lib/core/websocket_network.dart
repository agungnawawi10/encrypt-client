import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'config/app_config.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  authenticating,
  connected,
  reconnecting,
  rateLimited,
  authRequired,
  invalidToken,
  error,
}

enum WebSocketEventKind {
  authenticated,
  authRequired,
  invalidToken,
  rateLimited,
  join,
  left,
  message,
  raw,
  error,
}

class WebSocketEvent {
  final WebSocketEventKind kind;
  final String? sender;
  final String? plaintext;
  final String? encrypted;
  final String? message;
  final String? detail;
  final String? code;
  final Map<String, dynamic> raw;

  const WebSocketEvent({
    required this.kind,
    this.sender,
    this.plaintext,
    this.encrypted,
    this.message,
    this.detail,
    this.code,
    required this.raw,
  });

  bool isOwnMessage(String? currentUsername) {
    final senderValue = sender?.trim();
    final usernameValue = currentUsername?.trim();
    if (senderValue == null || senderValue.isEmpty) {
      return false;
    }
    if (usernameValue == null || usernameValue.isEmpty) {
      return false;
    }
    return senderValue.toLowerCase() == usernameValue.toLowerCase();
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  String? _token;
  String _username = 'Anonymous';
  bool _manualDisconnect = false;
  bool _authenticated = false;
  bool _joinSent = false;
  int _reconnectAttempt = 0;

  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<WebSocketConnectionState> get connectionStates =>
      _stateController.stream;
  WebSocketConnectionState get connectionState => _connectionState;
  bool get isAuthenticated => _authenticated;
  String get username => _username;

  Future<void> connect({String? token, String username = 'Anonymous'}) async {
    _token = token?.trim().isEmpty == true ? null : token?.trim();
    _username = username.trim().isEmpty ? 'Anonymous' : username.trim();
    _manualDisconnect = false;
    _authenticated = false;
    _joinSent = false;

    await _closeChannel();
    _setState(WebSocketConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(AppConfig.websocketUri);
      _subscription = _channel!.stream.listen(
        _handleIncomingData,
        onDone: _handleDisconnected,
        onError: _handleError,
      );

      if (_token != null) {
        _setState(WebSocketConnectionState.authenticating);
        _sendJson(<String, dynamic>{'type': 'authenticate', 'token': _token});
      } else {
        _authenticated = true;
        _setState(WebSocketConnectionState.connected);
        await join();
      }
    } catch (error) {
      _emitError(
        'Menghubungkan kembali.',
        raw: <String, dynamic>{'error': error.toString()},
      );
      _scheduleReconnect();
    }
  }

  Future<void> join() async {
    if (_joinSent || _channel == null) {
      return;
    }

    _joinSent = true;
    _sendJson(<String, dynamic>{'type': 'join'});
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (!_authenticated && _token != null) {
      _emitError(
        'Session belum siap. Tunggu autentikasi selesai.',
        code: 'auth_required',
      );
      return;
    }

    if (_channel == null) {
      _emitError('Koneksi websocket belum aktif.', code: 'disconnected');
      return;
    }

    _sendJson(<String, dynamic>{'type': 'message', 'message': trimmed});
  }

  Future<void> disconnect({bool permanent = true}) async {
    _manualDisconnect = permanent;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeChannel();
    _setState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _eventController.close();
    _stateController.close();
  }

  void _handleIncomingData(dynamic data) {
    final Map<String, dynamic>? payload = _decodePayload(data);
    if (payload == null) {
      _emitError('Menerima paket websocket yang tidak valid.');
      return;
    }

    final type = _readLowerCase(payload, const ['type', 'event']);
    final code = _readLowerCase(payload, const ['code', 'error_code']);
    final detail = _readString(payload, const [
      'message',
      'detail',
      'error',
      'description',
    ]);
    final sender = _readString(payload, const ['sender', 'username', 'from']);
    final plaintext = _readString(payload, const [
      'plaintext',
      'plain_text',
      'text',
    ]);
    final encrypted = _readString(payload, const [
      'encrypted',
      'ciphertext',
      'cipher_text',
    ]);
    final message = _readString(payload, const ['message']);

    switch (type) {
      case 'auth_ok':
      case 'authenticated':
        _authenticated = true;
        _joinSent = false;
        _setState(WebSocketConnectionState.connected);
        unawaited(join());
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.authenticated,
            detail: detail,
            code: code,
            raw: payload,
          ),
        );
        return;
      case 'auth_required':
        _authenticated = false;
        _setState(WebSocketConnectionState.authRequired);
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.authRequired,
            detail: detail ?? 'Autentikasi dibutuhkan sebelum mengirim pesan.',
            code: code,
            raw: payload,
          ),
        );
        _manualDisconnect = true;
        unawaited(_closeChannel());
        return;
      case 'invalid_token':
        _authenticated = false;
        _setState(WebSocketConnectionState.invalidToken);
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.invalidToken,
            detail: detail ?? 'Session token sudah tidak valid.',
            code: code,
            raw: payload,
          ),
        );
        _manualDisconnect = true;
        unawaited(_closeChannel());
        return;
      case 'rate_limited':
        _setState(WebSocketConnectionState.rateLimited);
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.rateLimited,
            detail: detail ?? 'Terlalu banyak request. Coba lagi nanti.',
            code: code,
            raw: payload,
          ),
        );
        return;
      case 'join':
      case 'user_joined':
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.join,
            sender: sender,
            detail: detail ?? sender ?? 'Seseorang bergabung',
            code: code,
            raw: payload,
          ),
        );
        return;
      case 'leave':
      case 'left':
      case 'disconnect':
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.left,
            sender: sender,
            detail: detail ?? sender ?? 'Seseorang keluar',
            code: code,
            raw: payload,
          ),
        );
        return;
      case 'message':
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.message,
            sender: sender,
            plaintext: plaintext ?? message,
            encrypted: encrypted,
            message: message,
            detail: detail,
            code: code,
            raw: payload,
          ),
        );
        return;
      default:
        _eventController.add(
          WebSocketEvent(
            kind: WebSocketEventKind.raw,
            sender: sender,
            plaintext: plaintext,
            encrypted: encrypted,
            message: message,
            detail: detail ?? type,
            code: code,
            raw: payload,
          ),
        );
    }
  }

  void _handleDisconnected() {
    _setState(WebSocketConnectionState.disconnected);
    _authenticated = false;

    if (_manualDisconnect) {
      return;
    }

    _scheduleReconnect();
  }

  void _handleError(Object error) {
    _setState(WebSocketConnectionState.error);
    _eventController.add(
      WebSocketEvent(
        kind: WebSocketEventKind.error,
        detail: 'Koneksi websocket mengalami gangguan.',
        code: 'socket_error',
        raw: <String, dynamic>{'error': error.toString()},
      ),
    );

    if (_manualDisconnect) {
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) {
      return;
    }

    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempt += 1;

    final delaySeconds = _reconnectAttempt < 4 ? _reconnectAttempt * 2 : 8;
    _setState(WebSocketConnectionState.reconnecting);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      unawaited(connect(token: token, username: _username));
    });
  }

  void _sendJson(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) {
      return;
    }

    channel.sink.add(jsonEncode(payload));
  }

  Future<void> _closeChannel() async {
    _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _setState(WebSocketConnectionState state) {
    _connectionState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _emitError(String detail, {String? code, Map<String, dynamic>? raw}) {
    _eventController.add(
      WebSocketEvent(
        kind: WebSocketEventKind.error,
        detail: detail,
        code: code,
        raw: raw ?? <String, dynamic>{},
      ),
    );
    _setState(WebSocketConnectionState.error);
  }

  Map<String, dynamic>? _decodePayload(dynamic data) {
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'type': 'raw', 'payload': decoded};
    } catch (_) {
      return null;
    }
  }

  String? _readLowerCase(Map<String, dynamic> payload, List<String> keys) {
    final value = _readString(payload, keys);
    if (value == null) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    for (final nestedKey in const ['data', 'result', 'payload']) {
      final nested = payload[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedValue = _readString(nested, keys);
        if (nestedValue != null) {
          return nestedValue;
        }
      }
    }

    return null;
  }
}

final wsService = WebSocketService();
