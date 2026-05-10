import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  bool _recoveryBusy = false;
  String? localError;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    final l10n = AppLocalizations.of(context)!;

    final email = emailController.text.trim();

    setState(() {
      localError = null;
    });

    final emailError = AppValidators.email(email);
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final ok = await auth.sendResetPassword(email);

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.recoveryEmailSent),
        ),
      );

      Navigator.pop(context);
    } else {
      setState(() {
        localError = auth.error ?? l10n.couldNotSendRecoveryEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              20,
              AppSizes.pagePadding,
              20,
            ),
            child: Column(
              children: [
                const _AuthLogo(
                  icon: Icons.lock_reset_rounded,
                ),
                const SizedBox(height: 18),

                Text(
                  l10n.forgotPasswordTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 8),

                Text(
                  l10n.forgotPasswordInstruction,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context),
                ),
                const SizedBox(height: 24),

                _AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recoveryPassword,
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        l10n.recoveryPasswordSubtitle,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: emailController,
                        hintText: l10n.enterEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),

                      if (localError != null &&
                          localError!.trim().isNotEmpty) ...[
                        _AuthErrorBox(text: localError!),
                        const SizedBox(height: 14),
                      ],

                      CustomButton(
                        text: l10n.sendRecoveryEmail,
                        onPressedAsync: () => _submit(auth),
                        onBusyChanged: (busy) =>
                            setState(() => _recoveryBusy = busy),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: _recoveryBusy
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.backToLogin,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  final IconData icon;

  const _AuthLogo({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue,
        border: Border.all(
          color: Colors.white.withOpacity(
            AppColors.isDark(context) ? 0.14 : 0.92,
          ),
          width: 3,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final Widget child;

  const _AuthCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              AppColors.isDark(context) ? 0.16 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  final String text;

  const _AuthErrorBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.isDark(context)
        ? const Color(0xFFFFB0B0)
        : AppColors.expenseDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.expense.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: errorColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: errorColor,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}