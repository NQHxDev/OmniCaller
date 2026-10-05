import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/friend_models.dart';

abstract class IFriendApiService {
  Future<List<FriendUser>> getFriends({
    required String token,
    int page = 1,
    int pageSize = 50,
  });

  Future<List<FriendRequestItem>> getReceivedFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  });

  Future<List<FriendRequestItem>> getSentFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  });

  Future<FriendRequestItem> sendFriendRequest({
    String? friendId,
    String? friendUsername,
    required String token,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
    required String token,
  });

  Future<void> rejectFriendRequest({
    required String requestId,
    required String token,
  });

  Future<void> cancelFriendRequest({
    required String requestId,
    required String token,
  });

  Future<void> unfriend({
    required String friendId,
    required String token,
  });

  Future<FriendshipStatusData> getFriendshipStatus({
    required String userId,
    required String token,
  });
}

class FriendApiService implements IFriendApiService {
  final ApiClient _apiClient;

  FriendApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<FriendUser>> getFriends({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.friendsEndpoint,
      token: token,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    if (responseData is List) {
      return responseData.map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (responseData is Map<String, dynamic>) {
      final list = (responseData['friends'] ?? responseData['users'] ?? responseData['items']) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return <FriendUser>[];
  }

  @override
  Future<List<FriendRequestItem>> getReceivedFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.friendRequestsReceivedEndpoint,
      token: token,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    if (responseData is List) {
      return responseData.map((e) => FriendRequestItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (responseData is Map<String, dynamic>) {
      final list = (responseData['requests'] ?? responseData['items'] ?? responseData['received_requests']) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => FriendRequestItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return <FriendRequestItem>[];
  }

  @override
  Future<List<FriendRequestItem>> getSentFriendRequests({
    required String token,
    int page = 1,
    int pageSize = 50,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.friendRequestsSentEndpoint,
      token: token,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    if (responseData is List) {
      return responseData.map((e) => FriendRequestItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (responseData is Map<String, dynamic>) {
      final list = (responseData['requests'] ?? responseData['items'] ?? responseData['sent_requests']) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => FriendRequestItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return <FriendRequestItem>[];
  }

  @override
  Future<FriendRequestItem> sendFriendRequest({
    String? friendId,
    String? friendUsername,
    required String token,
  }) async {
    final body = <String, dynamic>{};
    if (friendId != null && friendId.isNotEmpty) {
      body['friend_id'] = friendId;
    }
    if (friendUsername != null && friendUsername.isNotEmpty) {
      body['friend_username'] = friendUsername;
    }

    final responseData = await _apiClient.post(
      ApiConfig.friendRequestsEndpoint,
      token: token,
      body: body,
    );

    if (responseData is Map<String, dynamic>) {
      return FriendRequestItem.fromJson(responseData);
    }
    return FriendRequestItem(
      requestId: '',
      userId: friendId ?? '',
      username: friendUsername ?? '',
      displayName: '',
      requestedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String token,
  }) async {
    await _apiClient.post(
      ApiConfig.acceptFriendRequestEndpoint(requestId),
      token: token,
    );
  }

  @override
  Future<void> rejectFriendRequest({
    required String requestId,
    required String token,
  }) async {
    await _apiClient.post(
      ApiConfig.rejectFriendRequestEndpoint(requestId),
      token: token,
    );
  }

  @override
  Future<void> cancelFriendRequest({
    required String requestId,
    required String token,
  }) async {
    await _apiClient.delete(
      ApiConfig.cancelFriendRequestEndpoint(requestId),
      token: token,
    );
  }

  @override
  Future<void> unfriend({
    required String friendId,
    required String token,
  }) async {
    await _apiClient.delete(
      ApiConfig.unfriendEndpoint(friendId),
      token: token,
    );
  }

  @override
  Future<FriendshipStatusData> getFriendshipStatus({
    required String userId,
    required String token,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.friendshipStatusEndpoint(userId),
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return FriendshipStatusData.fromJson(responseData);
    }
    return const FriendshipStatusData(status: FriendshipStatus.none);
  }
}
