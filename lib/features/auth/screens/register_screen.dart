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
      message: 'Vui lòng nhập tên hiển thị',
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
                  'Tạo tài khoản mới ✨',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 8),

                Text(
                  'Bắt đầu lưu khoảnh khắc chi tiêu theo cách vui hơn, thật hơn.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context),
                ),
                const SizedBox(height: 24),

                _AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tham gia Meme',
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Tạo hồ sơ để quản lý chi tiêu, lưu ảnh và kết nối với bạn bè.',
                        style: AppTextStyles.bodySecondary(context),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: nameController,
                        hintText: 'Tên hiển thị',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Dùng 3-20 ký tự: chữ thường, số, dấu . hoặc _',
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Mật khẩu',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline_rounded,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Mật khẩu tối thiểu 6 ký tự',
                          style: AppTextStyles.caption(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (errorText != null && errorText.trim().isNotEmpty) ...[
                        _AuthErrorBox(text: errorText),
                        const SizedBox(height: 14),
                      ],

                      CustomButton(
                        text: 'Đăng ký',
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
                                TextSpan(text: 'Đã có tài khoản? '),
                                TextSpan(
                                  text: 'Đăng nhập',
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