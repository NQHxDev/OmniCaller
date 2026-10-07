import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/ws_models.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/chat_websocket_service.dart';

class ConversationsController extends ChangeNotifier {
  final IChatApiService _apiService;
  final IChatWebSocketService _wsService;
  final bool _isCustomWsService;
  String? _currentUserId;
  String? _currentUsername;
  String? _token;

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _wsSubscription;

  ConversationsController({
    String? currentUserId,
    String? currentUsername,
    String? token,
    IChatApiService? apiService,
    IChatWebSocketService? wsService,
  })  : _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        _token = token,
        _apiService = apiService ?? ChatApiService(),
        _wsService = wsService ?? ChatWebSocketService(),
        _isCustomWsService = wsService != null {
    _initWsListener();
  }

  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initWsListener() {
    _wsSubscription = _wsService.events.listen((event) {
      if (event is WsMessageNewEvent) {
        _handleNewMessage(event.message);
      }
    });
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final timeA = a.lastMessage?.createdAt ?? a.updatedAt;
      final timeB = b.lastMessage?.createdAt ?? b.updatedAt;
      return timeB.compareTo(timeA);
    });
  }

  void _handleNewMessage(MessageModel message) {
    final isFromSelf = message.isMine(_currentUserId ?? '', _currentUsername);
    final idx = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx >= 0) {
      final existing = _conversations.removeAt(idx);
      final isSameMessage = existing.lastMessage?.id == message.id;
      final newUnreadCount = isFromSelf
          ? 0
          : (isSameMessage ? existing.unreadCount : (existing.unreadCount + 1));

      final updated = existing.copyWith(
        lastMessage: message,
        unreadCount: newUnreadCount,
        updatedAt: message.createdAt,
      );
      _conversations.insert(0, updated);
      _sortConversations();
      notifyListeners();
    } else {
      if (_token != null && _token!.isNotEmpty) {
        fetchConversations(token: _token);
      }
    }
  }

  Future<void> fetchConversations({
    required String? token,
    String? currentUserId,
    String? currentUsername,
  }) async {
    if (token != null && token.isNotEmpty) _token = token;
    if (currentUserId != null) _currentUserId = currentUserId;
    if (currentUsername != null) _currentUsername = currentUsername;

    final effectiveToken = _token;
    if (effectiveToken == null || effectiveToken.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_wsService.isConnected) {
        _wsService.connect(token: effectiveToken);
      }

      final list = await _apiService.getConversations(token: effectiveToken);
      list.sort((a, b) {
        final timeA = a.lastMessage?.createdAt ?? a.updatedAt;
        final timeB = b.lastMessage?.createdAt ?? b.updatedAt;
        return timeB.compareTo(timeA);
      });
      _conversations = list;
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    if (_isCustomWsService) {
      _wsService.dispose();
    }
    super.dispose();
  }
}
