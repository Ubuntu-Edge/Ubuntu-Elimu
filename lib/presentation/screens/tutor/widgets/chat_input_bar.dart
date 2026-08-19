import 'package:flutter/material.dart';
import 'package:denizen_ai/denizen_ai.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final bool isTyping;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onStop,
    this.isTyping = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final DenizenVoiceSession _voiceSession = DenizenVoiceSession();
  bool _hasText = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _voiceSession.stopListening();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceSession.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      try {
        await _voiceSession.startListening(
          onResult: (text) {
            if (text.isNotEmpty) {
              setState(() {
                _controller.text = text;
              });
            }
          },
        );
      } catch (e) {
        setState(() => _isListening = false);
      }
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isTyping) return;
    if (_isListening) {
      _voiceSession.stopListening();
      _isListening = false;
    }
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(
          top: BorderSide(color: UEColors.bgCard, width: 0.5),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: UEColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isListening
                ? UEColors.accent
                : _hasText
                    ? UEColors.indigo.withOpacity(0.4)
                    : UEColors.bgBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.newline,
                style: UETypography.bodyMd.copyWith(fontSize: 14),
                cursorColor: UEColors.indigo,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening to speech...' : 'Ask anything...',
                  hintStyle: UETypography.bodyMd.copyWith(
                    color: _isListening ? UEColors.accent : UEColors.textDim,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _toggleListening,
              icon: Icon(
                _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                size: 20,
                color: _isListening ? UEColors.accent : UEColors.textDim,
              ),
              tooltip: _isListening ? 'Stop Listening' : 'Voice Input',
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isTyping
                    ? Colors.redAccent.withOpacity(0.85)
                    : _hasText
                        ? UEColors.indigo
                        : UEColors.bgBorder,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: widget.isTyping ? widget.onStop : (_hasText ? _send : null),
                icon: Icon(
                  widget.isTyping ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  size: widget.isTyping ? 20 : 18,
                  color: widget.isTyping || _hasText
                      ? Colors.white
                      : UEColors.textDim,
                ),
                tooltip: widget.isTyping ? 'Stop Generation' : 'Send Message',
              ),
            ),
          ],
        ),
      ),
    );
  }
}