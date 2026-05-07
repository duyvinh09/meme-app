import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final newEmailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    newEmailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final profile = context.read<ProfileController>();
    final authRepository = context.read<AuthRepository>();

    final user = auth.user;
    final currentEmail = user?.email ?? '';
    final uid = user?.uid;

    final newEmail = newEmailController.text.trim();
    final password = passwordController.text.trim();

    if (uid == null || currentEmail.isEmpty) {
      _showMessage('Không tìm thấy tài khoản hiện tại');
      return;
    }

    if (!_isValidEmail(newEmail)) {
      _showMessage('Email mới không hợp lệ');
      return;
    }

    if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
      _showMessage('Email mới đang trùng với email hiện tại');
      return;
    }

    if (password.length < 6) {
      _showMessage('Vui lòng nhập mật khẩu hiện tại');
      return;
    }

    final ok = await profile.updateEmailAddress(
      authRepository: authRepository,
      uid: uid,
      currentEmail: currentEmail,
      currentPassword: password,
      newEmail: newEmail,
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Đã đổi email đăng nhập thành công');
      Navigator.pop(context);
    } else {
      _showMessage(
        'Không thể đổi email. Vui lòng kiểm tra mật khẩu hoặc đăng nhập lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final currentEmail = context.read<AuthController>().user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            12,
            AppSizes.pagePadding,
            28,
          ),
          children: [
            _ChangeEmailHeader(
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 18),

            _IntroCard(
              currentEmail: currentEmail,
            ),

            const SizedBox(height: 16),

            _FormCard(
              newEmailController: newEmailController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              isSaving: profile.isSaving,
              onTogglePassword: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeEmailHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _ChangeEmailHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundBackButton(onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi email đăng nhập',
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Cập nhật email dùng để đăng nhập tài khoản của bạn',
                style: AppTextStyles.caption(context).copyWith(
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RoundBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      shape: CircleBorder(
        side: BorderSide(
          color: AppColors.border(context),
        ),
      ),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String currentEmail;

  const _IntroCard({
    required this.currentEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.alternate_email_rounded,
              color: AppColors.primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email hiện tại',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentEmail.isEmpty ? 'Không rõ' : currentEmail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final TextEditingController newEmailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSaving;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.newEmailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin email mới',
            style: AppTextStyles.body(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 14),

          _InputLabel(
            label: 'Email mới',
          ),
          const SizedBox(height: 8),
          _InputBox(
            child: TextField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: AppColors.primaryBlue,
              decoration: InputDecoration(
                hintText: 'Nhập email mới của bạn',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.textSecondary(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _InputLabel(
            label: 'Mật khẩu hiện tại',
          ),
          const SizedBox(height: 8),
          _InputBox(
            child: TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              cursorColor: AppColors.primaryBlue,
              onSubmitted: (_) {
                if (!isSaving) onSubmit();
              },
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu để xác nhận',
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textSecondary(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _NoticeBox(),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: isSaving ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusMedium,
                  ),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Cập nhật email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;

  const _InputLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption(context).copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryBlue,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Để bảo vệ tài khoản, bạn cần nhập lại mật khẩu hiện tại trước khi đổi email đăng nhập.',
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;

  const _InputBox({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: child,
    );
  }
}