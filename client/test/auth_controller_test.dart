import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_exception.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthApiService implements IAuthApiService {
  bool shouldFail = false;
  bool shouldFailRefresh = false;
  String? loggedOutToken;

  @override
  Future<AuthResponseDto> login({
    required String username,
    required String password,
  }) async {
    if (shouldFail) {
      throw const ApiException(message: 'Invalid username or password', statusCode: 401);
    }
    return AuthResponseDto(
      userId: 'usr_fake_1',
      username: username,
      displayName: 'Fake $username',
      accessToken: 'access_jwt_123',
      refreshToken: 'refresh_jwt_123',
    );
  }

  @override
  Future<AuthResponseDto> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    if (shouldFail) {
      throw const ApiException(message: 'Username already exists', statusCode: 409);
    }
    return AuthResponseDto(
      userId: 'usr_fake_2',
      username: username,
      displayName: displayName,
      accessToken: 'access_jwt_456',
      refreshToken: 'refresh_jwt_456',
    );
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    if (shouldFailRefresh || shouldFail) {
      throw const ApiException(message: 'Invalid or expired refresh token', statusCode: 401);
    }
    return const RefreshTokenResponseDto(
      accessToken: 'refreshed_access_jwt',
      refreshToken: 'refreshed_refresh_jwt',
    );
  }

  @override
  Future<void> logout(String token) async {
    loggedOutToken = token;
  }
}

class FakeTokenStorage implements ITokenStorage {
  AuthSessionData? storedSession;

  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {
    storedSession = AuthSessionData(
      userId: userId,
      username: username,
      displayName: displayName,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    return storedSession;
  }

  @override
  Future<String?> getAccessToken() async {
    return storedSession?.accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return storedSession?.refreshToken;
  }

  @override
  Future<void> clear() async {
    storedSession = null;
  }
}

void main() {
  group('AuthController Tests', () {
    late FakeAuthApiService fakeService;
    late FakeTokenStorage fakeStorage;
    late AuthController controller;

    setUp(() {
      fakeService = FakeAuthApiService();
      fakeStorage = FakeTokenStorage();
      controller = AuthController(
        authService: fakeService,
        tokenStorage: fakeStorage,
      );
    });

    test('initial state is unauthenticated before initialization', () {
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(controller.accessToken, null);
    });

    test('initialize loads existing session and refreshes/validates token from server', () async {
      await fakeStorage.saveSession(
        userId: 'usr_saved',
        username: 'saved_user',
        displayName: 'Saved User',
        accessToken: 'saved_access_token',
        refreshToken: 'saved_refresh_token',
      );

      await controller.initialize();

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.id, 'usr_saved');
      expect(controller.currentUser?.username, 'saved_user');
      expect(controller.accessToken, 'refreshed_access_jwt');
      expect(controller.refreshToken, 'refreshed_refresh_jwt');
    });

    test('initialize clears storage and unauthenticates when session is invalid on server', () async {
      await fakeStorage.saveSession(
        userId: 'usr_saved',
        username: 'saved_user',
        displayName: 'Saved User',
        accessToken: 'expired_access_token',
        refreshToken: 'expired_refresh_token',
      );

      fakeService.shouldFailRefresh = true;

      await controller.initialize();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(controller.accessToken, null);
      expect(fakeStorage.storedSession, null);
    });

    test('login saves session into encrypted storage and updates state', () async {
      final success = await controller.login(
        username: 'testuser',
        password: 'password123',
      );

      expect(success, true);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.id, 'usr_fake_1');
      expect(controller.currentUser?.username, 'testuser');
      expect(controller.accessToken, 'access_jwt_123');
      expect(controller.refreshToken, 'refresh_jwt_123');

      // Verify stored in storage
      expect(fakeStorage.storedSession?.accessToken, 'access_jwt_123');
      expect(fakeStorage.storedSession?.userId, 'usr_fake_1');
    });

    test('login sets unauthenticated state and rethrows on failure', () async {
      fakeService.shouldFail = true;

      expect(
        () => controller.login(
          username: 'wronguser',
          password: 'wrongpassword',
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(fakeStorage.storedSession, null);
    });

    test('register saves session to encrypted storage and updates state', () async {
      final success = await controller.register(
        displayName: 'Test Person',
        username: 'testperson',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(success, true);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.displayName, 'Test Person');
      expect(controller.currentUser?.username, 'testperson');
      expect(fakeStorage.storedSession?.displayName, 'Test Person');
      expect(fakeStorage.storedSession?.accessToken, 'access_jwt_456');
    });

    test('logout calls server API, clears encrypted storage and resets state', () async {
      await controller.login(
        username: 'testuser',
        password: 'password123',
      );
      expect(controller.isAuthenticated, true);
      expect(fakeStorage.storedSession, isNotNull);

      await controller.logout();

      expect(fakeService.loggedOutToken, 'access_jwt_123');
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(controller.accessToken, null);
      expect(controller.refreshToken, null);
      expect(fakeStorage.storedSession, isNull);
    });

    test('global 401 triggers refresh tokens seamlessly', () async {
      await controller.login(
        username: 'testuser',
        password: 'password123',
      );
      expect(controller.isAuthenticated, true);
      expect(controller.accessToken, 'access_jwt_123');

      // Trigger 401 callback when refresh token succeeds
      ApiClient.globalOnUnauthorized?.call();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Should remain authenticated with refreshed token
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.accessToken, 'refreshed_access_jwt');
    });

    test('global 401 triggers logout when refresh token fails', () async {
      await controller.login(
        username: 'testuser',
        password: 'password123',
      );
      expect(controller.isAuthenticated, true);

      fakeService.shouldFailRefresh = true;

      // Trigger 401 callback when refresh token fails
      ApiClient.globalOnUnauthorized?.call();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
    });
  });
}
