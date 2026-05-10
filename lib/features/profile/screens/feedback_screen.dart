import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/extensions/localization_extension.dart';
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

  bool didPrefillEmail = false;
  int currentLength = 0;

  bool _canSubmitFeedback() {
    final email = emailController.text.trim();
    final message = feedbackController.text.trim();
    if (email.isEmpty || message.isEmpty) return false;
    if (!_isValidEmail(email)) return false;
    if (message.length > maxLength) return false;
    return true;
  }

  void _syncFeedbackFields() {
    if (!mounted) return;
    setState(() {
      currentLength = feedbackController.text.length;
    });
  }

  @override
  void initState() {
    super.initState();

    emailController.addListener(_syncFeedbackFields);
    feedbackController.addListener(_syncFeedbackFields);
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
    emailController.removeListener(_syncFeedbackFields);
    feedbackController.removeListener(_syncFeedbackFields);
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
    final l10n = context.l10n;
    final subject = Uri.encodeComponent(l10n.feedbackEmailSubject);

    final body = Uri.encodeComponent(
      l10n.feedbackEmailBody(
        name.isEmpty ? l10n.unknown : name,
        username.isEmpty ? l10n.unknown : '@$username',
        fromEmail.isEmpty ? l10n.unknown : fromEmail,
        message,
      ),
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
    final auth = context.read<AuthController>();
    final profile = context.read<ProfileController>();
    final l10n = context.l10n;

    final message = feedbackController.text.trim();
    final email = emailController.text.trim();

    if (email.isNotEmpty && !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.invalidEmailGeneric),
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.pleaseEnterFeedback),
        ),
      );
      return;
    }

    if (message.length > maxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.feedbackTooLong(maxLength)),
        ),
      );
      return;
    }

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
          duration: AppDurations.snackBar,
          content: Text(
            emailOpened
                ? l10n.feedbackSentEmail
                : l10n.feedbackSaved,
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.feedbackError(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                          l10n.feedbackTitle,
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
                        l10n.sendFeedback,
                        style: AppTextStyles.pageTitle(context).copyWith(
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.feedbackSubtitle,
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
                  l10n.yourEmail,
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
                  l10n.emailPrefilledNote,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.yourFeedback,
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
                      hintText: l10n.feedbackHint,
                      hintStyle: AppTextStyles.bodySecondary(context),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                CustomButton(
                  height: 56,
                  borderRadius: AppSizes.radiusMedium,
                  text: l10n.sendFeedback,
                  icon: Icons.send_outlined,
                  onPressedAsync:
                      _canSubmitFeedback() ? submitFeedback : null,
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