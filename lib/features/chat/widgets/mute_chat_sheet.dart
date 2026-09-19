import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/repositories/chat_repository.dart';

class MuteChatSheet {
  static Future<bool?> show(
    BuildContext context, {
    required String chatId,
    required String myUid,
    required bool isCurrentlyMuted,
    String? title,
    bool isGroup = false,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MuteChatBottomSheet(
        chatId: chatId,
        myUid: myUid,
        isCurrentlyMuted: isCurrentlyMuted,
        customTitle: title,
        isGroup: isGroup,
      ),
    );
  }
}

class _MuteChatBottomSheet extends StatelessWidget {
  final String chatId;
  final String myUid;
  final bool isCurrentlyMuted;
  final String? customTitle;
  final bool isGroup;

  const _MuteChatBottomSheet({
    required this.chatId,
    required this.myUid,
    required this.isCurrentlyMuted,
    this.customTitle,
    this.isGroup = false,
  });

  Future<void> _handleMuteOption(
    BuildContext context,
    Duration? duration,
    String durationLabelVi,
    String durationLabelEn,
  ) async {
    final chatRepo = context.read<ChatRepository>();
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    Navigator.pop(context, true);

    await chatRepo.muteChat(
      chatId: chatId,
      uid: myUid,
      duration: duration,
    );

    if (!context.mounted) return;

    final toastMsg = duration != null
        ? (isEn
            ? 'Muted notifications for $durationLabelEn'
            : 'Đã tắt thông báo $durationLabelVi')
        : (isEn
            ? 'Muted notifications until you turn it back on'
            : 'Đã tắt thông báo đến khi bạn thay đổi');

    AppToast.show(
      context,
      toastMsg,
      icon: Icons.notifications_off_rounded,
    );
  }

  Future<void> _handleUnmute(BuildContext context) async {
    final chatRepo = context.read<ChatRepository>();
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    Navigator.pop(context, false);

    await chatRepo.unmuteChat(
      chatId: chatId,
      uid: myUid,
    );

    if (!context.mounted) return;

    AppToast.show(
      context,
      isEn ? 'Unmuted notifications' : 'Đã bật lại thông báo',
      icon: Icons.notifications_active_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final sheetBg = isDark ? const Color(0xFF1E212B) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    const actionBlue = Color(0xFF3B82F6);

    final titleText = customTitle ??
        (isEn
            ? 'Mute notifications for this chat?'
            : 'Tắt thông báo về đoạn chat này?');

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ),

          if (isGroup)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
              child: Text(
                isEn
                    ? 'You will still receive @mentions and system updates.'
                    : 'Bạn vẫn sẽ nhận thông báo khi được tag (@) và cập nhật hệ thống.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ),

          Divider(height: 1, color: dividerColor),

          // Option: Unmute if currently muted
          if (isCurrentlyMuted) ...[
            _buildOptionButton(
              context: context,
              label: isEn ? 'Unmute notifications' : 'Bật lại thông báo',
              textColor: const Color(0xFF10B981),
              icon: Icons.notifications_active_rounded,
              isBold: true,
              onTap: () => _handleUnmute(context),
            ),
            Divider(height: 1, color: dividerColor),
          ],

          // Option 1: 15 minutes
          _buildOptionButton(
            context: context,
            label: isEn ? 'For 15 minutes' : 'Trong 15 phút',
            textColor: actionBlue,
            onTap: () => _handleMuteOption(
              context,
              const Duration(minutes: 15),
              'trong 15 phút',
              '15 minutes',
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // Option 2: 1 hour
          _buildOptionButton(
            context: context,
            label: isEn ? 'For 1 hour' : 'Trong 1 giờ',
            textColor: actionBlue,
            onTap: () => _handleMuteOption(
              context,
              const Duration(hours: 1),
              'trong 1 giờ',
              '1 hour',
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // Option 3: 8 hours
          _buildOptionButton(
            context: context,
            label: isEn ? 'For 8 hours' : 'Trong 8 giờ',
            textColor: actionBlue,
            onTap: () => _handleMuteOption(
              context,
              const Duration(hours: 8),
              'trong 8 giờ',
              '8 hours',
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // Option 4: 24 hours
          _buildOptionButton(
            context: context,
            label: isEn ? 'For 24 hours' : 'Trong 24 giờ',
            textColor: actionBlue,
            onTap: () => _handleMuteOption(
              context,
              const Duration(hours: 24),
              'trong 24 giờ',
              '24 hours',
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // Option 5: Until I change it (forever)
          _buildOptionButton(
            context: context,
            label: isEn ? 'Until I change it' : 'Đến khi tôi thay đổi',
            textColor: actionBlue,
            onTap: () => _handleMuteOption(
              context,
              null,
              'đến khi thay đổi',
              'until turned back on',
            ),
          ),
          Divider(height: 1, color: dividerColor),

          const SizedBox(height: 6),

          // Option 6: Cancel
          _buildOptionButton(
            context: context,
            label: isEn ? 'Cancel' : 'Hủy',
            textColor: isDark ? Colors.white70 : const Color(0xFF6B7280),
            isBold: true,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    IconData? icon,
    bool isBold = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
