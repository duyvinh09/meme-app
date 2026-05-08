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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? localError;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register(AuthController auth) async {
    final lang = context.read<LanguageProvider>();
    if (auth.isLoading) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      localError = null;
    });

    final nameError = AppValidators.requiredText(
      name,
      message: lang.t('auth.enter_display_name'),
    );
    if (nameError != null) {
      setState(() => localError = nameError);
      return;
    }

    final usernameError = AppValidators.username(username);
    if (usernameError != null) {
      setState(() => localError = usernameError);
      return;
    }

    final emailError = AppValidators.email(email);
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final passwordError = AppValidators.password(password);
    if (passwordError != null) {
      setState(() => localError = passwordError);
      return;
    }

    final ok = await auth.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );

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
                  icon: Icons.person_add_alt_1_rounded,
                ),
                const SizedBox(height: 18),

                Text(
                  lang.t('auth.create_account'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(context),
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
                        lang.t('auth.join_meme'),
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        lang.t('auth.create_profile'),
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: nameController,
                        hintText: lang.t('auth.display_name'),
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: usernameController,
                        hintText: lang.t('auth.username'),
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          lang.t('auth.username_hint'),
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          lang.t('auth.password_min'),
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (errorText != null && errorText.trim().isNotEmpty) ...[
                        _AuthErrorBox(text: errorText),
                        const SizedBox(height: 14),
                      ],

                      CustomButton(
                        text: lang.t('auth.register'),
                        isLoading: auth.isLoading,
                        onPressed: () => _register(auth),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySecondary(context),
                              children: const [
                                TextSpan(text: lang.t('auth.has_account')),
                                TextSpan(
                                  text: lang.t('auth.login'),
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