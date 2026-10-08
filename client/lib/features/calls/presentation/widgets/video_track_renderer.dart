import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';

class VideoTrackRendererWidget extends StatelessWidget {
  final VideoTrack? track;
  final String participantName;
  final String? avatarUrl;
  final bool isVideoMuted;
  final bool isAudioMuted;
  final bool isSpeaking;
  final bool isMirror;
  final VideoViewFit fit;

  const VideoTrackRendererWidget({
    super.key,
    required this.track,
    required this.participantName,
    this.avatarUrl,
    this.isVideoMuted = false,
    this.isAudioMuted = false,
    this.isSpeaking = false,
    this.isMirror = false,
    this.fit = VideoViewFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveVideo = track != null && !isVideoMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? const Color(0xFF4CAF50) : Colors.white12,
          width: isSpeaking ? 2.5 : 1.0,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasActiveVideo)
              VideoTrackRenderer(
                track!,
                fit: fit,
                mirrorMode: isMirror
                    ? VideoViewMirrorMode.mirror
                    : VideoViewMirrorMode.auto,
              )
            else
              _buildAvatarPlaceholder(),

            // Participant label & mic / speaking status badge
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: isSpeaking
                      ? Border.all(color: const Color(0xFF4CAF50), width: 1.0)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSpeaking) ...[
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedMic01,
                        color: Color(0xFF4CAF50),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                    ] else if (isAudioMuted) ...[
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedMic02,
                        color: Color(0xFFFF5252),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        participantName,
                        style: TextStyle(
                          color: isSpeaking ? const Color(0xFF4CAF50) : Colors.white,
                          fontSize: 12,
                          fontWeight: isSpeaking ? FontWeight.bold : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initial = participantName.trim().isNotEmpty
        ? participantName.trim()[0].toUpperCase()
        : '?';

    return Container(
      color: const Color(0xFF1E222A),
      child: Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF2A313E),
          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
