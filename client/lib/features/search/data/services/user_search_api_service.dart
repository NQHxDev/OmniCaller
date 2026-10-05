import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_search_models.dart';

abstract class IUserSearchApiService {
  Future<SearchUsersResponse> searchUsers({
    required String query,
    required String token,
    int page = 1,
    int pageSize = 10,
  });

  Future<UserPublicProfile> getUserProfile({
    required String username,
    required String token,
  });
}

class UserSearchApiService implements IUserSearchApiService {
  final ApiClient _apiClient;

  UserSearchApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<SearchUsersResponse> searchUsers({
    required String query,
    required String token,
    int page = 1,
    int pageSize = 10,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.searchUsersEndpoint,
      token: token,
      queryParameters: {
        'query': query,
        'page': page,
        'page_size': pageSize,
      },
    );

    if (responseData is Map<String, dynamic>) {
      return SearchUsersResponse.fromJson(responseData);
    }

    throw const FormatException('Định dạng dữ liệu trả về không hợp lệ');
  }

  @override
  Future<UserPublicProfile> getUserProfile({
    required String username,
    required String token,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final responseData = await _apiClient.get(
      '/api/users/$cleanUsername',
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return UserPublicProfile.fromJson(responseData);
    }

    throw const FormatException('Định dạng dữ liệu trả về không hợp lệ');
  }
}
