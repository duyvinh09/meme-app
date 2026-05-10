import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Primary filled button. Use [onPressedAsync] for network/backend work so the
/// button disables and shows loading immediately until the future completes.
/// Do not pass both [onPressed] and [onPressedAsync].
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  /// Notifies when internal async busy state changes (for disabling sibling links).
  final ValueChanged<bool>? onBusyChanged;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? borderRadius;

  CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.onPressedAsync,
    this.onBusyChanged,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
  }) : assert(
          onPressed == null || onPressedAsync == null,
          'CustomButton: use only one of onPressed or onPressedAsync.',
        );

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _busy = false;

  bool get _effectiveLoading => widget.isLoading || _busy;

  Future<void> _runAsync() async {
    if (_busy) return;
    final fn = widget.onPressedAsync;
    if (fn == null) return;

    setState(() => _busy = true);
    widget.onBusyChanged?.call(true);

    try {
      await fn();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      widget.onBusyChanged?.call(false);
    }
  }

  void _fireAsync() {
    _runAsync();
  }

  void _onSyncTap() {
    if (_effectiveLoading) return;
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? AppSizes.buttonHeight;
    final radius = widget.borderRadius ?? AppSizes.radiusMedium;

    final async = widget.onPressedAsync;
    final sync = widget.onPressed;

    final VoidCallback? handler;
    if (async != null) {
      handler = _effectiveLoading ? null : _fireAsync;
    } else {
      handler =
          (sync == null || _effectiveLoading) ? null : _onSyncTap;
    }

    final bg = widget.backgroundColor ?? AppColors.primaryBlue;
    final fg = widget.foregroundColor ?? Colors.white;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: FilledButton(
        onPressed: handler,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _effectiveLoading
              ? SizedBox(
                  key: const ValueKey('button_loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Row(
                  key: const ValueKey('button_content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 20,
                        color: fg,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
