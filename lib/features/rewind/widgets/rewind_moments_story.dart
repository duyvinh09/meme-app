import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../models/rewind_data.dart';

class RewindMomentsStory extends StatefulWidget {
  final RewindData data;
  final String currency;
  final ValueChanged<bool>? onZoomChanged;

  const RewindMomentsStory({
    super.key,
    required this.data,
    required this.currency,
    this.onZoomChanged,
  });

  @override
  State<RewindMomentsStory> createState() => _RewindMomentsStoryState();
}

class _RewindMomentsStoryState extends State<RewindMomentsStory>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _zoomController;
  late Animation<double> _zoomScaleAnimation;
  late Animation<double> _zoomFadeAnimation;

  TransactionModel? _zoomedMoment;

  // Fixed deterministic rotations for collage aesthetic
  static const List<double> _deterministicRotations = [
    -0.07, // ~ -4.0 deg
    0.05,  // ~ +2.9 deg
    -0.04, // ~ -2.3 deg
    0.06,  // ~ +3.4 deg
    -0.05,
    0.04,
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _zoomScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutBack),
    );

    _zoomFadeAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _openZoom(TransactionModel tx) {
    HapticFeedback.mediumImpact();
    widget.onZoomChanged?.call(true);
    setState(() {
      _zoomedMoment = tx;
    });
    _zoomController.forward(from: 0.0);
  }

  void _closeZoom() {
    HapticFeedback.lightImpact();
    _zoomController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _zoomedMoment = null;
        });
        widget.onZoomChanged?.call(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moments = widget.data.momentTransactions.take(6).toList();

    return Stack(
      children: [
        // ORIGINAL FLOATING POLAROID COLLAGE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      l10n.rewindMomentsTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  l10n.rewindMomentsSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Polaroid Collage Area
              Expanded(
                child: Center(
                  child: moments.length <= 2
                      ? _buildLinearMoments(moments)
                      : _buildCollageMoments(moments),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ZOOMED MODAL LIGHTBOX OVERLAY
        if (_zoomedMoment != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _zoomController,
              builder: (context, _) {
                final fade = _zoomFadeAnimation.value;
                final scale = _zoomScaleAnimation.value;

                return Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backdrop (Tap anywhere outside to close)
                      GestureDetector(
                        onTap: _closeZoom,
                        behavior: HitTestBehavior.opaque,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10 * fade,
                            sigmaY: 10 * fade,
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.82),
                          ),
                        ),
                      ),

                      // Zoomed Card in Center
                      Transform.scale(
                        scale: scale,
                        child: _buildZoomedCard(_zoomedMoment!),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLinearMoments(List<TransactionModel> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final tx = entry.value;
        final rotation =
            _deterministicRotations[index % _deterministicRotations.length];

        return _buildAnimatedPolaroid(
          tx: tx,
          index: index,
          rotation: rotation,
          width: 210,
          height: 240,
        );
      }).toList(),
    );
  }

  Widget _buildCollageMoments(List<TransactionModel> items) {
    final count = items.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Original relative positions with slight breathing room
        final relativePositions = [
          Offset(w * 0.04, h * 0.03),
          Offset(w * 0.44, h * 0.07),
          Offset(w * 0.10, h * 0.36),
          Offset(w * 0.48, h * 0.42),
          Offset(w * 0.03, h * 0.67),
          Offset(w * 0.43, h * 0.69),
        ];

        final cardWidth = (w * 0.48).clamp(145.0, 185.0);
        final cardHeight = cardWidth * 1.25;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(count, (index) {
            final tx = items[index];
            final pos = relativePositions[index % relativePositions.length];
            final rotation =
                _deterministicRotations[index % _deterministicRotations.length];

            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: _buildAnimatedPolaroid(
                tx: tx,
                index: index,
                rotation: rotation,
                width: cardWidth,
                height: cardHeight,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAnimatedPolaroid({
    required TransactionModel tx,
    required int index,
    required double rotation,
    required double width,
    required double height,
  }) {
    final startInterval = (index * 0.12).clamp(0.0, 0.6);
    final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = animation.value;
        final slideY = (1.0 - animation.value) * 60;

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Transform.rotate(
            angle: rotation * animation.value,
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openZoom(tx),
        child: _PolaroidCard(
          tx: tx,
          width: width,
          height: height,
          currency: widget.currency,
        ),
      ),
    );
  }

  Widget _buildZoomedCard(TransactionModel tx) {
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(tx.createdAt);
    final catDisplay = BudgetNameLocalizer.display(context, tx.category);
    final amountStr = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount,
      currency: widget.currency,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.86).clamp(280.0, 360.0);

    return GestureDetector(
      onTap: () {}, // Prevent tap on card from closing
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              spreadRadius: 4,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: tx.displayImageUrl,
                    width: double.infinity,
                    height: cardWidth * 0.95,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: cardWidth * 0.95,
                      color: const Color(0xFFE5E7EB),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: cardWidth * 0.95,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.black38,
                        size: 40,
                      ),
                    ),
                  ),

                  // Close button at top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _closeZoom,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Amount Stamp in bottom right
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        amountStr,
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Category & Date Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    catDisplay,
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Caption
            if (tx.caption.isNotEmpty)
              Text(
                tx.caption,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PolaroidCard extends StatelessWidget {
  final TransactionModel tx;
  final double width;
  final double height;
  final String currency;

  const _PolaroidCard({
    required this.tx,
    required this.width,
    required this.height,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM').format(tx.createdAt);
    final amountStr = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount,
      currency: currency,
    );
    final catDisplay = BudgetNameLocalizer.display(context, tx.category);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: tx.displayImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  // Amount Badge Stamp
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amountStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Caption & Date
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.caption.isNotEmpty ? tx.caption : catDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
