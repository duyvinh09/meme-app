import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class FeedReactionInputBar extends StatefulWidget {
  final VoidCallback? onOpenChat;
  final ValueChanged<String> onSelectEmoji;
  final Future<bool> Function(String text)? onSendReply;
  final String authorName;
  final String authorAvatar;
  final String? authorFrame;
  final ValueChanged<bool>? onReplyingChanged;
  final bool? isReplying;
  final bool isDark;

  const FeedReactionInputBar({
    super.key,
    this.onOpenChat,
    required this.onSelectEmoji,
    this.onSendReply,
    this.authorName = '',
    this.authorAvatar = '',
    this.authorFrame,
    this.onReplyingChanged,
    this.isReplying,
    this.isDark = true,
  });

  @override
  State<FeedReactionInputBar> createState() => FeedReactionInputBarState();
}

class FeedReactionInputBarState extends State<FeedReactionInputBar> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _displayedEmojis = [];
  bool _initialized = false;
  bool _isReplying = false;
  bool _hasText = false;
  bool _isSending = false;
  bool _keyboardWasOpen = false;

  bool get isReplying => _isReplying;

  @override
  void initState() {
    super.initState();
    _isReplying = widget.isReplying ?? false;
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (_isReplying) {
      if (bottomInset > 0) {
        _keyboardWasOpen = true;
      } else if (_keyboardWasOpen && bottomInset == 0) {
        _keyboardWasOpen = false;
        _closeReply();
      }
    } else {
      _keyboardWasOpen = bottomInset > 0;
    }
  }

  @override
  void didUpdateWidget(FeedReactionInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReplying != null && widget.isReplying != _isReplying) {
      setState(() {
        _isReplying = widget.isReplying!;
      });
      if (!_isReplying) {
        _focusNode.unfocus();
        _textController.clear();
        _hasText = false;
      }
    }
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (!_isReplying) {
        setState(() {
          _isReplying = true;
        });
        widget.onReplyingChanged?.call(true);
      }
    } else {
      if (_isReplying) {
        _closeReply();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _displayedEmojis = _getEmojis(context);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void openReply() {
    if (!_isReplying) {
      setState(() {
        _isReplying = true;
      });
      widget.onReplyingChanged?.call(true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeReply() {
    if (!_isReplying) return;
    _focusNode.unfocus();
    setState(() {
      _isReplying = false;
      _textController.clear();
      _hasText = false;
    });
    widget.onReplyingChanged?.call(false);
  }

  Future<void> _handleSendReply() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    AppHaptics.lightImpact();

    try {
      if (widget.onSendReply != null) {
        final success = await widget.onSendReply!(text);
        if (success && mounted) {
          _closeReply();
        }
      } else {
        _closeReply();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  List<String> _getEmojis(BuildContext context) {
    try {
      final localSettings = context.read<LocalSettingsService>();
      return List<String>.from(localSettings.recentEmojis);
    } catch (_) {
      return List<String>.from(LocalSettingsService.defaultAllEmojis);
    }
  }

  void _onEmojiTapped(String emoji) {
    AppHaptics.selectionClick();
    try {
      context.read<LocalSettingsService>().recordEmojiUsage(emoji);
    } catch (_) {}
    widget.onSelectEmoji(emoji);
  }

  void _showEmojiPickerSheet(BuildContext context) {
    AppHaptics.lightImpact();
    final emojis = _getEmojis(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E212B) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVi ? 'Gửi biểu cảm' : 'Send reaction',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: emojis.map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _onEmojiTapped(emoji);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final isDark = widget.isDark;
    final pillBgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
        : const Color(0xFFE5E7EB).withValues(alpha: 0.95);
    final pillBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    const hintTextColor = Color(0xFF8E8E93);

    final emojis = _displayedEmojis.isNotEmpty ? _displayedEmojis : _getEmojis(context);
    final quickEmojis = emojis.take(3).toList();

    if (_isReplying) {
      // FULL REPLY MODE: Header (Centered & Linked) + Full Width Pill Input + Send Button
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.authorName.isNotEmpty || widget.authorAvatar.isNotEmpty)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * (1 - animValue)),
                  child: Opacity(
                    opacity: animValue,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarWithFrame(
                      avatarUrl: widget.authorAvatar,
                      frameId: widget.authorFrame ?? 'default',
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi ? 'Đang trả lời' : 'Replying to',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.black.withValues(alpha: 0.75),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          widget.authorName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: pillBgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: pillBorderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 8),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        autofocus: true,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendReply(),
                        cursorColor: isDark ? Colors.white : Colors.black87,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hintText: widget.authorName.isNotEmpty
                              ? (isVi ? 'Trả lời ${widget.authorName}...' : 'Reply to ${widget.authorName}...')
                              : (isVi ? 'Nhập tin nhắn...' : 'Type a message...'),
                          hintStyle: const TextStyle(
                            color: hintTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: GestureDetector(
                    onTap: (_hasText && !_isSending) ? _handleSendReply : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _hasText
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D5DB)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isSending
                            ? SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                size: 19,
                                color: _hasText
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.35)),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // COLLAPSED MODE: Direct 1-tap message button + quick reaction emojis
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: pillBgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: pillBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Message button - 1 tap triggers typing mode immediately
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: openReply,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 8, top: 14, bottom: 14),
                child: Text(
                  isVi ? 'Tin nhắn...' : 'Message...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: hintTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Right: Quick emojis + Sheet button
          ...quickEmojis.map((emoji) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onEmojiTapped(emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showEmojiPickerSheet(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 8, 14, 8),
              child: Icon(
                Icons.add_reaction_outlined,
                color: widget.isDark ? Colors.white70 : Colors.black54,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
