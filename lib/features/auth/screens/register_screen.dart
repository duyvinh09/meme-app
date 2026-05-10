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
  final confirmPasswordController = TextEditingController();

  String? localError;
  bool _primaryAuthBusy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  _PasswordStrength _passwordStrength(
      BuildContext context,
      String password,
      ) {
    final text = password.trim();

    if (text.isEmpty) {
      return _PasswordStrength(
        label: 'Chưa nhập mật khẩu',
        progress: 0,
        color: AppColors.textSecondary(context),
        description: 'Mật khẩu nên có chữ và số.',
      );
    }

    final hasLetter = RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~`]').hasMatch(text);
    final hasMinLength = text.length >= 6;
    final hasGoodLength = text.length >= 8;

    int score = 0;

    if (hasMinLength) score++;
    if (hasLetter) score++;
    if (hasNumber) score++;
    if (hasSpecial) score++;
    if (hasGoodLength) score++;

    if (!hasMinLength) {
      return const _PasswordStrength(
        label: 'Yếu',
        progress: 0.25,
        color: AppColors.expense,
        description: 'Tối thiểu 6 ký tự, nên có cả chữ và số.',
      );
    }

    if (hasLetter && hasNumber && score >= 3) {
      if (hasSpecial || hasGoodLength) {
        return const _PasswordStrength(
          label: 'Mạnh',
          progress: 1,
          color: AppColors.income,
          description: 'Mật khẩu tốt, có chữ, số và đủ độ dài.',
        );
      }

      return const _PasswordStrength(
        label: 'Vừa',
        progress: 0.65,
        color: AppColors.warning,
        description: 'Mật khẩu ổn. Thêm ký tự đặc biệt để mạnh hơn.',
      );
    }

    return const _PasswordStrength(
      label: 'Yếu',
      progress: 0.35,
      color: AppColors.expense,
      description: 'Nên có cả chữ và số để bảo mật hơn.',
    );
  }

  bool _passwordHasLetterAndNumber(String password) {
    final hasLetter = RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return hasLetter && hasNumber;
  }

  Future<void> _register(AuthController auth) async {
    if (auth.isLoading) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      localError = null;
    });

    final l10n = context.l10n;
    final nameError = AppValidators.requiredText(
      name,
      message: l10n.pleaseEnterName,
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

    if (!_passwordHasLetterAndNumber(password)) {
      setState(() {
        localError = 'Mật khẩu cần có cả chữ và số';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        localError = 'Vui lòng nhập lại mật khẩu';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        localError = 'Mật khẩu nhập lại không khớp';
      });
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
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final errorText = localError ?? auth.error;
    final authBusy = auth.isLoading || _primaryAuthBusy;
    final passwordStrength = _passwordStrength(
      context,
      passwordController.text,
    );
    final passwordsMatch = confirmPasswordController.text.trim().isNotEmpty &&
        passwordController.text.trim() == confirmPasswordController.text.trim();

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
                  l10n.createNewAccount,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 8),

                Text(
                  l10n.registerSlogan,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context),
                ),
                const SizedBox(height: 24),

                _AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.joinMeme,
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        l10n.registerSubtitle,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: nameController,
                        hintText: l10n.displayName,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: usernameController,
                        hintText: l10n.username,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          l10n.usernameHint,
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        onToggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      _PasswordStrengthView(
                        strength: passwordStrength,
                      ),
                      const SizedBox(height: 12),

                      _PasswordTextField(
                        controller: confirmPasswordController,
                        hintText: 'Nhập lại mật khẩu',
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        suffixStatusIcon: confirmPasswordController.text.trim().isEmpty
                            ? null
                            : passwordsMatch
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        suffixStatusColor: passwordsMatch
                            ? AppColors.income
                            : AppColors.expense,
                        onToggleObscure: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Mật khẩu tối thiểu 6 ký tự, nên gồm cả chữ và số.',
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),

                      if (errorText != null && errorText.trim().isNotEmpty) ...[
                        _AuthErrorBox(text: errorText),
                        const SizedBox(height: 14),
                      ],

                      CustomButton(
                        text: l10n.register,
                        isLoading: auth.isLoading,
                        onPressedAsync: () => _register(auth),
                        onBusyChanged: (busy) =>
                            setState(() => _primaryAuthBusy = busy),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: authBusy
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySecondary(context),
                              children: [
                                TextSpan(text: l10n.alreadyHaveAccount),
                                TextSpan(
                                  text: l10n.login,
                                  style: const TextStyle(
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
          color: Colors.white.withValues(
            alpha: AppColors.isDark(context) ? 0.14 : 0.92,
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

class _PasswordStrength {
  final String label;
  final double progress;
  final Color color;
  final String description;

  const _PasswordStrength({
    required this.label,
    required this.progress,
    required this.color,
    required this.description,
  });
}

class _PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback onToggleObscure;
  final IconData? suffixStatusIcon;
  final Color? suffixStatusColor;

  const _PasswordTextField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.textInputAction,
    required this.onToggleObscure,
    this.onChanged,
    this.suffixStatusIcon,
    this.suffixStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onChanged: onChanged,
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffixStatusIcon != null) ...[
              Icon(
                suffixStatusIcon,
                color: suffixStatusColor,
                size: 20,
              ),
              const SizedBox(width: 2),
            ],
            IconButton(
              tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: onToggleObscure,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
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

class _PasswordStrengthView extends StatelessWidget {
  final _PasswordStrength strength;

  const _PasswordStrengthView({
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: strength.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: strength.color.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: strength.color,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Độ mạnh mật khẩu: ${strength.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: strength.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: strength.progress,
              minHeight: 6,
              backgroundColor: AppColors.innerBorder(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                strength.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  strength.description,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
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