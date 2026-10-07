import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../controllers/call_controller.dart';
import 'active_call_page.dart';

class OutgoingCallPage extends StatefulWidget {
  final CallController controller;

  const OutgoingCallPage({
    super.key,
    required this.controller,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage> {
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
        widget.controller.state == CallStateStatus.idle ||
        widget.controller.state == CallStateStatus.error) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calleeName = widget.controller.otherPartyName ?? 'Recipient';
    final isVideo = widget.controller.isVideoCall;
    final initial = calleeName.trim().isNotEmpty ? calleeName.trim()[0].toUpperCase() : '?';

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
                // Top Section: Calling Type
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
                          isVideo ? 'Outgoing Video Call' : 'Outgoing Voice Call',
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

                // Center Section: Callee Avatar & Status
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
                      calleeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.controller.state == CallStateStatus.connecting
                          ? 'Connecting...'
                          : 'Calling...',
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Bottom Section: Cancel Call Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: () async {
                      await widget.controller.cancelCall();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE53935),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCallEnd01,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
