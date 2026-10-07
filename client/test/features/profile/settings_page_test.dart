import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/theme_controller.dart';
import 'package:client/core/theme/theme_scope.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/profile/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DummyAuthApiService implements IAuthApiService {
  @override
  Future<AuthResponseDto> login({required String username, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String token) async {}

  @override
  Future<AuthResponseDto> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    return const RefreshTokenResponseDto(
      accessToken: 'dummy_access_token',
      refreshToken: 'dummy_refresh_token',
    );
  }
}

class DummyTokenStorage implements ITokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<AuthSessionData?> loadSession() async => null;
  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {}
}

void main() {
  testWidgets('SettingsPage displays dark theme switch and toggles correctly', (WidgetTester tester) async {
    final themeController = ThemeController(initialThemeMode: ThemeMode.light);
    final authController = AuthController(
      authService: DummyAuthApiService(),
      tokenStorage: DummyTokenStorage(),
    );

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: ThemeScope(
          controller: themeController,
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      ),
    );

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Giao diện tối'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Tap switch to enable dark theme
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.dark);
    expect(themeController.isDarkMode, isTrue);

    // Tap again to switch back to light theme
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.light);
    expect(themeController.isDarkMode, isFalse);
  });
}
