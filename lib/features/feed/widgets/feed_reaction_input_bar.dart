import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/services/local_settings_service.dart';

class FeedReactionInputBar extends StatefulWidget {
  final VoidCallback onOpenChat;
  final ValueChanged<String> onSelectEmoji;
  final bool isDark;

  const FeedReactionInputBar({
    super.key,
    required this.onOpenChat,
    required this.onSelectEmoji,
    this.isDark = true,
  });

  @override
  State<FeedReactionInputBar> createState() => _FeedReactionInputBarState();
}

class _FeedReactionInputBarState extends State<FeedReactionInputBar> {
  List<String> _displayedEmojis = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _displayedEmojis = _getEmojis(context);
      _initialized = true;
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
    HapticFeedback.selectionClick();
    try {
      // Record in storage so the next post / screen will have updated ranking,
      // but DO NOT call setState() on this post so the user can freely spam tap in place.
      context.read<LocalSettingsService>().recordEmojiUsage(emoji);
    } catch (_) {}
    widget.onSelectEmoji(emoji);
  }

  void _showEmojiPickerSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final emojis = _getEmojis(context);

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
                context.l10n.sendReactionTitle,
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
    final bgColor = widget.isDark
        ? const Color(0xFF26262A).withValues(alpha: 0.88)
        : const Color(0xFFE5E7EB).withValues(alpha: 0.92);
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final hintTextColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.55);

    final emojis = _displayedEmojis.isNotEmpty ? _displayedEmojis : _getEmojis(context);
    final quickEmojis = emojis.take(3).toList();

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: borderColor,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: "Tin nhắn..." tap target
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onOpenChat,
              child: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  context.l10n.feedMessageHint,
                  style: TextStyle(
                    color: hintTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Right: Dynamic Recent / Quick Emojis
          ...quickEmojis.map((emoji) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onEmojiTapped(emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }),

          // Plus / More Emojis Icon
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showEmojiPickerSheet(context),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
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
