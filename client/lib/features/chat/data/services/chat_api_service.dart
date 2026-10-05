import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_models.dart';

abstract class IChatApiService {
  Future<List<ConversationModel>> getConversations({required String token});

  Future<ConversationModel> createOrGetDirectConversation({
    required String friendUsername,
    required String token,
  });

  Future<MessagesResponse> getMessages({
    required String conversationId,
    required String token,
    String? cursor,
    int limit = 30,
  });

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
    required String token,
  });
}

class ChatApiService implements IChatApiService {
  final ApiClient _apiClient;

  ChatApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<ConversationModel>> getConversations({required String token}) async {
    final responseData = await _apiClient.get(
      ApiConfig.conversationsEndpoint,
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      final list = (responseData['conversations'] ?? responseData['items']) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } else if (responseData is List) {
      return responseData.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return <ConversationModel>[];
  }

  @override
  Future<ConversationModel> createOrGetDirectConversation({
    required String friendUsername,
    required String token,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.directConversationEndpoint,
      body: {
        'friend_username': friendUsername,
      },
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return ConversationModel.fromJson(responseData);
    }

    throw Exception('Phản hồi không hợp lệ từ máy chủ khi tạo cuộc trò chuyện');
  }

  @override
  Future<MessagesResponse> getMessages({
    required String conversationId,
    required String token,
    String? cursor,
    int limit = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final responseData = await _apiClient.get(
      ApiConfig.conversationMessagesEndpoint(conversationId),
      queryParameters: queryParams,
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return MessagesResponse.fromJson(responseData);
    }

    return const MessagesResponse(messages: []);
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
    required String token,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.sendMessageEndpoint,
      body: {
        'conversation_id': conversationId,
        'content': content,
        if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      },
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return MessageModel.fromJson(responseData);
    }

    throw Exception('Không thể gửi tin nhắn');
  }
}
