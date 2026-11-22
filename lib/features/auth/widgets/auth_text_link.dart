import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Account link with text-only hover and keyboard focus feedback.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary(context);
          }
          return states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed)
              ? AppColors.textPrimary(context)
              : AppColors.primaryBlue;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          final emphasized = states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed);
          return AppTextStyles.bodySecondary(context).copyWith(
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
            decoration: states.contains(WidgetState.focused)
                ? TextDecoration.underline
                : TextDecoration.none,
          );
        }),
      ),
      child: Text(label),
    );
  }
}
