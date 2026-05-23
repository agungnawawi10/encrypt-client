import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../models/app_session.dart';
import '../storage/secure_storage_helper.dart';
import '../websocket_network.dart';

enum SessionStatus { unknown, unauthenticated, authenticating, authenticated }

class SessionManager extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageHelper _storage;
  final WebSocketService _socketService;

  AppSession? _session;
  SessionStatus _status = SessionStatus.unknown;
  bool _busy = false;
  bool _bootstrapping = true;
  String? _errorMessage;
  String? _successMessage;
  StreamSubscription<WebSocketEvent>? _eventSubscription;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  SessionManager({
    AuthService? authService,
    SecureStorageHelper? storage,
    WebSocketService? socketService,
  }) : _authService = authService ?? const AuthService(),
       _storage = storage ?? SecureStorageHelper(),
       _socketService = socketService ?? wsService {
    _bindSocketListeners();
  }

  bool get isBootstrapping => _bootstrapping;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == SessionStatus.authenticated;
  SessionStatus get status => _status;
  String? get username => _session?.username;
  String? get token => _session?.token;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  WebSocketConnectionState get connectionState =>
      _socketService.connectionState;
  Stream<WebSocketEvent> get events => _socketService.events;

  Future<void> bootstrap() async {
    _bootstrapping = true;
    _errorMessage = null;
    notifyListeners();

    _session = await _storage.readSession();
    if (_session == null) {
      _status = SessionStatus.unauthenticated;
      _bootstrapping = false;
      notifyListeners();
      return;
    }

    _status = SessionStatus.authenticated;
    _bootstrapping = false;
    notifyListeners();

    await _connectSocketForSession(_session!);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await _authenticate(flow: 'login', username: username, password: password);
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    await _authenticate(
      flow: 'register',
      username: username,
      password: password,
    );
  }

  Future<void> logout() async {
    _busy = false;
    _errorMessage = null;
    _successMessage = null;
    _session = null;
    _status = SessionStatus.unauthenticated;

    await _socketService.disconnect(permanent: true);
    await _storage.clearSession();

    notifyListeners();
  }

  Future<void> clearLocalSession({String? message}) async {
    _busy = false;
    _errorMessage = message;
    _successMessage = null;
    _session = null;
    _status = SessionStatus.unauthenticated;

    await _socketService.disconnect(permanent: true);
    await _storage.clearSession();

    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    await _socketService.sendMessage(message);
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    if (_successMessage == null) {
      return;
    }

    _successMessage = null;
    notifyListeners();
  }

  Future<void> _authenticate({
    required String flow,
    required String username,
    required String password,
  }) async {
    _busy = true;
    _status = SessionStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      if (flow == 'register') {
        await _authService.register(username: username, password: password);

        _status = SessionStatus.unauthenticated;
        _successMessage = 'Akun berhasil dibuat. Silakan login.';
        _errorMessage = null;
        return;
      }

      final session = await _authService.login(
        username: username,
        password: password,
      );

      _session = session;
      _status = SessionStatus.authenticated;
      await _storage.saveSession(
        token: session.token,
        username: session.username,
      );
      await _connectSocketForSession(session);
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      _status = SessionStatus.unauthenticated;
    } catch (_) {
      _errorMessage =
          'Gagal memproses login atau registrasi. Coba lagi sebentar.';
      _status = SessionStatus.unauthenticated;
    } finally {
      _busy = false;
      _bootstrapping = false;
      notifyListeners();
    }
  }

  void _bindSocketListeners() {
    _eventSubscription = _socketService.events.listen(_handleSocketEvent);
    _connectionSubscription = _socketService.connectionStates.listen(
      (_) => notifyListeners(),
    );
  }

  void _handleSocketEvent(WebSocketEvent event) {
    switch (event.kind) {
      case WebSocketEventKind.authenticated:
        _status = SessionStatus.authenticated;
        _errorMessage = null;
        _busy = false;
        notifyListeners();
        break;
      case WebSocketEventKind.invalidToken:
      case WebSocketEventKind.authRequired:
        unawaited(
          clearLocalSession(
            message:
                event.detail ?? 'Sesi sudah tidak valid. Silakan login lagi.',
          ),
        );
        break;
      case WebSocketEventKind.rateLimited:
        _errorMessage =
            event.detail ?? 'Terlalu banyak permintaan. Coba lagi nanti.';
        notifyListeners();
        break;
      default:
        break;
    }
  }

  Future<void> _connectSocketForSession(AppSession session) async {
    try {
      await _socketService.connect(
        token: session.token,
        username: session.username,
      );
    } catch (_) {
      _errorMessage =
          'Login berhasil, tetapi koneksi chat belum tersambung. App akan mencoba reconnect otomatis.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _connectionSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}
