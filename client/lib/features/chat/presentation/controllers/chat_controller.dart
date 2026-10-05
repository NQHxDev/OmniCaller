import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/ws_models.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/chat_websocket_service.dart';

class ChatController extends ChangeNotifier {
  final IChatApiService _apiService;
  final IChatWebSocketService _wsService;
  final bool _isCustomWsService;

  String? _conversationId;
  final String? _friendUsername;
  final String? _friendDisplayName;
  final String? _friendUserId;
  final String? _currentUserId;
  final String? _currentUsername;
  final String? _token;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _nextCursor;
  String? _errorMessage;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _wsSubscription;

  ChatController({
    String? conversationId,
    String? friendUsername,
    String? friendDisplayName,
    String? friendUserId,
    String? currentUserId,
    String? currentUsername,
    String? token,
    IChatApiService? apiService,
    IChatWebSocketService? wsService,
  })  : _conversationId = conversationId,
        _friendUsername = friendUsername,
        _friendDisplayName = friendDisplayName,
        _friendUserId = friendUserId,
        _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        _token = token,
        _apiService = apiService ?? ChatApiService(),
        _wsService = wsService ?? ChatWebSocketService(),
        _isCustomWsService = wsService != null {
    _initWsListener();
  }

  String? get conversationId => _conversationId;
  String? get friendUsername => _friendUsername;
  String? get friendDisplayName => _friendDisplayName;
  String? get friendUserId => _friendUserId;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isOtherUserTyping => _isOtherUserTyping;

