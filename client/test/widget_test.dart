import 'package:client/app.dart';
import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/messages/presentation/widgets/messages_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthApiService implements IAuthApiService {
  @override
  Future<AuthResponseDto> login({
    required String username,
    required String password,
  }) async {
    return AuthResponseDto(
      userId: 'usr_1',
      username: username,
      displayName: username,
      accessToken: 'fake_access_token',
      refreshToken: 'fake_refresh_token',
    );
  }

  @override
  Future<AuthResponseDto> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    return AuthResponseDto(
      userId: 'usr_2',
      username: username,
      displayName: displayName,
      accessToken: 'fake_access_token',
      refreshToken: 'fake_refresh_token',
    );
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    return const RefreshTokenResponseDto(
      accessToken: 'refreshed_access_token',
      refreshToken: 'refreshed_refresh_token',
    );
  }

  @override
  Future<void> logout(String token) async {}
}

class FakeTokenStorage implements ITokenStorage {
  AuthSessionData? session;

  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {
    session = AuthSessionData(
      userId: userId,
      username: username,
      displayName: displayName,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<AuthSessionData?> loadSession() async => session;

  @override
  Future<String?> getAccessToken() async => session?.accessToken;

  @override
  Future<String?> getRefreshToken() async => session?.refreshToken;

  @override
  Future<void> clear() async {
    session = null;
  }
}

void main() {
  testWidgets('Full Authentication flow and Home navigation test with real API integration layer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authController = AuthController(
      authService: FakeAuthApiService(),
      tokenStorage: FakeTokenStorage(),
    );
    await tester.pumpWidget(App(authController: authController));

    // 1. Initially unauthenticated -> LoginPage is shown
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);

    // 2. Navigate to RegisterPage
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    expect(find.text('Tên hiển thị'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);

    // Return to LoginPage via Back button
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);

    // 3. Perform Login
    await tester.enterText(find.byType(TextFormField).at(0), 'anhjkr');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    // 4. Now authenticated -> HomePage is displayed
    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.text('Danh bạ'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);

    // 5. Test Messages menu
    final plusButton = find.byType(PopupMenuButton<MessagesMenuAction>);
    expect(plusButton, findsOneWidget);
    await tester.tap(plusButton);
    await tester.pumpAndSettle();
    expect(find.text('Thêm bạn'), findsOneWidget);
    await tester.tap(find.text('Thêm bạn'));
    await tester.pumpAndSettle();

    // 6. Test Contacts tab and navigation
    await tester.tap(find.text('Danh bạ'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Quản lý nhóm'), findsOneWidget);
    expect(find.byTooltip('Lời mời kết bạn'), findsOneWidget);

    await tester.tap(find.byTooltip('Quản lý nhóm'));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý nhóm'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 7. Test Profile tab & Logout flow
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cài đặt'), findsOneWidget);
    expect(find.text('@anhjkr'), findsNothing);
    expect(find.text('anhjkr'), findsWidgets);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('Giao diện tối'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    // Toggle dark mode switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Perform Logout
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    // In confirmation dialog, tap Đăng xuất
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    // 8. Verified -> back to LoginPage
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
