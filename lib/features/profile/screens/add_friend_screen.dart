import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class AddFriendScreen extends StatefulWidget {
  final String? myUid;
  final UserRepository repo;

  const AddFriendScreen({
    super.key,
    required this.myUid,
    required this.repo,
  });

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  UserModel? foundUser;

  bool isSearching = false;
  bool isSubmitting = false;
  String? infoText;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final keyword = value.trim().toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        foundUser = null;
        infoText = null;
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      infoText = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      await _searchUser(keyword);
    });
  }

  Future<void> _searchUser(String username) async {
    try {
      final user = await widget.repo.findUserByUsername(username);
      debugPrint('FOUND USER: ${user?.uid} - ${user?.name} - ${user?.username}');

      if (!mounted) return;

      if (_controller.text.trim().toLowerCase() != username) {
        return;
      }

      if (user == null || user.uid == widget.myUid) {
        setState(() {
          foundUser = null;
          infoText = 'Không tìm thấy người dùng phù hợp';
          isSearching = false;
        });
        return;
      }

      setState(() {
        foundUser = user;
        infoText = null;
        isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        foundUser = null;
        infoText = 'Có lỗi khi tìm kiếm';
        isSearching = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    final myUid = widget.myUid;
    final user = foundUser;

    if (myUid == null || user == null || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await widget.repo.sendFriendRequest(
        myUid: myUid,
        targetUser: user,
      );

      if (!mounted) return;

      if (result != null && result != 'auto_accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'auto_accepted'
                ? 'Hai bạn đã tự động trở thành bạn bè'
                : 'Đã gửi lời mời kết bạn',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi lời mời thất bại'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFC61A);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface(context),
                                border: Border.all(
                                  color: AppColors.innerBorder(context),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.textPrimary(context),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Thêm bạn',
                            style: AppTextStyles.pageTitle(context).copyWith(
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: 152,
                    height: 152,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withOpacity(0.08),
                    ),
                    child: Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withOpacity(0.12),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 54,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Tìm người dùng Meme',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle(context).copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nhập username để gửi lời mời kết bạn và theo dõi chi tiêu chung',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SearchBox(
                    controller: _controller,
                    onChanged: _onSearchChanged,
                    cursorColor: yellow,
                  ),

                  const SizedBox(height: 20),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isSearching
                        ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    )
                        : foundUser != null
                        ? _FoundUserCard(
                      key: const ValueKey('found_user'),
                      user: foundUser!,
                      isSubmitting: isSubmitting,
                      onSendRequest: _sendRequest,
                      buttonColor: yellow,
                    )
                        : _SearchHintBox(
                      key: const ValueKey('hint_box'),
                    ),
                  ),

                  if (infoText != null && foundUser == null && !isSearching) ...[
                    const SizedBox(height: 14),
                    Text(
                      infoText!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color cursorColor;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary(context),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              cursorColor: cursorColor,
              style: AppTextStyles.body(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tìm theo username...',
                hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundUserCard extends StatelessWidget {
  final UserModel user;
  final bool isSubmitting;
  final VoidCallback onSendRequest;
  final Color buttonColor;

  const _FoundUserCard({
    super.key,
    required this.user,
    required this.isSubmitting,
    required this.onSendRequest,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final cardBg = isDark
        ? const Color(0xFF20232D)
        : const Color(0xFFF3F7FF);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFD8E6FF);

    final textPrimary = isDark ? Colors.white : const Color(0xFF172033);
    final textSecondary =
    isDark ? Colors.white.withOpacity(0.62) : const Color(0xFF667085);

    final avatarUrl = user.avatarUrl.trim();
    final name = user.name.trim().isEmpty ? 'Người dùng' : user.name.trim();
    final username = user.username.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.person_rounded,
                    size: 26,
                    color: textSecondary,
                  );
                },
              )
                  : Icon(
                Icons.person_rounded,
                size: 26,
                color: textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username.isEmpty ? '@username' : '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 86,
            height: 42,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSendRequest,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                AppColors.primaryBlue.withOpacity(0.55),
                disabledForegroundColor: Colors.white.withOpacity(0.85),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Thêm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
}

class _SearchHintBox extends StatelessWidget {
  const _SearchHintBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Column(
        children: [
          _SearchHintRow(
            icon: Icons.person_outline_rounded,
            text: 'Tìm bạn bè bằng username để kết nối',
            iconBg: AppColors.primaryBlue.withOpacity(0.15),
            iconColor: AppColors.primaryBlue,
          ),
          const SizedBox(height: 14),
          _SearchHintRow(
            icon: Icons.alternate_email_rounded,
            text: 'Nhập đúng username của người bạn muốn thêm',
            iconBg: Colors.orange.withOpacity(0.15),
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 14),
          _SearchHintRow(
            icon: Icons.link_rounded,
            text: 'Kết nối và theo dõi chi tiêu chung',
            iconBg: Colors.green.withOpacity(0.15),
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _SearchHintRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconBg;
  final Color iconColor;

  const _SearchHintRow({
    required this.icon,
    required this.text,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}