  void _initWsListener() {
    _wsSubscription = _wsService.events.listen((event) {
      if (event is WsMessageNewEvent) {
        if (_conversationId != null && event.message.conversationId == _conversationId) {
          _handleNewIncomingMessage(event.message);
        }
      } else if (event is WsMessageStatusEvent) {
        _handleMessageStatusUpdate(event.messageId, event.status);
      } else if (event is WsUserTypingStartEvent) {
        if (_conversationId != null && event.conversationId == _conversationId) {
          if (event.userId != _currentUserId) {
            _isOtherUserTyping = true;
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 4), () {
              _isOtherUserTyping = false;
              notifyListeners();
            });
            notifyListeners();
          }
        }
      } else if (event is WsUserTypingStopEvent) {
        if (_conversationId != null && event.conversationId == _conversationId) {
          _isOtherUserTyping = false;
          _typingTimer?.cancel();
          notifyListeners();
        }
      }
    });
  }

  void _markUnreadMessagesAsRead() {
    if (_token == null || _token!.isEmpty || !_wsService.isConnected) return;
    for (final m in _messages) {
      final isMine = m.isMine(_currentUserId ?? '', _currentUsername);
      if (!isMine && m.status != MessageStatus.read) {
        _wsService.send(WsMessageDeliveredEvent(messageId: m.id));
        _wsService.send(WsMessageReadEvent(messageId: m.id));
      }
    }
  }

  void _handleNewIncomingMessage(MessageModel incoming) {
    // Avoid duplicate message if already present by exact server ID
    final existingIdx = _messages.indexWhere((m) => m.id == incoming.id);
    if (existingIdx >= 0) {
      _messages[existingIdx] = incoming;
      _isOtherUserTyping = false;
      notifyListeners();
      return;
    }

    // Check if the message is from self to reconcile optimistic messages
    final isFromSelf = incoming.isMine(_currentUserId ?? '', _currentUsername);
    int tempIdx = -1;
    if (isFromSelf) {
      tempIdx = _messages.lastIndexWhere(
        (m) => m.id.startsWith('temp_') && m.content == incoming.content,
      );
      if (tempIdx < 0) {
        tempIdx = _messages.lastIndexWhere((m) => m.id.startsWith('temp_'));
      }
    }

    if (tempIdx >= 0) {
      // Replace optimistic message with actual message from server
      _messages[tempIdx] = incoming;
    } else {
      _messages.insert(0, incoming);
    }
    _isOtherUserTyping = false;
    notifyListeners();

    // Mark as delivered/read (only if received from someone else)
    if (!isFromSelf && _token != null && _token!.isNotEmpty) {
      _wsService.send(WsMessageDeliveredEvent(messageId: incoming.id));
      _wsService.send(WsMessageReadEvent(messageId: incoming.id));
    }
  }

  void _handleMessageStatusUpdate(String messageId, MessageStatus status) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(status: status);
      if (status == MessageStatus.read) {
        for (int i = idx + 1; i < _messages.length; i++) {
          final m = _messages[i];
          if (m.isMine(_currentUserId ?? '', _currentUsername) &&
              (m.status == MessageStatus.sent || m.status == MessageStatus.delivered)) {
            _messages[i] = m.copyWith(status: MessageStatus.read);
          }
        }
      }
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_token == null || _token!.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Connect WebSocket if not connected
      if (!_wsService.isConnected) {
        await _wsService.connect(token: _token!);
      }

      // If conversationId is unknown, resolve it via direct conversation API
      if (_conversationId == null || _conversationId!.isEmpty) {
        if (_friendUsername != null && _friendUsername!.isNotEmpty) {
          final conv = await _apiService.createOrGetDirectConversation(
            friendUsername: _friendUsername!,
            token: _token!,
          );
          _conversationId = conv.id;
        }
      }

      // Fetch initial messages
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        final res = await _apiService.getMessages(
          conversationId: _conversationId!,
          token: _token!,
          limit: 30,
        );
        _messages = res.messages;
        _nextCursor = res.nextCursor;
        _hasMore = res.hasMore;

        _markUnreadMessagesAsRead();
      }
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _conversationId == null || _token == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final res = await _apiService.getMessages(
        conversationId: _conversationId!,
        token: _token!,
        cursor: _nextCursor,
        limit: 30,
      );

      _messages.addAll(res.messages);
      _nextCursor = res.nextCursor;
      _hasMore = res.hasMore;
      _isLoadingMore = false;
    } catch (_) {
      _isLoadingMore = false;
    }
    notifyListeners();
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _token == null) return false;

    // Ensure conversation exists
    if (_conversationId == null || _conversationId!.isEmpty) {
      if (_friendUsername != null && _friendUsername!.isNotEmpty) {
        try {
          final conv = await _apiService.createOrGetDirectConversation(
            friendUsername: _friendUsername!,
            token: _token!,
          );
          _conversationId = conv.id;
        } catch (e) {
          _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
          notifyListeners();
          return false;
        }
      } else {
        return false;
      }
    }

    final convId = _conversationId!;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic message
    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: convId,
      senderId: _currentUserId ?? '',
      senderUsername: _currentUsername ?? '',
      senderDisplayName: '',
      content: trimmed,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _messages.insert(0, optimisticMsg);
    notifyListeners();

    // Send via WebSocket if connected, else via REST
    if (_wsService.isConnected) {
      _wsService.send(WsSendMessageEvent(
        conversationId: convId,
        content: trimmed,
      ));
      // Give optimistic message sent status
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(status: MessageStatus.sent);
      }
      notifyListeners();
      return true;
    } else {
      try {
        final serverMsg = await _apiService.sendMessage(
          conversationId: convId,
          content: trimmed,
          token: _token!,
        );
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx >= 0) {
          _messages[idx] = serverMsg;
        } else {
          _messages.insert(0, serverMsg);
        }
        notifyListeners();
        return true;
      } catch (e) {
        final idx = _messages.indexWhere((m) => m.id == tempId);
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(status: MessageStatus.failed);
        }
        notifyListeners();
        return false;
      }
    }
  }

  void onTyping() {
    if (_conversationId != null && _wsService.isConnected) {
      _wsService.send(WsTypingStartEvent(conversationId: _conversationId!));
    }
  }

  void onTypingStopped() {
    if (_conversationId != null && _wsService.isConnected) {
      _wsService.send(WsTypingStopEvent(conversationId: _conversationId!));
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _wsSubscription?.cancel();
    if (_isCustomWsService) {
      _wsService.dispose();
    }
    super.dispose();
  }
}
