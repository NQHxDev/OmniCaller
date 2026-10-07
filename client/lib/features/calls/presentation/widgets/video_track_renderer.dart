import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';

class VideoTrackRendererWidget extends StatelessWidget {
  final VideoTrack? track;
  final String participantName;
  final String? avatarUrl;
  final bool isVideoMuted;
  final bool isAudioMuted;
  final bool isMirror;
  final VideoViewFit fit;

  const VideoTrackRendererWidget({
    super.key,
    required this.track,
    required this.participantName,
    this.avatarUrl,
    this.isVideoMuted = false,
    this.isAudioMuted = false,
    this.isMirror = false,
    this.fit = VideoViewFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveVideo = track != null && !isVideoMuted;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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

          // Participant label & mic muted badge
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAudioMuted) ...[
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedMic02,
                      color: Color(0xFFFF5252),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    participantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          radius: 40,
          backgroundColor: const Color(0xFF2A313E),
          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
