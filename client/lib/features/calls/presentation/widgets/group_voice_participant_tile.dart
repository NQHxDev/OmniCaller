import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'speaking_avatar_widget.dart';

class GroupVoiceParticipantTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isSpeaking;
  final bool isMuted;
  final bool isLocal;

  const GroupVoiceParticipantTile({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.isSpeaking,
    required this.isMuted,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking
              ? const Color(0xFF4CAF50)
              : (isLocal ? Colors.white24 : Colors.white10),
          width: isSpeaking ? 2.0 : 1.0,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeakingAvatarWidget(
            name: name,
            avatarUrl: avatarUrl,
            isSpeaking: isSpeaking,
            radius: 30,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              isLocal ? '$name (Bạn)' : name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSpeaking ? const Color(0xFF4CAF50) : Colors.white,
                fontSize: 12,
                fontWeight: isSpeaking ? FontWeight.bold : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSpeaking
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                  : (isMuted
                      ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: isSpeaking
                      ? HugeIcons.strokeRoundedMic01
                      : (isMuted
                          ? HugeIcons.strokeRoundedMic02
                          : HugeIcons.strokeRoundedMic01),
                  color: isSpeaking
                      ? const Color(0xFF4CAF50)
                      : (isMuted ? const Color(0xFFFF5252) : Colors.white54),
                  size: 11,
                ),
                const SizedBox(width: 3),
                Text(
                  isSpeaking
                      ? 'Đang nói'
                      : (isMuted ? 'Đã tắt mic' : 'Đang nghe'),
                  style: TextStyle(
                    color: isSpeaking
                        ? const Color(0xFF4CAF50)
                        : (isMuted ? const Color(0xFFFF5252) : Colors.white54),
                    fontSize: 10,
                    fontWeight: isSpeaking ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
