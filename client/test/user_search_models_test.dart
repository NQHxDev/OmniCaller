import 'package:client/features/search/data/models/user_search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSearchModels Tests', () {
    test('UserSearchResult deserializes and serializes correctly', () {
      final json = {
        'user_id': '01928374-5678-9abc-def0-123456789abc',
        'username': 'john123',
        'display_name': 'John Doe',
      };

      final result = UserSearchResult.fromJson(json);
      expect(result.userId, '01928374-5678-9abc-def0-123456789abc');
      expect(result.username, 'john123');
      expect(result.displayName, 'John Doe');

      final serialized = result.toJson();
      expect(serialized['user_id'], '01928374-5678-9abc-def0-123456789abc');
      expect(serialized['username'], 'john123');
      expect(serialized['display_name'], 'John Doe');
    });

    test('SearchPagination deserializes correctly', () {
      final json = {
        'current_page': 2,
        'page_size': 20,
        'total_items': 45,
        'total_pages': 3,
      };

      final pagination = SearchPagination.fromJson(json);
      expect(pagination.currentPage, 2);
      expect(pagination.pageSize, 20);
      expect(pagination.totalItems, 45);
      expect(pagination.totalPages, 3);
    });

    test('SearchUsersResponse deserializes full response data', () {
      final json = {
        'users': [
          {
            'user_id': 'u1',
            'username': 'alice',
            'display_name': 'Alice Wonder',
          },
          {
            'user_id': 'u2',
            'username': 'bob',
            'display_name': 'Bob Builder',
          },
        ],
        'pagination': {
          'current_page': 1,
          'page_size': 10,
          'total_items': 2,
          'total_pages': 1,
        },
      };

      final response = SearchUsersResponse.fromJson(json);
      expect(response.users.length, 2);
      expect(response.users[0].username, 'alice');
      expect(response.users[1].displayName, 'Bob Builder');
      expect(response.pagination.totalItems, 2);
    });
  });
}
