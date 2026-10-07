import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class CallControlsBar extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isSpeakerphoneOn;
  final bool isVideoCall;
  final VoidCallback onToggleMic;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;

  const CallControlsBar({
    super.key,
    required this.isMicMuted,
    required this.isCameraOff,
    required this.isSpeakerphoneOn,
    required this.isVideoCall,
    required this.onToggleMic,
    this.onToggleCamera,
    this.onSwitchCamera,
    required this.onToggleSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speakerphone Button
          _buildControlButton(
            icon: isSpeakerphoneOn
                ? HugeIcons.strokeRoundedVolumeHigh
                : HugeIcons.strokeRoundedVolumeLow,
            isActive: isSpeakerphoneOn,
            onTap: onToggleSpeaker,
            tooltip: isSpeakerphoneOn ? 'Speaker On' : 'Speaker Off',
          ),
          const SizedBox(width: 14),

          // Mic Mute Button
          _buildControlButton(
            icon: isMicMuted
                ? HugeIcons.strokeRoundedMic02
                : HugeIcons.strokeRoundedMic01,
            isActive: !isMicMuted,
            isDestructiveState: isMicMuted,
            onTap: onToggleMic,
            tooltip: isMicMuted ? 'Unmute' : 'Mute',
          ),
          const SizedBox(width: 14),

          // Video specific buttons
          if (isVideoCall) ...[
            if (onToggleCamera != null) ...[
              _buildControlButton(
                icon: isCameraOff
                    ? HugeIcons.strokeRoundedVideo02
                    : HugeIcons.strokeRoundedVideo01,
                isActive: !isCameraOff,
                isDestructiveState: isCameraOff,
                onTap: onToggleCamera!,
                tooltip: isCameraOff ? 'Turn Cam On' : 'Turn Cam Off',
              ),
              const SizedBox(width: 14),
            ],
            if (onSwitchCamera != null && !isCameraOff) ...[
              _buildControlButton(
                icon: HugeIcons.strokeRoundedCamera01,
                isActive: false,
                onTap: onSwitchCamera!,
                tooltip: 'Switch Camera',
              ),
              const SizedBox(width: 14),
            ],
          ],

          // End Call Button
          _buildEndCallButton(onTap: onEndCall),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required dynamic icon,
    required bool isActive,
    bool isDestructiveState = false,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    Color backgroundColor;
    Color iconColor;

    if (isDestructiveState) {
      backgroundColor = Colors.white.withValues(alpha: 0.2);
      iconColor = const Color(0xFFFF5252);
    } else if (isActive) {
      backgroundColor = Colors.white.withValues(alpha: 0.25);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withValues(alpha: 0.12);
      iconColor = Colors.white70;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndCallButton({required VoidCallback onTap}) {
    return Tooltip(
      message: 'End Call',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE53935),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCallEnd01,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
