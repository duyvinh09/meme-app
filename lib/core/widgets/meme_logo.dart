import 'package:flutter/material.dart';

/// Exact high-definition brand mark widget for "Meme" / "Meme Money Moment".
/// Faithfully reproduces 100% of the artwork:
/// - 3D Wallet 'M' with photo card, mountain, sun, spark rays, and clasp button.
/// - Rounded bubble letters 'eme' with leaf sprout petals on top of the last 'e'.
/// - Optional "Money Moment" subtitle below.
class MemeLogo extends StatelessWidget {
  /// Overall height of the logo widget.
  final double height;

  /// Optional width. If not specified, the aspect ratio is maintained automatically.
  final double? width;

  /// Whether to show the full logo with "Money Moment" subtitle (true) or just the "Meme" wordmark (false).
  final bool showSubtitle;

  /// Optional color filter (if null, displays the original vibrant blue theme).
  final Color? color;

  /// Box fit for the image rendering.
  final BoxFit fit;

  const MemeLogo({
    super.key,
    this.height = 42,
    this.width,
    this.showSubtitle = true,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = showSubtitle
        ? 'assets/icons/meme_logo.png'
        : 'assets/icons/meme_wordmark.png';

    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      color: color,
      filterQuality: FilterQuality.high,
    );
  }
}
