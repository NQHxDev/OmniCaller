import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/models/chat_models.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final String? avatarUrl;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.avatarUrl,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatusText(ThemeData theme) {
    String text;
    Color color = Colors.white.withAlpha(200);

    switch (message.status) {
      case MessageStatus.sending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.2,
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Đang gửi',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        );
      case MessageStatus.sent:
        text = 'Đã gửi';
        break;
      case MessageStatus.delivered:
        text = 'Đã nhận';
        break;
      case MessageStatus.read:
        text = 'Đã xem';
        color = const Color(0xFF90CAF9);
        break;
      case MessageStatus.failed:
        text = 'Lỗi';
        color = theme.colorScheme.error;
        break;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: message.status == MessageStatus.read ? FontWeight.w600 : FontWeight.normal,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final myBgColor = theme.colorScheme.primary;
    final otherBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHigh;

    final myTextColor = Colors.white;
    final otherTextColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.0),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: theme.colorScheme.primary,
                size: 14.0,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMine) ...[
            const SizedBox(width: 36),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMine ? myBgColor : otherBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? myTextColor : otherTextColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMine
                              ? Colors.white.withAlpha(180)
                              : theme.colorScheme.onSurfaceVariant.withAlpha(160),
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withAlpha(140),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusText(theme),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
