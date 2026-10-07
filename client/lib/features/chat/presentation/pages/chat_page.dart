import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../friends/data/services/friend_api_service.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../search/data/services/user_search_api_service.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/services/chat_websocket_service.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId;
  final String? userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isGroup;
  final String? groupTitle;
  final int? memberCount;
  final bool openedFromChat;
  final ChatController? chatController;
  final IChatApiService? chatApiService;
  final IChatWebSocketService? wsService;
  final IUserSearchApiService? userApiService;
  final IFriendApiService? friendApiService;

  const ChatPage({
    super.key,
    this.conversationId,
    this.userId,
    this.username = '',
    this.displayName,
    this.avatarUrl,
    this.isGroup = false,
    this.groupTitle,
    this.memberCount,
    this.openedFromChat = false,
    this.chatController,
    this.chatApiService,
    this.wsService,
    this.userApiService,
    this.friendApiService,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  late final bool _isInternalController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.chatController != null) {
      _controller = widget.chatController!;
      _isInternalController = false;
    } else {
      _isInternalController = true;
      // Controller initialized in didChangeDependencies with AuthScope
    }
  }

  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      final auth = AuthScope.maybeOf(context);
      if (_isInternalController) {
        _controller = ChatController(
          conversationId: widget.conversationId,
          friendUsername: widget.isGroup ? null : widget.username,
          friendDisplayName: widget.isGroup ? null : widget.displayName,
          friendUserId: widget.userId,
          currentUserId: auth?.currentUser?.id,
          currentUsername: auth?.currentUser?.username,
          token: auth?.accessToken,
          apiService: widget.chatApiService,
          wsService: widget.wsService,
        );
      }
      _controller.initialize();
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onOpenProfile() {
    if (widget.username.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          username: widget.username,
          initialDisplayName: widget.displayName,
          initialUserId: widget.userId,
          openedFromChat: true,
          userApiService: widget.userApiService,
          friendApiService: widget.friendApiService,
        ),
      ),
    );
  }

  void _onSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.sendMessage(text);
    _controller.onTypingStopped();
  }

  void _onSendImage() {
    // Send image placeholder (ready for file picker / image upload integration)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chọn và gửi ảnh đang được chuẩn bị'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onEmojiPressed() {
    // Emoji picker placeholder
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.maybeOf(context);
    final currentUserId = auth?.currentUser?.id ?? '';
    final currentUsername = auth?.currentUser?.username ?? '';

    final isGroupChat = widget.isGroup ||
        (widget.groupTitle != null && widget.groupTitle!.isNotEmpty);

    final title = isGroupChat
        ? (widget.groupTitle != null && widget.groupTitle!.isNotEmpty
            ? widget.groupTitle!
            : (widget.displayName != null && widget.displayName!.isNotEmpty
                ? widget.displayName!
                : (widget.username.isNotEmpty ? widget.username : 'Nhóm trò chuyện')))
        : ((widget.displayName != null && widget.displayName!.isNotEmpty)
            ? widget.displayName!
            : (widget.username.isNotEmpty ? widget.username : 'Cuộc trò chuyện'));

    final subtitle = isGroupChat
        ? (widget.memberCount != null && widget.memberCount! > 0
            ? '${widget.memberCount} thành viên'
            : 'Nhóm trò chuyện')
        : (widget.username.isNotEmpty ? '@${widget.username}' : '');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: isGroupChat ? null : _onOpenProfile,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: HugeIcon(
                    icon: isGroupChat
                        ? HugeIcons.strokeRoundedUserGroup
                        : HugeIcons.strokeRoundedUser,
                    color: theme.colorScheme.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCall02,
              size: 20.0,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedVideo01,
              size: 20.0,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              size: 20.0,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_controller.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(120),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: HugeIcon(
                              icon: isGroupChat
                                  ? HugeIcons.strokeRoundedUserGroup
                                  : HugeIcons.strokeRoundedMessage01,
                              color: theme.colorScheme.primary,
                              size: 32.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isGroupChat ? 'Chào mừng đến với nhóm!' : 'Chưa có tin nhắn nào',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isGroupChat
                                ? 'Hãy gửi tin nhắn đầu tiên để cùng nhau thảo luận!'
                                : 'Hãy gửi lời chào đầu tiên để bắt đầu trò chuyện!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (_controller.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          overscroll: false,
                        ),
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _controller.messages.length,
                          itemBuilder: (context, index) {
                            final message = _controller.messages[index];
                            final isMine = message.isMine(currentUserId, currentUsername);
                            return ChatMessageBubble(
                              message: message,
                              isMine: isMine,
                              showAvatar: !isMine,
                              showSenderName: isGroupChat,
                            );
                          },
                        ),
                      ),
                    ),
                    if (_controller.isOtherUserTyping)
                      TypingIndicator(
                        username: isGroupChat
                            ? 'Một thành viên'
                            : (widget.displayName ?? widget.username),
                      ),
                  ],
                );
              },
            ),
          ),

          // Message input bar at bottom
          ChatInputBar(
            controller: _inputController,
            onSendMessage: _onSendMessage,
            onSendImage: _onSendImage,
            onEmojiPressed: _onEmojiPressed,
            onTyping: _controller.onTyping,
            onTypingStopped: _controller.onTypingStopped,
          ),
        ],
      ),
    );
  }
}
