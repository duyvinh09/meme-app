import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/extensions/localization_extension.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_text_link.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? localError;
  bool _primaryAuthBusy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController auth) async {
    FocusScope.of(context).unfocus();

    if (auth.isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      localError = null;
    });

    final emailError = AppValidators.email(email);
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final l10n = context.l10n;
    final passwordError = AppValidators.requiredText(
      password,
      message: l10n.pleaseEnterPasswordLogin,
    );
    if (passwordError != null) {
      setState(() => localError = passwordError);
      return;
    }

    final ok = await auth.login(email, password);

    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.mainShell,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final errorText = localError ?? auth.error;
    final authBusy = auth.isLoading || _primaryAuthBusy;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                20,
                AppSizes.pagePadding,
                20,
              ),
              child: Column(
                children: [
                  AuthBrandHeader(
                    title: l10n.welcomeBack,
                    subtitle: l10n.appSlogan,
                    compact: false,
                  ),
                  const SizedBox(height: AppSizes.gapXLarge),
                  _AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.login,
                          style: AppTextStyles.sectionTitle(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          style: AppTextStyles.bodySecondary(context),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: emailController,
                          hintText: l10n.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),
                        _PasswordTextField(
                          controller: passwordController,
                          hintText: l10n.password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onToggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AuthTextLink(
                            onPressed: authBusy
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.pushNamed(
                                        context, RouteNames.forgotPassword);
                                  },
                            label: l10n.forgotPassword,
                          ),
                        ),
                        if (errorText != null &&
                            errorText.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _AuthErrorBox(text: errorText),
                          const SizedBox(height: 14),
                        ] else
                          const SizedBox(height: 6),
                        CustomButton(
                          text: l10n.login,
                          isLoading: auth.isLoading,
                          onPressedAsync: () => _login(auth),
                          onBusyChanged: (busy) =>
                              setState(() => _primaryAuthBusy = busy),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l10n.dontHaveAccount.trim(),
                                style: AppTextStyles.bodySecondary(context),
                              ),
                              AuthTextLink(
                                onPressed: authBusy
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.pushNamed(
                                            context, RouteNames.register);
                                      },
                                label: l10n.register,
                              ),
                            ],
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
      constraints: const BoxConstraints(maxWidth: 480),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.gapXLarge),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.05,
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

class _PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputAction textInputAction;
  final VoidCallback onToggleObscure;

  const _PasswordTextField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.textInputAction,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      cursorColor: AppColors.primaryBlue,
      style: AppTextStyles.body(context).copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySecondary(context).copyWith(
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textSecondary(context),
        ),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary(context),
          ),
        ),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: AppColors.innerBorder(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: AppColors.innerBorder(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.3,
          ),
        ),
      ),
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
        color: AppColors.expense.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.22),
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
