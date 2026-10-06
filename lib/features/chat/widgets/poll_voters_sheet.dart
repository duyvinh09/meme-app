import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/poll_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class PollVotersSheet extends StatefulWidget {
  final PollModel poll;
  final PollOptionModel option;
  final Map<String, UserModel>? memberCache;

  const PollVotersSheet({
    super.key,
    required this.poll,
    required this.option,
    this.memberCache,
  });

  static Future<void> show({
    required BuildContext context,
    required PollModel poll,
    required PollOptionModel option,
    Map<String, UserModel>? memberCache,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PollVotersSheet(
        poll: poll,
        option: option,
        memberCache: memberCache,
      ),
    );
  }

  @override
  State<PollVotersSheet> createState() => _PollVotersSheetState();
}

class _PollVotersSheetState extends State<PollVotersSheet> {
  final Map<String, UserModel> _users = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.memberCache != null) {
      _users.addAll(widget.memberCache!);
    }
    _loadVoters();
  }

  Future<void> _loadVoters() async {
    final voterIds = widget.option.voterIds;
    final userRepo = context.read<UserRepository>();

    final missingUids = voterIds.where((uid) => !_users.containsKey(uid)).toList();

    if (missingUids.isNotEmpty) {
      for (final uid in missingUids) {
        try {
          final profile = await userRepo.getUserProfile(uid);
          if (profile != null && mounted) {
            _users[uid] = profile;
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final bgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.45);

    final voterIds = widget.option.voterIds;
    final totalVoters = widget.poll.totalVoters;
    final pct = totalVoters > 0
        ? (widget.option.voteCount / totalVoters * 100).round()
        : 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
        minHeight: 240,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.option.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$pct% • ${l10n.votesCount(widget.option.voteCount)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Voters List
            Expanded(
              child: voterIds.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noVotersYet,
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                      ),
                    )
                  : _isLoading && _users.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: voterIds.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 56),
                          itemBuilder: (context, index) {
                            final uid = voterIds[index];
                            final user = _users[uid];
                            final isEn = Localizations.localeOf(context).languageCode == 'en';
                            final displayName = user?.name.isNotEmpty == true
                                ? user!.name
                                : (user?.username.isNotEmpty == true
                                    ? '@${user!.username}'
                                    : (isEn ? 'Member' : 'Thành viên'));
                            final username = user?.username.isNotEmpty == true
                                ? '@${user!.username}'
                                : null;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  AvatarWithFrame(
                                    avatarUrl: user?.avatarUrl ?? '',
                                    frameId: user?.avatarFrame,
                                    size: 42,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        if (username != null &&
                                            username != displayName) ...[
                                          const SizedBox(height: 1),
                                          Text(
                                            username,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: hintColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: primaryColor,
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
    );
  }
}
