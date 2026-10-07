import 'package:client/core/auth/auth_controller.dart';
import 'package:client/core/auth/auth_scope.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/services/auth_api_service.dart';
import 'package:client/features/contacts/presentation/pages/contacts_page.dart';
import 'package:client/features/messages/presentation/pages/messages_page.dart';
import 'package:client/features/profile/presentation/pages/user_profile_page.dart';
import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
import 'package:client/features/search/presentation/controllers/user_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAuthApiService implements IAuthApiService {
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
      accessToken: 'stub_refreshed_access_token',
      refreshToken: 'stub_refreshed_refresh_token',
    );
  }
}

class StubTokenStorage implements ITokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> getAccessToken() async => 'fake_access_token';
  @override
  Future<String?> getRefreshToken() async => 'fake_refresh_token';
  @override
  Future<AuthSessionData?> loadSession() async => const AuthSessionData(
        userId: 'usr_1',
        username: 'current_user',
        displayName: 'Current User',
        accessToken: 'fake_access_token',
        refreshToken: 'fake_refresh_token',
      );
  @override
  Future<void> saveSession({
    required String userId,
    required String username,
    required String displayName,
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class StubUserSearchApiService implements IUserSearchApiService {
  @override
  Future<SearchUsersResponse> searchUsers({
    required String query,
    required String token,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (query == 'john') {
      return const SearchUsersResponse(
        users: [
          UserSearchResult(
            userId: 'u1',
            username: 'john123',
            displayName: 'John Doe',
          ),
          UserSearchResult(
            userId: 'u2',
            username: 'johnny',
            displayName: 'Johnny Silverhand',
          ),
        ],
        pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 2, totalPages: 1),
      );
    }
    return const SearchUsersResponse(
      users: [],
      pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 0, totalPages: 0),
    );
  }

  @override
  Future<UserPublicProfile> getUserProfile({
    required String username,
    required String token,
  }) async {
    return UserPublicProfile(
      userId: 'u1',
      username: username,
      displayName: username == 'john123' ? 'John Doe' : 'Johnny Silverhand',
      createdAt: '2024-10-01 10:30:45.123456 +00:00',
    );
  }
}

void main() {
  late AuthController authController;

  setUp(() async {
    authController = AuthController(
      authService: StubAuthApiService(),
      tokenStorage: StubTokenStorage(),
    );
    await authController.initialize();
  });

  testWidgets('MessagesPage search displays search results, navigates to UserProfilePage on tap, and clears properly', (WidgetTester tester) async {
    final searchController = UserSearchController(
      searchService: StubUserSearchApiService(),
    );

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: MessagesPage(searchController: searchController),
        ),
      ),
    );

    // Initial state: empty conversations view
    expect(find.text('Chưa có cuộc trò chuyện nào'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Type query "john"
    await tester.enterText(find.byType(TextField), 'john');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify search results are displayed
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('@john123'), findsOneWidget);
    expect(find.text('Johnny Silverhand'), findsOneWidget);
    expect(find.text('@johnny'), findsOneWidget);

    // Tap on John Doe to open UserProfilePage
    await tester.tap(find.text('John Doe'));
    await tester.pumpAndSettle();

    expect(find.byType(UserProfilePage), findsOneWidget);

    // Pop back to MessagesPage
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Tap clear button
    final clearIcon = find.byIcon(Icons.close_rounded);
    expect(clearIcon, findsOneWidget);
    await tester.tap(clearIcon);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có cuộc trò chuyện nào'), findsOneWidget);
  });

  testWidgets('ContactsPage search displays search results and navigates to UserProfilePage on tap', (WidgetTester tester) async {
    final searchController = UserSearchController(
      searchService: StubUserSearchApiService(),
    );

    await tester.pumpWidget(
      AuthScope(
        controller: authController,
        child: MaterialApp(
          home: ContactsPage(searchController: searchController),
        ),
      ),
    );

    // Initial state: quick actions & contacts
    expect(find.text('Quản lý nhóm'), findsOneWidget);
    expect(find.text('Lời mời kết bạn'), findsOneWidget);
    expect(find.textContaining('Danh bạ'), findsOneWidget);

    // Type query "john"
    await tester.enterText(find.byType(TextField), 'john');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify search results are displayed
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('@john123'), findsOneWidget);

    // Tap on Johnny Silverhand to navigate to profile
    await tester.tap(find.text('Johnny Silverhand'));
    await tester.pumpAndSettle();

    expect(find.byType(UserProfilePage), findsOneWidget);

    // Pop back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Type query "nonexistent"
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy người dùng phù hợp'), findsOneWidget);
  });
}
