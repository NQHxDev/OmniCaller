import '../../features/chat/data/services/chat_websocket_service.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/services/auth_api_service.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class UserProfile {
  final String id;
  final String username;
  final String displayName;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
    );
  }
}

class AuthController extends ChangeNotifier {
  final IAuthApiService _authService;
  final ITokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  String? _errorMessage;

  AuthController({
    IAuthApiService? authService,
    ITokenStorage? tokenStorage,
  })  : _authService = authService ?? AuthApiService(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage() {
    ApiClient.globalOnUnauthorized = () {
      if (isAuthenticated) {
        refreshTokens().then((refreshed) {
          if (!refreshed) {
            logout();
          }
        });
      }
    };
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitializing => _status == AuthStatus.initial;
  UserProfile? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get token => _accessToken; // Backwards compatibility getter
  String? get errorMessage => _errorMessage;

  /// Loads saved session from EncryptedSharedPreferences / Secure Storage
  /// and immediately validates / refreshes the session with Server
  Future<void> initialize() async {
    _status = AuthStatus.initial;
    notifyListeners();

    try {
      final session = await _tokenStorage.loadSession();
      if (session != null && session.refreshToken.isNotEmpty) {
        try {
          // Immediately validate token against Server upon app startup
          final refreshed = await _authService.refreshToken(session.refreshToken);
          _currentUser = UserProfile(
            id: session.userId,
            username: session.username,
            displayName: session.displayName,
          );
          _accessToken = refreshed.accessToken;
          _refreshToken = refreshed.refreshToken;

          await _tokenStorage.saveSession(
            userId: session.userId,
            username: session.username,
            displayName: session.displayName,
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken,
          );
          _status = AuthStatus.authenticated;
        } catch (e) {
          // Session invalid, revoked, or expired on Server -> Auto logout immediately on startup
          await _tokenStorage.clear();
          _currentUser = null;
          _accessToken = null;
          _refreshToken = null;
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> refreshTokens() async {
    final currentRefresh = _refreshToken;
    if (currentRefresh == null || currentRefresh.isEmpty) {
      await logout();
      return false;
    }

    try {
      final refreshed = await _authService.refreshToken(currentRefresh);
      _accessToken = refreshed.accessToken;
      _refreshToken = refreshed.refreshToken;

      if (_currentUser != null) {
        await _tokenStorage.saveSession(
          userId: _currentUser!.id,
          username: _currentUser!.username,
          displayName: _currentUser!.displayName,
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
        );
      }
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final authResult = await _authService.login(
        username: username,
        password: password,
      );

      _currentUser = UserProfile(
        id: authResult.userId,
        username: authResult.username,
        displayName: authResult.displayName,
      );
      _accessToken = authResult.accessToken;
      _refreshToken = authResult.refreshToken;

      await _tokenStorage.saveSession(
        userId: authResult.userId,
        username: authResult.username,
        displayName: authResult.displayName,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    try {
      final authResult = await _authService.register(
        displayName: displayName,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );

      _currentUser = UserProfile(
        id: authResult.userId,
        username: authResult.username,
        displayName: authResult.displayName,
      );
      _accessToken = authResult.accessToken;
      _refreshToken = authResult.refreshToken;

      await _tokenStorage.saveSession(
        userId: authResult.userId,
        username: authResult.username,
        displayName: authResult.displayName,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    final tokenToRevoke = _accessToken;

    if (tokenToRevoke != null && tokenToRevoke.isNotEmpty) {
      try {
        await _authService.logout(tokenToRevoke);
      } catch (_) {
        // Continue clearing local data even if network logout fails
      }
    }

    try {
      ChatWebSocketService().disconnect();
    } catch (_) {}

    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _errorMessage = null;
    await _tokenStorage.clear();
    notifyListeners();
  }
}
