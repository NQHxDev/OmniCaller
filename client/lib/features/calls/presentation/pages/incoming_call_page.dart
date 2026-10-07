import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../controllers/call_controller.dart';
import 'active_call_page.dart';

class IncomingCallPage extends StatefulWidget {
  final CallController controller;

  const IncomingCallPage({
    super.key,
    required this.controller,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
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

    if (widget.controller.state == CallStateStatus.connected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveCallPage(controller: widget.controller),
        ),
      );
    } else if (widget.controller.state == CallStateStatus.ended ||
        widget.controller.state == CallStateStatus.idle) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.controller.otherPartyName ?? 'Unknown caller';
    final isVideo = widget.controller.isVideoCall;
    final initial = callerName.trim().isNotEmpty ? callerName.trim()[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFF10141D),
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Section: Call Type Indicator
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: isVideo
                              ? HugeIcons.strokeRoundedVideo01
                              : HugeIcons.strokeRoundedCall02,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center Section: Caller Avatar & Name
                Column(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: const Color(0xFF263238),
                      backgroundImage: (widget.controller.otherPartyAvatar != null &&
                              widget.controller.otherPartyAvatar!.isNotEmpty)
                          ? NetworkImage(widget.controller.otherPartyAvatar!)
                          : null,
                      child: (widget.controller.otherPartyAvatar == null ||
                              widget.controller.otherPartyAvatar!.isEmpty)
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      callerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ringing...',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Bottom Section: Accept & Decline Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline Button
                      _buildActionButton(
                        label: 'Decline',
                        color: const Color(0xFFE53935),
                        icon: HugeIcons.strokeRoundedCallEnd01,
                        onTap: () async {
                          await widget.controller.rejectCall();
                        },
                      ),

                      // Accept Button
                      _buildActionButton(
                        label: 'Accept',
                        color: const Color(0xFF43A047),
                        icon: isVideo
                            ? HugeIcons.strokeRoundedVideo01
                            : HugeIcons.strokeRoundedCall02,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await widget.controller.acceptCall();
                          if (!success && mounted && widget.controller.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(widget.controller.errorMessage!),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
