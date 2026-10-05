import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionData {
  final String userId;
  final String username;
  final String displayName;
  final String accessToken;
  final String refreshToken;

  const AuthSessionData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.accessToken,
    required this.refreshToken,
  });
}

abstract class ITokenStorage {
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  });

  Future<AuthSessionData?> loadSession();

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clear();
}

class SecureTokenStorage implements ITokenStorage {
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUsername = 'auth_username';
  static const String _keyDisplayName = 'auth_display_name';
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUsername, value: username),
      _storage.write(key: _keyDisplayName, value: displayName),
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    final values = await Future.wait([
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUsername),
      _storage.read(key: _keyDisplayName),
      _storage.read(key: _keyAccessToken),
      _storage.read(key: _keyRefreshToken),
    ]);

    final userId = values[0];
    final username = values[1];
    final displayName = values[2];
    final accessToken = values[3];
    final refreshToken = values[4];

    if (accessToken != null && accessToken.isNotEmpty && userId != null) {
      return AuthSessionData(
        userId: userId,
        username: username ?? '',
        displayName: displayName ?? '',
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
    }

    return null;
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUsername),
      _storage.delete(key: _keyDisplayName),
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }
}
