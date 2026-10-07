import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/models/chat_models.dart';

class CallLogBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onCallBack;

  const CallLogBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onCallBack,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta = message.callLogMetadata;

    final isVideo = meta?.isVideo ?? false;
    final isMissed = meta?.isMissed ?? false;
    final isRejected = meta?.isRejected ?? false;
    final isCompleted = meta?.isCompleted ?? false;

    // Determine status color and icon
    Color accentColor;
    dynamic iconData;

    if (isCompleted) {
      accentColor = const Color(0xFF4CAF50); // Green
      iconData = isVideo ? HugeIcons.strokeRoundedVideo01 : HugeIcons.strokeRoundedCall02;
    } else if (isMissed || isRejected) {
      accentColor = const Color(0xFFE53935); // Red
      iconData = isVideo ? HugeIcons.strokeRoundedVideo02 : HugeIcons.strokeRoundedCallEnd01;
    } else {
      accentColor = Colors.orangeAccent;
      iconData = isVideo ? HugeIcons.strokeRoundedVideo01 : HugeIcons.strokeRoundedCall02;
    }

    final title = meta?.titleText(isMine) ?? (isMine ? 'Cuộc gọi đi' : 'Cuộc gọi đến');
    final durationText = (isCompleted && meta != null) ? meta.formatDuration() : '';

    final bgCardColor = isDark
        ? (isMine ? const Color(0xFF1E293B) : const Color(0xFF1E2430))
        : (isMine ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCallBack,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: bgCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withAlpha(80),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Circle
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withAlpha(35),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: iconData,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text and Time
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (durationText.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                durationText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nhấn để gọi lại',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
