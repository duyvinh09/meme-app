import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import 'change_email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<ProfileController>().loadUser(uid);
      }

      loaded = true;
    }
  }

  List<Color> _heroGradient(BuildContext context) {
    if (AppColors.isDark(context)) {
      return const [
        Color(0xFF191A27),
        Color(0xFF141522),
        Color(0xFF1A1825),
      ];
    }

    return const [
      Color(0xFFF8F5FF),
      Color(0xFFF2F5FF),
      Color(0xFFF8F7FB),
    ];
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (password == null || password.trim().isEmpty) return;

    if (!context.mounted) return;

    await _deleteAccount(
      context: context,
      password: password.trim(),
    );
  }

  Future<void> _deleteAccount({
    required BuildContext context,
    required String password,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    final authController = context.read<AuthController>();
    final userRepository = context.read<UserRepository>();

    final authRepository = authController.authRepository;
    final firebaseUser = authController.user;

    final uid = firebaseUser?.uid;
    final email = firebaseUser?.email ?? '';

    if (firebaseUser == null || uid == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy tài khoản hiện tại'),
        ),
      );
      return;
    }

    try {
      FocusManager.instance.primaryFocus?.unfocus();

      await authRepository.reauthenticateWithPassword(
        email: email,
        password: password,
      );

      await userRepository.markUserAsDeleted(uid);

      await authRepository.deleteCurrentUser();

      await Future.delayed(const Duration(milliseconds: 250));

      if (!navigator.mounted) return;

      navigator.pushNamedAndRemoveUntil(
        RouteNames.login,
            (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể xoá tài khoản. Vui lòng kiểm tra mật khẩu hoặc đăng nhập lại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final auth = context.read<AuthController>();
    final user = profile.user;

    final createdAtText = user == null
        ? '--'
        : DateFormat('dd/MM/yyyy').format(user.createdAt);

    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Người dùng';

    final username = (user?.username.trim().isNotEmpty ?? false)
        ? user!.username.trim()
        : 'username';

    final avatarUrl = user?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Cá nhân',
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          8,
          AppSizes.pagePadding,
          AppSizes.bottomNavSafePadding,
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _heroGradient(context),
              ),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 150,
                      height: 150,
                      child: _RotatingAvatarRing(),
                    ),
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.isDark(context)
                              ? AppColors.darkSurface
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: AppColors.surface(context),
                        backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.textPrimary(context),
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, RouteNames.editProfile);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 26,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryPink.withOpacity(0.95),
                        size: 18,
                      ),
                    ),
                    Positioned(
                      top: 22,
                      right: 24,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryPurple.withOpacity(0.95),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context).copyWith(
                      fontSize: 28,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.calendar_month_rounded,
                      text: 'Tham gia: $createdAtText',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _SectionCard(
            children: [
              StreamBuilder<List<String>>(
                stream: auth.user == null
                    ? const Stream.empty()
                    : context
                    .read<UserRepository>()
                    .streamFriendIds(auth.user!.uid),
                builder: (context, snapshot) {
                  final friendCount = snapshot.data?.length ?? 0;

                  return _ProfileMenuTile(
                    icon: Icons.group_rounded,
                    title: '$friendCount Bạn bè',
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.friends);
                    },
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.groups_2_outlined,
                title: 'Nhóm',
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.groups);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.settings_outlined,
                title: 'Cài đặt',
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.settings);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.mail_outline,
                title: 'Đổi email đăng nhập',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangeEmailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.feedback_outlined,
                title: 'Góp ý',
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.feedback);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionCard(
            children: [
              _ProfileMenuTile(
                icon: Icons.delete_forever_rounded,
                title: 'Xoá tài khoản',
                iconColor: AppColors.expense,
                iconBackgroundColor: AppColors.expense.withOpacity(0.12),
                titleColor: AppColors.expense,
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
              ),
              _ProfileMenuTile(
                icon: Icons.logout_rounded,
                title: 'Đăng xuất',
                onTap: () async {
                  await auth.logout();

                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                          (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RotatingAvatarRing extends StatefulWidget {
  const _RotatingAvatarRing();

  @override
  State<_RotatingAvatarRing> createState() => _RotatingAvatarRingState();
}

class _RotatingAvatarRingState extends State<_RotatingAvatarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * math.pi * 2,
          child: CustomPaint(
            painter: _AvatarRingPainter(),
          ),
        );
      },
    );
  }
}

class _AvatarRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const SweepGradient(
        colors: [
          AppColors.primaryPink,
          AppColors.primaryPurple,
          AppColors.primaryPink,
        ],
      ).createShader(rect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = AppColors.primaryPink.withOpacity(0.25);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withOpacity(0.08)
              : AppColors.border(context),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary(context),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryBlue;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBackgroundColor ?? effectiveIconColor.withOpacity(0.12),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.body(context).copyWith(
          color: titleColor ?? AppColors.textPrimary(context),
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: titleColor == AppColors.expense
            ? AppColors.expense.withOpacity(0.75)
            : AppColors.textSecondary(context),
      ),
      onTap: onTap,
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final passwordController = TextEditingController();

  bool isDeleting = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      Navigator.pop(context, null);
    });
  }

  void _confirm() {
    final password = passwordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mật khẩu hiện tại'),
        ),
      );
      return;
    }

    setState(() {
      isDeleting = true;
    });

    FocusManager.instance.primaryFocus?.unfocus();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      Navigator.pop(context, password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: keyboardBottom + 20,
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 360,
              maxHeight: 520,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xoá tài khoản?',
                    style: AppTextStyles.sectionTitle(context).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Hành động này sẽ xoá tài khoản của bạn khỏi Meme. Bạn sẽ không thể đăng nhập lại bằng tài khoản này.',
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.expense.withOpacity(0.20),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.expense,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nếu bạn chỉ muốn rời app tạm thời, hãy chọn Đăng xuất thay vì xoá tài khoản.',
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: !isDeleting,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu hiện tại',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: isDeleting
                            ? null
                            : () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _confirm(),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isDeleting ? null : _cancel,
                          child: const Text('Huỷ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.expense,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isDeleting ? null : _confirm,
                          child: isDeleting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Xoá tài khoản',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}