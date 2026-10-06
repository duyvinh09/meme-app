import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/poll_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import 'poll_voters_sheet.dart';

class GroupPollBubble extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final Map<String, UserModel>? memberCache;

  const GroupPollBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.memberCache,
  });

  @override
  State<GroupPollBubble> createState() => _GroupPollBubbleState();
}

class _GroupPollBubbleState extends State<GroupPollBubble> {
  final Set<String> _stagedSelections = {};
  bool _isEditingVote = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initSelections();
  }

  @override
  void didUpdateWidget(covariant GroupPollBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.poll != widget.message.poll && !_isEditingVote) {
      _initSelections();
    }
  }

  void _initSelections() {
    final myUid = context.read<AuthController>().user?.uid;
    final poll = widget.message.poll;
    _stagedSelections.clear();
    if (myUid != null && poll != null) {
      _stagedSelections.addAll(poll.userSelectedOptionIds(myUid));
    }
  }

  void _toggleOption(String optionId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_stagedSelections.contains(optionId)) {
        _stagedSelections.remove(optionId);
      } else {
        _stagedSelections.add(optionId);
      }
    });
  }

  Future<void> _submitVote() async {
    final myUid = context.read<AuthController>().user?.uid;
    final poll = widget.message.poll;
    if (myUid == null || poll == null || _isSubmitting) return;

    if (_stagedSelections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pollSelectAtLeastOneError),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final chatRepo = context.read<ChatRepository>();
    final success = await chatRepo.votePoll(
      groupId: widget.message.groupId ?? widget.message.receiverId,
      messageId: widget.message.id,
      userId: myUid,
      selectedOptionIds: _stagedSelections.toList(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _isEditingVote = false;
        }
      });
    }
  }

  void _showVoters(PollOptionModel option) {
    final poll = widget.message.poll;
    if (poll == null) return;
    HapticFeedback.lightImpact();
    PollVotersSheet.show(
      context: context,
      poll: poll,
      option: option,
      memberCache: widget.memberCache,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.message.poll;
    if (poll == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final myUid = context.read<AuthController>().user?.uid ?? '';
    final hasVoted = poll.hasVoted(myUid);
    final isVotingMode = !hasVoted || _isEditingVote;

    final cardBg = isDark ? const Color(0xFF1F2026) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final totalVoters = poll.totalVoters;
    final mySelectedCount = poll.userSelectedOptionIds(myUid).length;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 295),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Badge + Question
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.5,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.poll_rounded,
                            size: 13,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            l10n.pollAttachmentLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.pollOptionsCount(poll.options.length),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  poll.question,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: textColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.8, color: borderColor),

          // Options List (Compact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              children: poll.options.map((option) {
                final isSelectedByMe = option.voterIds.contains(myUid);
                final isStaged = _stagedSelections.contains(option.id);
                final voteCount = option.voteCount;
                final percentage = totalVoters > 0
                    ? (voteCount / totalVoters * 100).round()
                    : 0;

                if (isVotingMode) {
                  return _buildVotingOptionTile(
                    option: option,
                    isStaged: isStaged,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    borderColor: borderColor,
                  );
                } else {
                  return _buildResultOptionTile(
                    option: option,
                    isSelectedByMe: isSelectedByMe,
                    voteCount: voteCount,
                    percentage: percentage,
                    isDark: isDark,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    l10n: l10n,
                  );
                }
              }).toList(),
            ),
          ),

          Divider(height: 1, thickness: 0.8, color: borderColor),

          // Footer (Compact single-line summary + buttons)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voters summary line (Compact, single line with no ugly wrap)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasVoted && !isVotingMode && mySelectedCount > 0
                            ? '${l10n.votersCount(totalVoters)} • ${l10n.youSelectedOptionsCount(mySelectedCount)}'
                            : l10n.votersCount(totalVoters),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // Action Buttons
                if (isVotingMode) ...[
                  Row(
                    children: [
                      if (hasVoted && _isEditingVote) ...[
                        Expanded(
                          child: SizedBox(
                            height: 33,
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditingVote = false;
                                        _initSelections();
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: subtextColor,
                                padding: EdgeInsets.zero,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                isEn ? 'Cancel' : 'Hủy',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 33,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting || _stagedSelections.isEmpty
                                    ? null
                                    : _submitVote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.voteAction,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Revote / Change Vote Button
                  SizedBox(
                    width: double.infinity,
                    height: 31,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isEditingVote = true;
                          _initSelections();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.35),
                        ),
                        backgroundColor: primaryColor.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.changeVoteAction,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingOptionTile({
    required PollOptionModel option,
    required bool isStaged,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final optionBg = isStaged
        ? primaryColor.withValues(alpha: isDark ? 0.16 : 0.08)
        : (isDark ? const Color(0xFF272830) : const Color(0xFFF9FAFB));
    final optionBorder = isStaged ? primaryColor : borderColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleOption(option.id),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
            decoration: BoxDecoration(
              color: optionBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: optionBorder,
                width: isStaged ? 1.3 : 0.9,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: isStaged ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isStaged ? primaryColor : borderColor,
                      width: 1.3,
                    ),
                  ),
                  child: isStaged
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isStaged ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
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

  Widget _buildResultOptionTile({
    required PollOptionModel option,
    required bool isSelectedByMe,
    required int voteCount,
    required int percentage,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
    required dynamic l10n,
  }) {
    final tileBg = isDark ? const Color(0xFF26272F) : const Color(0xFFF7F8FA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVoters(option),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSelectedByMe
                    ? primaryColor.withValues(alpha: 0.65)
                    : borderColor,
                width: isSelectedByMe ? 1.3 : 0.9,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Option text + percentage
                Row(
                  children: [
                    if (isSelectedByMe) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelectedByMe
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelectedByMe ? primaryColor : textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Progress Bar (Compact 4.5px)
                Stack(
                  children: [
                    Container(
                      height: 4.5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth *
                            (percentage / 100.0).clamp(0.0, 1.0);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          height: 4.5,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: isSelectedByMe
                                ? primaryColor
                                : primaryColor.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Bottom row: Vote count & tap to view voters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.votesCount(voteCount),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                    if (voteCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.viewOptionVoters,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 13,
                            color: primaryColor,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
