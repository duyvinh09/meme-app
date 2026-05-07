import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const String adminEmail = 'dinhduyvinh69@gmail.com';
  static const int maxLength = 500;

  final emailController = TextEditingController();
  final feedbackController = TextEditingController();

  bool isSending = false;
  bool didPrefillEmail = false;
  int currentLength = 0;

  @override
  void initState() {
    super.initState();

    feedbackController.addListener(() {
      if (!mounted) return;

      setState(() {
        currentLength = feedbackController.text.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didPrefillEmail) return;

    final auth = context.read<AuthController>();
    final profile = context.read<ProfileController>();

    emailController.text = profile.user?.email ?? auth.user?.email ?? '';
    didPrefillEmail = true;
  }

  @override
  void dispose() {
    emailController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    if (email.trim().isEmpty) return true;

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  Future<bool> _sendEmailToAdmin({
    required String fromEmail,
    required String name,
    required String username,
    required String message,
  }) async {
    final subject = Uri.encodeComponent('Góp ý từ ứng dụng Meme');

    final body = Uri.encodeComponent(
      '''
Xin chào Admin,

Bạn vừa nhận được một góp ý mới từ ứng dụng Meme.

Thông tin người gửi:
- Tên: ${name.isEmpty ? 'Không rõ' : name}
- Username: ${username.isEmpty ? 'Không rõ' : '@$username'}
- Email: ${fromEmail.isEmpty ? 'Không cung cấp' : fromEmail}

Nội dung góp ý:
$message

---
Email này được tạo tự động từ màn Góp ý của app Meme.
''',
    );

    final uri = Uri.parse(
      'mailto:$adminEmail?subject=$subject&body=$body',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return opened;
    } catch (e) {
      debugPrint('Không thể mở app email: $e');
      return false;
    }
  }

  Future<void> submitFeedback() async {
    if (isSending) return;

    final auth = context.read<AuthController>();
    final profile = context.read<ProfileController>();

    final message = feedbackController.text.trim();
    final email = emailController.text.trim();

    if (email.isNotEmpty && !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không hợp lệ'),
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung góp ý'),
        ),
      );
      return;
    }

    if (message.length > maxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nội dung góp ý không được quá 500 ký tự'),
        ),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final name = profile.user?.name ?? '';
      final username = profile.user?.username ?? '';

      final emailOpened = await _sendEmailToAdmin(
        fromEmail: email,
        name: name,
        username: username,
        message: message,
      );

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': auth.user?.uid,
        'name': name,
        'username': username,
        'email': email,
        'message': message,
        'adminEmail': adminEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'status': emailOpened ? 'email_opened' : 'saved_only',
        'emailOpened': emailOpened,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailOpened
                ? 'Đã mở email để gửi góp ý cho admin'
                : 'Đã lưu góp ý. Thiết bị chưa mở được ứng dụng email.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi góp ý: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            12,
            AppSizes.pagePadding,
            24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CloseButton(
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Góp ý',
                          style: AppTextStyles.sectionTitle(context).copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withOpacity(0.18),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          size: 52,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gửi phản hồi',
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chia sẻ ý kiến, đề xuất hoặc báo lỗi để Meme ngày càng hoàn thiện hơn.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'Email của bạn',
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _FeedbackInputBox(
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: AppColors.primaryBlue,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'email@cuaban.com',
                      hintStyle: AppTextStyles.bodySecondary(context),
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.textSecondary(context),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email này được điền sẵn từ tài khoản của bạn.',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phản hồi của bạn *',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$currentLength/$maxLength',
                      style: AppTextStyles.caption(context).copyWith(
                        color: currentLength > maxLength
                            ? AppColors.expense
                            : AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _FeedbackInputBox(
                  child: TextField(
                    controller: feedbackController,
                    maxLines: 7,
                    maxLength: maxLength,
                    cursorColor: AppColors.primaryBlue,
                    style: AppTextStyles.body(context),
                    buildCounter: (
                        BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) {
                      return const SizedBox.shrink();
                    },
                    decoration: InputDecoration(
                      hintText:
                      'Chia sẻ ý kiến, báo lỗi hoặc đề xuất tính năng mới...',
                      hintStyle: AppTextStyles.bodySecondary(context),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: isSending ? null : submitFeedback,
                    icon: isSending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      isSending ? 'Đang gửi...' : 'Gửi phản hồi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColors.primaryBlue.withOpacity(0.45),
                      disabledForegroundColor: Colors.white.withOpacity(0.82),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                    ),
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

class _FeedbackInputBox extends StatelessWidget {
  final Widget child;

  const _FeedbackInputBox({
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

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface(context),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 28,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }
}