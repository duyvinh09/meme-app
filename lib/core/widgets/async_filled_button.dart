import 'package:flutter/material.dart';

/// [FilledButton] — một lần bấm → khóa + loading đến khi [onPressedAsync] xong.
class AsyncFilledButton extends StatefulWidget {
  const AsyncFilledButton({
    super.key,
    required this.child,
    this.onPressedAsync,
    this.style,
    this.onBusyChanged,
    this.locked = false,
    this.isLoading = false,
  });

  final Widget child;
  final Future<void> Function()? onPressedAsync;
  final ButtonStyle? style;
  final ValueChanged<bool>? onBusyChanged;

  /// Khóa khi nút khác trong cùng nhóm đang chạy (ví dụ Từ chối / Chấp nhận).
  final bool locked;

  /// Loading từ bên ngoài (controller).
  final bool isLoading;

  @override
  State<AsyncFilledButton> createState() => _AsyncFilledButtonState();
}

class _AsyncFilledButtonState extends State<AsyncFilledButton> {
  bool _busy = false;

  Future<void> _run() async {
    final fn = widget.onPressedAsync;
    if (fn == null || _busy || widget.isLoading || widget.locked) return;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final async = widget.onPressedAsync;
    final showSpinner = _busy || widget.isLoading;
    final enabled =
        async != null && !_busy && !widget.isLoading && !widget.locked;

    return FilledButton(
      style: widget.style,
      onPressed: enabled ? () => _run() : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: showSpinner
            ? SizedBox(
                key: const ValueKey('async_filled_loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onPrimary,
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('async_filled_child'),
                child: widget.child,
              ),
      ),
    );
  }
}

/// [OutlinedButton] — cùng hành vi async như [AsyncFilledButton].
class AsyncOutlinedButton extends StatefulWidget {
  const AsyncOutlinedButton({
    super.key,
    required this.child,
    this.onPressedAsync,
    this.style,
    this.onBusyChanged,
    this.locked = false,
    this.isLoading = false,
  });

  final Widget child;
  final Future<void> Function()? onPressedAsync;
  final ButtonStyle? style;
  final ValueChanged<bool>? onBusyChanged;
  final bool locked;
  final bool isLoading;

  @override
  State<AsyncOutlinedButton> createState() => _AsyncOutlinedButtonState();
}

class _AsyncOutlinedButtonState extends State<AsyncOutlinedButton> {
  bool _busy = false;

  Future<void> _run() async {
    final fn = widget.onPressedAsync;
    if (fn == null || _busy || widget.isLoading || widget.locked) return;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final async = widget.onPressedAsync;
    final showSpinner = _busy || widget.isLoading;
    final enabled =
        async != null && !_busy && !widget.isLoading && !widget.locked;

    return OutlinedButton(
      style: widget.style,
      onPressed: enabled ? () => _run() : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: showSpinner
            ? SizedBox(
                key: const ValueKey('async_outlined_loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('async_outlined_child'),
                child: widget.child,
              ),
      ),
    );
  }
}

/// [TextButton] — async + loading (liên kết huỷ, xóa nhẹ, …).
class AsyncTextButton extends StatefulWidget {
  const AsyncTextButton({
    super.key,
    required this.child,
    this.onPressedAsync,
    this.style,
    this.onBusyChanged,
    this.locked = false,
    this.isLoading = false,
  });

  final Widget child;
  final Future<void> Function()? onPressedAsync;
  final ButtonStyle? style;
  final ValueChanged<bool>? onBusyChanged;
  final bool locked;
  final bool isLoading;

  @override
  State<AsyncTextButton> createState() => _AsyncTextButtonState();
}

class _AsyncTextButtonState extends State<AsyncTextButton> {
  bool _busy = false;

  Future<void> _run() async {
    final fn = widget.onPressedAsync;
    if (fn == null || _busy || widget.isLoading || widget.locked) return;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final async = widget.onPressedAsync;
    final showSpinner = _busy || widget.isLoading;
    final enabled =
        async != null && !_busy && !widget.isLoading && !widget.locked;

    final fg =
        widget.style?.foregroundColor?.resolve(<WidgetState>{}) ??
            scheme.primary;

    return TextButton(
      style: widget.style,
      onPressed: enabled ? () => _run() : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: showSpinner
            ? SizedBox(
                key: const ValueKey('async_text_loading'),
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('async_text_child'),
                child: widget.child,
              ),
      ),
    );
  }
}
