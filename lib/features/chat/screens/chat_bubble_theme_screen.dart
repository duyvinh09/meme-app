import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../data/models/chat_bubble_theme.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/chat_bubble_decor_painter.dart';
import '../widgets/chat_bubble_widget.dart';

class ChatBubbleThemeScreen extends StatefulWidget {
  const ChatBubbleThemeScreen({super.key});

  @override
  State<ChatBubbleThemeScreen> createState() => _ChatBubbleThemeScreenState();
}

class _ChatBubbleThemeScreenState extends State<ChatBubbleThemeScreen> {
  late String _selectedThemeId;
  late String _initialThemeId;

  @override
  void initState() {
    super.initState();
    _initialThemeId = context.read<LocalSettingsService>().chatBubbleTheme;
    _selectedThemeId = _initialThemeId;
  }

  Future<void> _saveTheme() async {
    HapticFeedback.mediumImpact();
    final localSettings = context.read<LocalSettingsService>();
    final userRepo = context.read<UserRepository>();
    final uid = context.read<AuthController>().user?.uid;

    await localSettings.setChatBubbleTheme(_selectedThemeId);

    if (uid != null) {
      try {
        await userRepo.updateUserProfile(uid, {
          'chatBubbleTheme': _selectedThemeId,
        });
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context, _selectedThemeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark ? Colors.black : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF181A20) : const Color(0xFFF3F4F6);
    final currentTheme = ChatBubbleTheme.getTheme(_selectedThemeId);
    final hasChanged = _selectedThemeId != _initialThemeId;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(
            child: AppBackButton(),
          ),
        ),
        centerTitle: true,
        title: Text(
          l10n.chatBubbleThemeTitle,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton(
                onPressed: _saveTheme,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: hasChanged
                      ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                child: Text(
                  l10n.chatBubbleSave,
                  style: TextStyle(
                    color: hasChanged
                        ? AppColors.primaryBlue
                        : (isDark ? Colors.white38 : Colors.black38),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top Live Chat Preview Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: bgColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User message preview with selected bubble style
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    child: ChatBubbleDecoratedBox(
                      theme: currentTheme,
                      isMe: true,
                      child: Text(
                        l10n.chatBubblePreviewMe,
                        style: TextStyle(
                          color: currentTheme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Friend message preview (standard dark/light receiver bubble)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        ),
                        child: Center(
                          child: Text(
                            'B',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.68,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242526) : const Color(0xFFE4E6EB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            l10n.chatBubblePreviewFriend,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Bottom Grid ("Gợi ý")
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Little pull pill indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.chatBubbleSuggestions,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.chatBubbleAppliesToAll,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3-Column Theme Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: ChatBubbleTheme.allThemes.length,
                      itemBuilder: (context, index) {
                        final theme = ChatBubbleTheme.allThemes[index];
                        final isSelected = theme.id == _selectedThemeId;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedThemeId = theme.id;
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Miniature bubble preview card
                              Container(
                                width: double.infinity,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF242526) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? Colors.white : const Color(0xFF0084FF))
                                        : Colors.transparent,
                                    width: isSelected ? 2.0 : 0.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: (isDark ? Colors.white : const Color(0xFF0084FF))
                                            .withValues(alpha: 0.20),
                                        blurRadius: 10,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: _buildMiniBubbleThumbnail(theme),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                theme.getName(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark ? Colors.white : const Color(0xFF0084FF))
                                      : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBubbleThumbnail(ChatBubbleTheme theme) {
    return CustomPaint(
      foregroundPainter: ChatBubbleDecorPainter(
        theme: theme,
        isMe: true,
      ),
      child: Container(
        width: 66,
        height: 38,
        decoration: BoxDecoration(
          color: theme.gradient == null ? theme.backgroundColor : null,
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(10),
          border: theme.borderColor != null
              ? Border.all(color: theme.borderColor!, width: 1.2)
              : null,
          boxShadow: [
            if (theme.glowColor != null)
              BoxShadow(
                color: theme.glowColor!.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Center(
          child: Container(
            width: 24,
            height: 3.5,
            decoration: BoxDecoration(
              color: theme.textColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
