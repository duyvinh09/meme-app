import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  DateTime? _dateOfBirth;
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
    final l10n = context.l10n;
    final text = password.trim();

    if (text.isEmpty) {
      return _PasswordStrength(
        label: l10n.passwordStrengthNone,
        progress: 0,
        color: AppColors.textSecondary(context),
        description: l10n.passwordDescEmpty,
      );
    }

    final hasLower = RegExp(r'[a-zà-ỹ]').hasMatch(text);
    final hasUpper = RegExp(r'[A-ZÀ-Ỹ]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~` ]').hasMatch(text);
    final hasMinLength = text.length >= 6;
    final hasGoodLength = text.length >= 8;

    int passedCount = 0;
    if (hasMinLength) passedCount++;
    if (hasLower) passedCount++;
    if (hasUpper) passedCount++;
    if (hasNumber) passedCount++;
    if (hasSpecial) passedCount++;

    final meetsAllRequirements =
        hasMinLength && hasLower && hasUpper && hasNumber && hasSpecial;

    if (!hasMinLength) {
      return _PasswordStrength(
        label: l10n.passwordStrengthWeak,
        progress: (passedCount / 5.0) * 0.35,
        color: AppColors.expense,
        description: l10n.passwordDescTooShort,
      );
    }

    if (meetsAllRequirements) {
      if (hasGoodLength) {
        return _PasswordStrength(
          label: l10n.passwordStrengthStrong,
          progress: 1.0,
          color: AppColors.income,
          description: l10n.passwordDescStrong,
        );
      }

      return _PasswordStrength(
        label: l10n.passwordStrengthMedium,
        progress: 0.8,
        color: AppColors.warning,
        description: l10n.passwordDescMedium,
      );
    }

    return _PasswordStrength(
      label: l10n.passwordStrengthWeak,
      progress: (passedCount / 5.0) * 0.65,
      color: AppColors.expense,
      description: l10n.passwordDescNeedBoth,
    );
  }

  bool _isPasswordComplex(String password) {
    final text = password.trim();
    if (text.length < 6) return false;
    final hasLower = RegExp(r'[a-zà-ỹ]').hasMatch(text);
    final hasUpper = RegExp(r'[A-ZÀ-Ỹ]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~` ]').hasMatch(text);

    return hasLower && hasUpper && hasNumber && hasSpecial;
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    DateTime tempDate = _dateOfBirth ?? DateTime(now.year, now.month, now.day);
    final isDark = AppColors.isDark(context);
    final l10n = context.l10n;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1D29) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryPink.withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.selectBirthday,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy').format(tempDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? ColorScheme.dark(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  surface: const Color(0xFF1B1D29),
                                  onSurface: Colors.white,
                                )
                              : ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate.isAfter(now) ? now : tempDate,
                          firstDate: DateTime(1900),
                          lastDate: now,
                          onDateChanged: (newDate) {
                            setSheetState(() {
                              tempDate = newDate;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetCtx, tempDate),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.confirm,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
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

    final usernameError = AppValidators.username(
      username,
      requiredMessage: l10n.pleaseEnterUsername,
      invalidMessage: l10n.invalidUsername,
    );
    if (usernameError != null) {
      setState(() => localError = usernameError);
      return;
    }

    final emailError = AppValidators.email(
      email,
      requiredMessage: l10n.pleaseEnterEmail,
      invalidMessage: l10n.invalidEmailGeneric,
    );
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final passwordError = AppValidators.password(
      password,
      requiredMessage: l10n.pleaseEnterPasswordLogin,
      minLengthMessage: l10n.passwordMinLength,
    );
    if (passwordError != null) {
      setState(() => localError = passwordError);
      return;
    }

    if (!_isPasswordComplex(password)) {
      setState(() {
        localError = l10n.passwordNeedsLetterAndNumber;
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        localError = l10n.pleaseConfirmPassword;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        localError = l10n.passwordsDoNotMatch;
      });
      return;
    }

    final ok = await auth.register(
      name: name,
      username: username,
      email: email,
      password: password,
      dateOfBirth: _dateOfBirth,
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

                      // Ngày sinh (Date of birth)
                      InkWell(
                        onTap: authBusy ? null : _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            border: Border.all(
                              color: AppColors.innerBorder(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                color: _dateOfBirth != null
                                    ? AppColors.primaryPink
                                    : AppColors.textSecondary(context),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dateOfBirth != null
                                      ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                                      : context.l10n.birthdayOptional,
                                  style: _dateOfBirth != null
                                      ? AppTextStyles.body(context).copyWith(
                                          fontWeight: FontWeight.w600,
                                        )
                                      : AppTextStyles.bodySecondary(context),
                                ),
                              ),
                              if (_dateOfBirth != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _dateOfBirth = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary(context),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary(context),
                                ),
                            ],
                          ),
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
                        hintText: l10n.confirmPassword,
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
                          l10n.passwordRequirementHint,
                          style: AppTextStyles.caption(context),
                        ),
                      ),
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
      constraints: const BoxConstraints(maxWidth: 480),
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
              tooltip: obscureText
                  ? context.l10n.showPassword
                  : context.l10n.hidePassword,
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
        color: strength.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: strength.color.withValues(alpha: 0.18),
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
                  context.l10n.passwordStrengthTitle(strength.label),
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