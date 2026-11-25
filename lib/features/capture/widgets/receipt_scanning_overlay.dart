import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/extensions/localization_extension.dart';

class ReceiptScanningOverlay extends StatefulWidget {
  const ReceiptScanningOverlay(
      {required this.image, required this.accent, super.key});
  final ImageProvider<Object> image;
  final Color accent;

  @override
  State<ReceiptScanningOverlay> createState() => _ReceiptScanningOverlayState();
}

class _ReceiptScanningOverlayState extends State<ReceiptScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
        child: Semantics(
            liveRegion: true,
            label: context.l10n.receiptReading,
            child: ExcludeSemantics(
                child: ClipRect(
                    child: Stack(fit: StackFit.expand, children: [
              // Keep the live camera hidden, including while the file decodes.
              const ColoredBox(color: Colors.black),
              ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                      sigmaX: 18, sigmaY: 18, tileMode: TileMode.clamp),
                  child: Image(
                      image: widget.image,
                      fit: BoxFit.cover,
                      gaplessPlayback: true)),
              ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
              if (!_reduced)
                LayoutBuilder(
                    builder: (context, bounds) => AnimatedBuilder(
                          animation: _controller,
                          child: SizedBox(
                              height: bounds.maxHeight * 0.85,
                              width: bounds.maxWidth,
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                    widget.accent.withValues(alpha: 0),
                                    widget.accent.withValues(alpha: 0.04),
                                    widget.accent.withValues(alpha: 0.10),
                                    Colors.white.withValues(alpha: 0.18),
                                    widget.accent.withValues(alpha: 0.10),
                                    widget.accent.withValues(alpha: 0.04),
                                    widget.accent.withValues(alpha: 0)
                                  ],
                                          stops: const [
                                    0,
                                    0.16,
                                    0.34,
                                    0.5,
                                    0.66,
                                    0.84,
                                    1
                                  ])))),
                          builder: (context, child) => Align(
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                  offset: Offset(
                                      0,
                                      -bounds.maxHeight * 0.85 +
                                          bounds.maxHeight *
                                              1.85 *
                                              Curves.easeInOut.transform(
                                                  _controller.value)),
                                  child: child)),
                        )),
              PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 20,
                  child: Center(
                      child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                              child: Text(context.l10n.receiptReading,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700))),
                        ])),
                  ))),
            ])))),
      );
}
