import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../widgets/chat_input_bar.dart';

class ChatPage extends StatefulWidget {
  final String? userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const ChatPage({
    super.key,
    this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onOpenProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          username: widget.username,
          initialDisplayName: widget.displayName,
          initialUserId: widget.userId,
        ),
      ),
    );
  }

  void _onSendMessage(String text) {
    // Send message handler (to be implemented with server socket/API)
  }

  void _onSendImage() {
    // Send image handler (to be implemented)
  }

  void _onEmojiPressed() {
    // Emoji/sticker picker handler (to be implemented)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (widget.displayName != null && widget.displayName!.isNotEmpty)
        ? widget.displayName!
        : widget.username;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _onOpenProfile,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
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
                      Text(
                        '@${widget.username}',
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
          // Blank chat body area (ready for message list layout)
          const Expanded(
            child: SizedBox.expand(),
          ),

          // Message input bar at bottom
          ChatInputBar(
            controller: _messageController,
            onSendMessage: _onSendMessage,
            onSendImage: _onSendImage,
            onEmojiPressed: _onEmojiPressed,
          ),
        ],
      ),
    );
  }
}
