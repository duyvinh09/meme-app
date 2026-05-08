import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? localError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController auth) async {
    final lang = context.read<LanguageProvider>();
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

    final passwordError = AppValidators.requiredText(
      password,
      message: lang.t('auth.repassword'),
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
    final lang = context.watch<LanguageProvider>();

    final auth = context.watch<AuthController>();
    final errorText = localError ?? auth.error;

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
                  icon: Icons.add_a_photo_rounded,
                ),
                const SizedBox(height: 18),

                Text(
                  'Meme',
                  style: AppTextStyles.appTitle(context),
                ),
                const SizedBox(height: 8),

                Text(
                  lang.t('auth.create_account_desc'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context),
                ),
                const SizedBox(height: 24),

                _AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('auth.welcome_back'),
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        lang.t('auth.login_desc'),
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: emailController,
                        hintText: lang.t('auth.email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: passwordController,
                        hintText: lang.t('auth.password'),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline_rounded,
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.pushNamed(
                            context,
                            RouteNames.forgotPassword,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            lang.t('auth.forgot_password'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      if (errorText != null && errorText.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _AuthErrorBox(text: errorText),
                        const SizedBox(height: 14),
                      ] else
                        const SizedBox(height: 6),

                      CustomButton(
                        text: lang.t('auth.login'),
                        isLoading: auth.isLoading,
                        onPressed: () => _login(auth),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.pushNamed(
                            context,
                            RouteNames.register,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySecondary(context),
                              children: const [
                                TextSpan(text: lang.t('auth.no_account')),
                                TextSpan(
                                  text: lang.t('auth.register'),
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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