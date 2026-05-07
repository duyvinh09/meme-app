import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? name;
  final bool showBorder;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 22,
    this.name,
    this.showBorder = false,
    this.borderColor,
    this.backgroundColor,
  });

  String get _initial {
    final value = name?.trim() ?? '';

    if (value.isEmpty) return '';

    return value.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: showBorder ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
          color: borderColor ?? AppColors.border(context),
          width: 1.2,
        )
            : null,
      ),
      child: ClipOval(
        child: cleanUrl.isEmpty
            ? _AvatarFallback(
          radius: radius,
          initial: _initial,
          backgroundColor: backgroundColor,
        )
            : Image.network(
          cleanUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _AvatarFallback(
              radius: radius,
              initial: _initial,
              backgroundColor: backgroundColor,
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return _AvatarFallback(
              radius: radius,
              initial: _initial,
              backgroundColor: backgroundColor,
              isLoading: true,
            );
          },
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final double radius;
  final String initial;
  final Color? backgroundColor;
  final bool isLoading;

  const _AvatarFallback({
    required this.radius,
    required this.initial,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surface(context);

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: bg,
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
        width: radius * 0.72,
        height: radius * 0.72,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
          : initial.isNotEmpty
          ? Text(
        initial,
        style: TextStyle(
          color: AppColors.textPrimary(context),
          fontSize: radius * 0.82,
          fontWeight: FontWeight.w900,
        ),
      )
          : Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary(context),
        size: radius * 1.05,
      ),
    );
  }
}