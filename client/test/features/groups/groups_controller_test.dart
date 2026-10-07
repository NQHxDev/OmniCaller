import 'package:client/features/groups/data/models/group_models.dart';
import 'package:client/features/groups/data/services/group_api_service.dart';
import 'package:client/features/groups/presentation/controllers/groups_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class StubGroupApiService implements IGroupApiService {
  bool shouldFail = false;

  @override
  Future<GroupProfileResponse> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    required String token,
  }) async {
    if (shouldFail) {
      throw Exception('Server error: failed to create group');
    }
    return GroupProfileResponse(
      id: 'grp_new_1',
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      createdBy: 'creator_1',
      memberCount: memberIds.length + 1,
      createdAt: '2026-10-05T00:00:00Z',
    );
  }

  @override
  Future<List<GroupProfileResponse>> getUserGroups({required String token}) async {
    if (shouldFail) {
      throw Exception('Failed to get groups');
    }
    return [
      const GroupProfileResponse(
        id: 'grp_1',
        name: 'Existing Group',
        createdBy: 'creator_1',
        memberCount: 3,
        createdAt: '2026-10-05T00:00:00Z',
      ),
    ];
  }
}

void main() {
  group('GroupsController Tests', () {
    test('initial state is empty and not loading', () {
      final controller = GroupsController(groupService: StubGroupApiService());
      expect(controller.isLoading, isFalse);
      expect(controller.isCreating, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.groups, isEmpty);
    });

    test('createGroup updates groups list on success', () async {
      final service = StubGroupApiService();
      final controller = GroupsController(groupService: service);

      final result = await controller.createGroup(
        name: 'Omni Group',
        memberIds: ['u1', 'u2'],
        token: 'fake_token',
      );

      expect(result, isNotNull);
      expect(result!.name, 'Omni Group');
      expect(controller.groups.length, 1);
      expect(controller.groups.first.id, 'grp_new_1');
      expect(controller.isCreating, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('createGroup sets errorMessage on failure', () async {
      final service = StubGroupApiService()..shouldFail = true;
      final controller = GroupsController(groupService: service);

      final result = await controller.createGroup(
        name: 'Omni Group',
        memberIds: ['u1', 'u2'],
        token: 'fake_token',
      );

      expect(result, isNull);
      expect(controller.isCreating, isFalse);
      expect(controller.errorMessage, contains('Server error: failed to create group'));
    });

    test('fetchUserGroups sets groups list on success', () async {
      final service = StubGroupApiService();
      final controller = GroupsController(groupService: service);

      await controller.fetchUserGroups(token: 'fake_token');

      expect(controller.isLoading, isFalse);
      expect(controller.groups.length, 1);
      expect(controller.groups.first.name, 'Existing Group');
    });

    test('fetchUserGroups sets errorMessage on failure', () async {
      final service = StubGroupApiService()..shouldFail = true;
      final controller = GroupsController(groupService: service);

      await controller.fetchUserGroups(token: 'fake_token');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, contains('Failed to get groups'));
    });
  });
}
