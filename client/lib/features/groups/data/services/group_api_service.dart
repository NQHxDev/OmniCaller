import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/group_models.dart';

abstract class IGroupApiService {
  Future<GroupProfileResponse> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    required String token,
  });

  Future<List<GroupProfileResponse>> getUserGroups({
    required String token,
  });
}

class GroupApiService implements IGroupApiService {
  final ApiClient _apiClient;

  GroupApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<GroupProfileResponse> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    required String token,
  }) async {
    final request = CreateGroupRequest(
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl,
      memberIds: memberIds,
    );

    final responseData = await _apiClient.post(
      ApiConfig.groupsEndpoint,
      body: request.toJson(),
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return GroupProfileResponse.fromJson(responseData);
    }

    throw Exception('Phản hồi không hợp lệ từ máy chủ khi tạo nhóm');
  }

  @override
  Future<List<GroupProfileResponse>> getUserGroups({
    required String token,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.groupsEndpoint,
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      final list = responseData['groups'] as List<dynamic>?;
      if (list != null) {
        return list
            .map((e) => GroupProfileResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (responseData is List) {
      return responseData
          .map((e) => GroupProfileResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return <GroupProfileResponse>[];
  }
}
