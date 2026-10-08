import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import '../controllers/call_controller.dart';
import '../widgets/call_controls_bar.dart';
import '../widgets/call_timer_widget.dart';
import '../widgets/group_voice_participant_tile.dart';
import '../widgets/speaking_avatar_widget.dart';
import '../widgets/video_track_renderer.dart';

class ActiveCallPage extends StatefulWidget {
  final CallController controller;

  const ActiveCallPage({
    super.key,
    required this.controller,
  });

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleCallStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleCallStateChanged);
    super.dispose();
  }

  void _handleCallStateChanged() {
    if (!mounted) return;

    if (widget.controller.state == CallStateStatus.ended ||
        widget.controller.state == CallStateStatus.idle) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.controller.isVideoCall;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldEnd = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('End Call?'),
            content: const Text('Are you sure you want to end this call?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('End Call', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        if (shouldEnd == true) {
          await widget.controller.endCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF10141D),
        body: SafeArea(
          child: SizedBox.expand(
            child: isVideo ? _buildVideoCallLayout() : _buildVoiceCallLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCallLayout() {
    if (widget.controller.isGroupCall) {
      return _buildGroupVoiceCallLayout();
    }
    return _buildDirectVoiceCallLayout();
  }

  Widget _buildDirectVoiceCallLayout() {
    final partyName = widget.controller.otherPartyName ?? 'Caller';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A2232),
            Color(0xFF0D111A),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with Duration
            Column(
              children: [
                const SizedBox(height: 12),
                CallTimerWidget(duration: widget.controller.formattedDuration),
                const SizedBox(height: 8),
                const Text(
                  'Voice Call',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Center Avatar with Speaking Soundwaves & Name
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeakingAvatarWidget(
                  avatarUrl: widget.controller.otherPartyAvatar,
                  name: partyName,
                  isSpeaking: widget.controller.isRemoteSpeaking,
                  radius: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  partyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: widget.controller.isRemoteSpeaking ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedMic01,
                        color: Color(0xFF4CAF50),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đang nói...',
                        style: TextStyle(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Controls Bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CallControlsBar(
                isMicMuted: widget.controller.isMicMuted,
                isCameraOff: widget.controller.isCameraOff,
                isSpeakerphoneOn: widget.controller.isSpeakerphoneOn,
                isVideoCall: false,
                onToggleMic: () => widget.controller.toggleMicrophone(),
                onToggleSpeaker: () => widget.controller.toggleSpeakerphone(),
                onEndCall: () => widget.controller.endCall(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupVoiceCallLayout() {
    final groupTitle = widget.controller.otherPartyName ?? 'Cuộc gọi nhóm';
    final room = widget.controller.room;
    final remoteParticipants = room?.remoteParticipants.values.toList() ?? [];
    final totalCount = remoteParticipants.length + 1;

    final localParticipant = room?.localParticipant;
    final localSpeaking = localParticipant?.isSpeaking ?? false;
    final localMuted = widget.controller.isMicMuted;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF18202F),
            Color(0xFF0C1018),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CallTimerWidget(duration: widget.controller.formattedDuration),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: Color(0xFF4CAF50),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$totalCount thành viên',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Group Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              groupTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Participants Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: remoteParticipants.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Local user card
                        SizedBox(
                          width: 180,
                          height: 190,
                          child: GroupVoiceParticipantTile(
                            name: 'Bạn',
                            isSpeaking: localSpeaking,
                            isMuted: localMuted,
                            isLocal: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Đang đợi thành viên khác tham gia...',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: totalCount > 4 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: totalCount > 4 ? 0.82 : 0.95,
                      ),
                      itemCount: totalCount,
                      itemBuilder: (context, index) {
                        // Index 0: Local Participant
                        if (index == 0) {
                          return GroupVoiceParticipantTile(
                            name: 'Bạn',
                            isSpeaking: localSpeaking,
                            isMuted: localMuted,
                            isLocal: true,
                          );
                        }

                        // Index 1+: Remote Participants
                        final p = remoteParticipants[index - 1];
                        final pName = p.name.isNotEmpty
                            ? p.name
                            : (widget.controller.otherPartyName ?? p.identity);
                        final pMuted = p.audioTrackPublications.any((t) => t.muted) ||
                            p.audioTrackPublications.isEmpty;

                        return GroupVoiceParticipantTile(
                          name: pName,
                          isSpeaking: p.isSpeaking,
                          isMuted: pMuted,
                          isLocal: false,
                        );
                      },
                    ),
            ),
          ),

          // Controls Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 12),
            child: Center(
              child: CallControlsBar(
                isMicMuted: widget.controller.isMicMuted,
                isCameraOff: widget.controller.isCameraOff,
                isSpeakerphoneOn: widget.controller.isSpeakerphoneOn,
                isVideoCall: false,
                onToggleMic: () => widget.controller.toggleMicrophone(),
                onToggleSpeaker: () => widget.controller.toggleSpeakerphone(),
                onEndCall: () => widget.controller.endCall(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallLayout() {
    final room = widget.controller.room;
    final remoteParticipants = room?.remoteParticipants.values.toList() ?? [];

    // Local Video Track
    final localVideoTrack = room?.localParticipant?.videoTrackPublications
        .map((e) => e.track)
        .whereType<VideoTrack>()
        .firstOrNull;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main Remote Video Area
        if (remoteParticipants.isEmpty)
          // Waiting for remote participant to stream video
          _buildWaitingRemoteVideo()
        else if (remoteParticipants.length == 1)
          // 1-on-1 Remote Participant View
          _buildSingleRemoteParticipant(remoteParticipants.first)
        else
          // Group Call Grid View
          _buildGroupVideoGrid(remoteParticipants),

        // Floating Local Video Preview (Picture in Picture)
        if (localVideoTrack != null && !widget.controller.isCameraOff)
          Positioned(
            right: 16,
            top: 60,
            width: 110,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: VideoTrackRendererWidget(
                track: localVideoTrack,
                participantName: 'Bạn (You)',
                isMirror: widget.controller.isFrontCamera,
                isVideoMuted: widget.controller.isCameraOff,
                isAudioMuted: widget.controller.isMicMuted,
                isSpeaking: room?.localParticipant?.isSpeaking ?? false,
              ),
            ),
          ),

        // Top Overlay Bar: Timer & Status
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallTimerWidget(duration: widget.controller.formattedDuration),
              if (widget.controller.isGroupCall)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${remoteParticipants.length + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Bottom Controls Bar
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(
            child: CallControlsBar(
              isMicMuted: widget.controller.isMicMuted,
              isCameraOff: widget.controller.isCameraOff,
              isSpeakerphoneOn: widget.controller.isSpeakerphoneOn,
              isVideoCall: true,
              onToggleMic: () => widget.controller.toggleMicrophone(),
              onToggleCamera: () => widget.controller.toggleCamera(),
              onSwitchCamera: () => widget.controller.switchCamera(),
              onToggleSpeaker: () => widget.controller.toggleSpeakerphone(),
              onEndCall: () => widget.controller.endCall(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingRemoteVideo() {
    final partyName = widget.controller.otherPartyName ?? 'Remote Participant';
    return Container(
      color: const Color(0xFF151922),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF4CAF50),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Connecting to $partyName...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleRemoteParticipant(RemoteParticipant participant) {
    final videoTrack = participant.videoTrackPublications
        .map((e) => e.track)
        .whereType<VideoTrack>()
        .firstOrNull;

    final name = participant.name.isNotEmpty
        ? participant.name
        : (widget.controller.otherPartyName ?? participant.identity);

    return SizedBox.expand(
      child: VideoTrackRendererWidget(
        track: videoTrack,
        participantName: name,
        isVideoMuted: videoTrack == null || participant.videoTrackPublications.any((p) => p.muted),
        isAudioMuted: participant.audioTrackPublications.any((p) => p.muted),
        isSpeaking: participant.isSpeaking,
        fit: VideoViewFit.cover,
      ),
    );
  }

  Widget _buildGroupVideoGrid(List<RemoteParticipant> participants) {
    return Padding(
      padding: const EdgeInsets.only(top: 70, bottom: 100, left: 12, right: 12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: participants.length > 2 ? 2 : 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: participants.length > 2 ? 0.85 : 1.2,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          final videoTrack = participant.videoTrackPublications
              .map((e) => e.track)
              .whereType<VideoTrack>()
              .firstOrNull;
          final name = participant.name.isNotEmpty ? participant.name : participant.identity;

          return VideoTrackRendererWidget(
            track: videoTrack,
            participantName: name,
            isVideoMuted: videoTrack == null || participant.videoTrackPublications.any((p) => p.muted),
            isAudioMuted: participant.audioTrackPublications.any((p) => p.muted),
            isSpeaking: participant.isSpeaking,
            fit: VideoViewFit.cover,
          );
        },
      ),
    );
  }
}
