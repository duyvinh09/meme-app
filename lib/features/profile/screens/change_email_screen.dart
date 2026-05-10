import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_filled_button.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
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

  bool get _canSubmitChangeEmail =>
      newEmailController.text.trim().isNotEmpty &&
      passwordController.text.trim().isNotEmpty;

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    newEmailController.addListener(_onFieldsChanged);
    passwordController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    newEmailController.removeListener(_onFieldsChanged);
    passwordController.removeListener(_onFieldsChanged);
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
        duration: AppDurations.snackBar,
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
    final l10n = context.l10n;

    final user = auth.user;
    final currentEmail = user?.email ?? '';
    final uid = user?.uid;

    final newEmail = newEmailController.text.trim();
    final password = passwordController.text.trim();

    if (uid == null || currentEmail.isEmpty) {
      _showMessage(l10n.accountNotFound);
      return;
    }

    if (!_isValidEmail(newEmail)) {
      _showMessage(l10n.invalidEmail);
      return;
    }

    if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
      _showMessage(l10n.emailSameAsCurrent);
      return;
    }

    if (password.length < 6) {
      _showMessage(l10n.pleaseEnterPassword);
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
      _showMessage(l10n.emailChangedSuccessfully);
      Navigator.pop(context);
    } else {
      _showMessage(l10n.deleteAccountError);
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
              canSubmit: _canSubmitChangeEmail,
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
    final l10n = context.l10n;
    return Row(
      children: [
        _RoundBackButton(onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changeEmailTitle,
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.changeEmailSubtitle,
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
    final l10n = context.l10n;
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
                  l10n.currentEmail,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentEmail.isEmpty ? l10n.unknown : currentEmail,
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
  final bool canSubmit;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  const _FormCard({
    required this.newEmailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.canSubmit,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            l10n.newEmailInfo,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 14),

          _InputLabel(
            label: l10n.newEmail,
          ),
          const SizedBox(height: 8),
          _InputBox(
            child: TextField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: AppColors.primaryBlue,
              decoration: InputDecoration(
                hintText: l10n.enterNewEmail,
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
            label: l10n.password,
          ),
          const SizedBox(height: 8),
          _InputBox(
            child: TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              cursorColor: AppColors.primaryBlue,
              onSubmitted: (_) {
                onSubmit();
              },
              decoration: InputDecoration(
                hintText: l10n.enterPasswordToConfirm,
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

          const _NoticeBox(),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: AsyncFilledButton(
              isLoading: isSaving,
              onPressedAsync: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor:
                    AppColors.primaryBlue.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizes.radiusMedium,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.updateEmail,
                style: const TextStyle(
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
  const _NoticeBox();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.changeEmailNotice,
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