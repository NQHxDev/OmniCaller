import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onSendMessage;
  final VoidCallback? onSendImage;
  final VoidCallback? onEmojiPressed;

  const ChatInputBar({
    super.key,
    this.controller,
    this.onSendMessage,
    this.onSendImage,
    this.onEmojiPressed,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final TextEditingController _textController;
  late final bool _isInternalController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _textController = widget.controller!;
      _isInternalController = false;
    } else {
      _textController = TextEditingController();
      _isInternalController = true;
    }

    _hasText = _textController.text.trim().isNotEmpty;
    _textController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChange);
    if (_isInternalController) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage?.call(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inputBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withAlpha(120)
        : theme.colorScheme.surfaceContainerHighest.withAlpha(90);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withAlpha(50),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: Nút gửi ảnh (Send Image)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: theme.colorScheme.primary,
                size: 24.0,
              ),
              tooltip: 'Gửi ảnh',
              onPressed: widget.onSendImage ?? () {},
            ),
            const SizedBox(width: 4),

            // Middle: Ô nhập tin nhắn (Text Input)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(22.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Right: Nút thả icon / emoji (Emoji/Icon button) or Send button when text is present
            if (_hasText)
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  color: theme.colorScheme.primary,
                  size: 24.0,
                ),
                tooltip: 'Gửi tin nhắn',
                onPressed: _handleSend,
              )
            else
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSmile,
                  color: theme.colorScheme.primary,
                  size: 24.0,
                ),
                tooltip: 'Thả icon / Emoji',
                onPressed: widget.onEmojiPressed ?? () {},
              ),
          ],
        ),
      ),
    );
  }
}
