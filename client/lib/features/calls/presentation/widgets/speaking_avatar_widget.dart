import 'package:flutter/material.dart';

/// Animated soundwave ripple painter radiating outward from avatar center
class SoundwaveRipplePainter extends CustomPainter {
  final double animationValue; // 0.0 -> 1.0
  final Color color;
  final double baseRadius;
  final int waveCount;

  SoundwaveRipplePainter({
    required this.animationValue,
    required this.color,
    required this.baseRadius,
    this.waveCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxExpansion = baseRadius * 0.45;

    for (int i = 0; i < waveCount; i++) {
      final progress = (animationValue + (i / waveCount)) % 1.0;
      final currentRadius = baseRadius + (progress * maxExpansion);
      final opacity = ((1.0 - progress) * 0.45).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.0 * (1.0 - (progress * 0.6))).clamp(1.0, 3.0);

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SoundwaveRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.baseRadius != baseRadius;
  }
}

/// A circular avatar widget that radiates soundwaves when the participant is speaking
class SpeakingAvatarWidget extends StatefulWidget {
  final String? avatarUrl;
  final String name;
  final bool isSpeaking;
  final double radius;
  final Color activeColor;

  const SpeakingAvatarWidget({
    super.key,
    this.avatarUrl,
    required this.name,
    required this.isSpeaking,
    this.radius = 64,
    this.activeColor = const Color(0xFF4CAF50),
  });

  @override
  State<SpeakingAvatarWidget> createState() => _SpeakingAvatarWidgetState();
}

class _SpeakingAvatarWidgetState extends State<SpeakingAvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.trim().isNotEmpty
        ? widget.name.trim()[0].toUpperCase()
        : '?';

    final wavePadding = (widget.radius * 0.4).clamp(10.0, 32.0);
    final totalSize = (widget.radius + wavePadding) * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radiating soundwave ripples when speaking
          if (widget.isSpeaking)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(totalSize, totalSize),
                  painter: SoundwaveRipplePainter(
                    animationValue: _controller.value,
                    color: widget.activeColor,
                    baseRadius: widget.radius + 4,
                    waveCount: 3,
                  ),
                );
              },
            ),

          // Glowing Outer Border Ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSpeaking
                    ? widget.activeColor
                    : widget.activeColor.withValues(alpha: 0.35),
                width: widget.isSpeaking ? 3.5 : 2.5,
              ),
              boxShadow: widget.isSpeaking
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    ]
                  : [],
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: const Color(0xFF263238),
              backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.radius * 0.7,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
