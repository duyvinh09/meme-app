import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();

  File? selectedAvatar;
  bool didFillName = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didFillName) return;

    final profile = context.read<ProfileController>();
    nameController.text = profile.user?.name ?? '';
    didFillName = true;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    setState(() {
      selectedAvatar = File(file.path);
    });
  }

  Future<void> _saveProfile() async {
    final profile = context.read<ProfileController>();
    final auth = context.read<AuthController>();
    final uid = auth.user?.uid;

    if (uid == null || profile.isSaving) return;

    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên hiển thị'),
        ),
      );
      return;
    }

    final ok = await profile.updateProfile(
      uid: uid,
      name: name,
      avatarFile: selectedAvatar,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Cập nhật hồ sơ thành công' : 'Cập nhật hồ sơ thất bại',
        ),
      ),
    );

    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();

    final currentAvatar = profile.user?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            32,
          ),
          children: [
            _TopBar(
              isSaving: profile.isSaving,
              onCancel: () => Navigator.pop(context),
            ),

            const SizedBox(height: 34),

            Center(
              child: _AvatarPicker(
                selectedAvatar: selectedAvatar,
                currentAvatar: currentAvatar,
                onTap: pickAvatar,
              ),
            ),

            const SizedBox(height: 34),

            Text(
              'Tên',
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            _NameInput(
              controller: nameController,
            ),

            const SizedBox(height: 26),

            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: profile.isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: AppColors.primaryBlue.withOpacity(
                    0.45,
                  ),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.82),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: profile.isSaving
                      ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    key: ValueKey('save_text'),
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onCancel;

  const _TopBar({
    required this.isSaving,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: isSaving ? null : onCancel,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isSaving ? 0.55 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: AppColors.innerBorder(context),
                ),
              ),
              child: Text(
                'Huỷ',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Sửa',
          style: AppTextStyles.pageTitle(context).copyWith(
            fontSize: 24,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 84),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final File? selectedAvatar;
  final String currentAvatar;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.selectedAvatar,
    required this.currentAvatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCurrentAvatar = currentAvatar.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface(context),
            border: Border.all(
              color: AppColors.border(context),
              width: 1.2,
            ),
          ),
          child: ClipOval(
            child: selectedAvatar != null
                ? Image.file(
              selectedAvatar!,
              fit: BoxFit.cover,
            )
                : hasCurrentAvatar
                ? Image.network(
              currentAvatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _AvatarFallbackIcon();
              },
            )
                : const _AvatarFallbackIcon(),
          ),
        ),

        Positioned(
          right: -2,
          bottom: 8,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(
                    AppColors.isDark(context) ? 0.16 : 0.90,
                  ),
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallbackIcon extends StatelessWidget {
  const _AvatarFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: 72,
      color: AppColors.textSecondary(context),
    );
  }
}

class _NameInput extends StatelessWidget {
  final TextEditingController controller;

  const _NameInput({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 50,
      inputFormatters: [
        LengthLimitingTextInputFormatter(50),
      ],
      cursorColor: AppColors.primaryBlue,
      style: AppTextStyles.body(context).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Tên hiển thị',
        hintStyle: AppTextStyles.bodySecondary(context).copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.border(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}