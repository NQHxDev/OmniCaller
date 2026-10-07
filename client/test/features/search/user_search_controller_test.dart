import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:client/features/search/data/services/user_search_api_service.dart';
import 'package:client/features/search/presentation/controllers/user_search_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserSearchApiService implements IUserSearchApiService {
  SearchUsersResponse? responseToReturn;
  Exception? exceptionToThrow;
  String? lastQuery;
  String? lastToken;

  @override
  Future<SearchUsersResponse> searchUsers({
    required String query,
    required String token,
    int page = 1,
    int pageSize = 10,
  }) async {
    lastQuery = query;
    lastToken = token;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn ??
        const SearchUsersResponse(
          users: [],
          pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 0, totalPages: 0),
        );
  }

  @override
  Future<UserPublicProfile> getUserProfile({
    required String username,
    required String token,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return UserPublicProfile(
      userId: 'u1',
      username: username,
      displayName: 'Display $username',
      createdAt: '2024-01-01T00:00:00Z',
    );
  }
}

void main() {
  group('UserSearchController Tests', () {
    late FakeUserSearchApiService searchService;
    late UserSearchController controller;

    setUp(() {
      searchService = FakeUserSearchApiService();
      controller = UserSearchController(searchService: searchService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is empty', () {
      expect(controller.query, '');
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.results, isEmpty);
      expect(controller.hasQuery, isFalse);
      expect(controller.hasResults, isFalse);
    });

    test('search updates results on success', () async {
      searchService.responseToReturn = const SearchUsersResponse(
        users: [
          UserSearchResult(userId: 'u1', username: 'alex', displayName: 'Alex Mercer'),
        ],
        pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 1, totalPages: 1),
      );

      await controller.search(query: 'alex', token: 'valid_token');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.results.length, 1);
      expect(controller.results.first.displayName, 'Alex Mercer');
      expect(searchService.lastQuery, 'alex');
      expect(searchService.lastToken, 'valid_token');
    });

    test('search handles missing token', () async {
      await controller.search(query: 'alex', token: null);

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, contains('Chưa đăng nhập'));
      expect(controller.results, isEmpty);
    });

    test('search handles error from API', () async {
      searchService.exceptionToThrow = Exception('Network error');

      await controller.search(query: 'alex', token: 'token');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.results, isEmpty);
    });

    test('clear resets all search state', () async {
      searchService.responseToReturn = const SearchUsersResponse(
        users: [
          UserSearchResult(userId: 'u1', username: 'alex', displayName: 'Alex Mercer'),
        ],
        pagination: SearchPagination(currentPage: 1, pageSize: 10, totalItems: 1, totalPages: 1),
      );

      await controller.search(query: 'alex', token: 'token');
      expect(controller.results.isNotEmpty, isTrue);

      controller.clear();
      expect(controller.query, '');
      expect(controller.results, isEmpty);
      expect(controller.errorMessage, isNull);
    });
  });
}
