import 'dart:math' as math;
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
  late AnimationController _sequenceController;
  late AnimationController _zoomController;
  late Animation<double> _zoomScaleAnimation;
  late Animation<double> _zoomFadeAnimation;

  TransactionModel? _zoomedMoment;

  @override
  void initState() {
    super.initState();

    // 1. Master Sequence Controller (Fireworks Rocket -> Radial Explosion -> Exact 2-Column Auto Arrange -> Static Settle)
    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();

    // 2. Zoom Lightbox Controller
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _zoomScaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutBack),
    );

    _zoomFadeAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _onCardTapDown() {
    widget.onZoomChanged?.call(true);
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
    widget.onZoomChanged?.call(false);
    _zoomController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _zoomedMoment = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final moments = widget.data.momentTransactions.take(10).toList();

    return Stack(
      children: [
        // ═════════════════════════════════════════════════════════════════════
        // MEMORY BURST & 2-COLUMN COLLAGE CANVAS
        // ═════════════════════════════════════════════════════════════════════
        Positioned.fill(
          child: Column(
            children: [
              // 1. TOP HEADER TITLE ("KHOẢNH KHẮC CHI TIÊU")
              const SizedBox(height: 64),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _sequenceController,
                  curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
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
                          const Text('📸', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Spending Moments' : l10n.rewindMomentsTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        isEn
                            ? 'A scrapbook of your memorable spending moments'
                            : l10n.rewindMomentsSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. ANIMATED COLLAGE ARENA
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    return _ExpenseMemoryCollageCanvas(
                      moments: moments,
                      currency: widget.currency,
                      sequenceController: _sequenceController,
                      availableWidth: w,
                      availableHeight: h,
                      onCardTapDown: _onCardTapDown,
                      onTapMoment: _openZoom,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // ═════════════════════════════════════════════════════════════════════
        // LIGHTBOX ZOOM MODAL
        // ═════════════════════════════════════════════════════════════════════
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
                      // Backdrop Blur (Tap anywhere outside to close)
                      GestureDetector(
                        onTap: _closeZoom,
                        behavior: HitTestBehavior.opaque,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 12 * fade,
                            sigmaY: 12 * fade,
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.85),
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
      onTap: () {}, // Prevent accidental dismissal when clicking on the card itself
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Header with Amount Badge and Close Icon
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

                  // Close button
                  Positioned(
                    top: 10,
                    right: 10,
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
                        color: Colors.black.withValues(alpha: 0.8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                  fontSize: 14.5,
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

// ═════════════════════════════════════════════════════════════════════════════
// EXPENSE MEMORY FIREWORKS BURST & 2-COLUMN AUTO-ARRANGE CANVAS (STATIC FINALE)
// Choreography:
// 1. ROCKET LAUNCH (Small & dim rocket ascends from bottom)
// 2. FIREWORKS RADIAL EXPLOSION (360° burst, scale pop & bright illumination)
// 3. AUTO ARRANGE (Sparks smoothly glide into original 2-column layout)
// 4. STATIC FINALE (No continuous floating, completely stable)
// ═════════════════════════════════════════════════════════════════════════════

class _ExpenseMemoryCollageCanvas extends StatelessWidget {
  final List<TransactionModel> moments;
  final String currency;
  final AnimationController sequenceController;
  final double availableWidth;
  final double availableHeight;
  final VoidCallback onCardTapDown;
  final ValueChanged<TransactionModel> onTapMoment;

  const _ExpenseMemoryCollageCanvas({
    required this.moments,
    required this.currency,
    required this.sequenceController,
    required this.availableWidth,
    required this.availableHeight,
    required this.onCardTapDown,
    required this.onTapMoment,
  });

  @override
  Widget build(BuildContext context) {
    final count = moments.length;
    if (count == 0) return const SizedBox.shrink();

    final w = availableWidth;
    final h = availableHeight;

    // Card dimensions matching original code: 2 columns with generous visibility
    final cardWidth = count <= 6
        ? (w * 0.48).clamp(145.0, 185.0)
        : (w * 0.44).clamp(130.0, 166.0);
    final cardHeight = cardWidth * 1.25;

    // 1. Single Fireworks Launch Point at bottom center
    final spawnPoint = Offset(
      (w - cardWidth) / 2,
      h * 0.94,
    );

    // 2. Fireworks Apex Explosion Point in upper/mid arena
    final apexPoint = Offset(
      (w - cardWidth) / 2,
      h * 0.38,
    );

    // Generate tailored fireworks trajectories for all photos
    final configs = _generateFireworksConfigs(
      count: count,
      w: w,
      h: h,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      spawnPoint: spawnPoint,
      apexPoint: apexPoint,
    );

    return AnimatedBuilder(
      animation: sequenceController,
      builder: (context, _) {
        final t = sequenceController.value; // Timeline: 0.0 -> 1.0 (2100ms)

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(count, (index) {
            final tx = moments[index];
            final cfg = configs[index % configs.length];

            // ═════════════════════════════════════════════════════════════════
            // FIREWORKS TIMELINE PHASES:
            // 0.00 -> 0.22: Rocket Launch (small, dim, zooming upward to apex)
            // 0.22 -> 0.52: Fireworks Radial Explosion (360° burst, scale pop)
            // 0.52 -> 0.88: Auto Arrange into Original 2 Columns
            // 0.88 -> 1.00: Settle & STATIC FINALE (no endless floating)
            // ═════════════════════════════════════════════════════════════════
            Offset currentPos;
            double currentRot;
            double scale;
            double opacity;

            if (t <= 0.22) {
              // ── PHASE 1: ROCKET LAUNCH (Từ nhỏ & mờ phóng vút lên) ──
              final uRaw = (t / 0.22).clamp(0.0, 1.0);
              final u = Curves.easeInCubic.transform(uRaw);

              final x = (1 - u) * cfg.spawnPoint.dx + u * cfg.apexPoint.dx;
              final y = (1 - u) * cfg.spawnPoint.dy + u * cfg.apexPoint.dy;
              currentPos = Offset(x, y);

              currentRot = cfg.launchRotation * (1.0 - u);
              scale = 0.06 + 0.20 * u;
              opacity = (u * 1.5).clamp(0.0, 0.5);
            } else if (t <= 0.52) {
              // ── PHASE 2: FIREWORKS RADIAL EXPLOSION (Bùng nổ pháo hoa tỏa ra) ──
              final vRaw = ((t - 0.22) / (0.52 - 0.22)).clamp(0.0, 1.0);
              final v = Curves.easeOutQuart.transform(vRaw);

              final p0 = cfg.apexPoint;
              final p1 = cfg.burstPoint;

              final arcX = math.sin(v * math.pi) * cfg.burstArcBend.dx;
              final arcY = math.sin(v * math.pi) * cfg.burstArcBend.dy;

              final x = (1 - v) * p0.dx + v * p1.dx + arcX;
              final y = (1 - v) * p0.dy + v * p1.dy + arcY;
              currentPos = Offset(x, y);

              currentRot = v * cfg.burstRotation;
              scale = 0.26 + 0.84 * v + 0.08 * math.sin(v * math.pi);
              opacity = (0.5 + 0.5 * v).clamp(0.0, 1.0);
            } else if (t <= 0.88) {
              // ── PHASE 3: AUTO ARRANGE FROM FIREWORKS BURST TO 2 COLUMNS ──
              final wRaw = ((t - 0.52) / (0.88 - 0.52)).clamp(0.0, 1.0);
              final wEase = Curves.easeInOutCubic.transform(wRaw);

              final pStart = cfg.burstPoint;
              final pEnd = cfg.finalPoint;

              final arcX = math.sin(wEase * math.pi) * cfg.arrangeArcBend.dx;
              final arcY = math.sin(wEase * math.pi) * cfg.arrangeArcBend.dy;

              final x = (1 - wEase) * pStart.dx + wEase * pEnd.dx + arcX;
              final y = (1 - wEase) * pStart.dy + wEase * pEnd.dy + arcY;
              currentPos = Offset(x, y);

              currentRot = (1 - wEase) * cfg.burstRotation + wEase * cfg.finalRotation;
              scale = 1.0 + 0.03 * math.sin(wEase * math.pi);
              opacity = 1.0;
            } else {
              // ── PHASE 4: FINAL SETTLE & STATIC FINALE ──
              final sRaw = ((t - 0.88) / (1.0 - 0.88)).clamp(0.0, 1.0);
              final s = Curves.easeOutBack.transform(sRaw);

              final pFinal = cfg.finalPoint;
              final settleOffset = (1.0 - s) * cfg.settleJitter;

              currentPos = Offset(
                pFinal.dx,
                pFinal.dy + settleOffset,
              );
              currentRot = cfg.finalRotation;
              scale = 1.0;
              opacity = 1.0;
            }

            return Positioned(
              left: currentPos.dx,
              top: currentPos.dy,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: currentRot,
                  child: Transform.scale(
                    scale: scale.clamp(0.05, 1.3),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => onCardTapDown(),
                      onTap: () => onTapMoment(tx),
                      child: _PolaroidCard(
                        tx: tx,
                        width: cardWidth,
                        height: cardHeight,
                        currency: currency,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Calculates dynamic fireworks trajectories using exact original 2-column layout
  List<_FireworksTrajectoryConfig> _generateFireworksConfigs({
    required int count,
    required double w,
    required double h,
    required double cardWidth,
    required double cardHeight,
    required Offset spawnPoint,
    required Offset apexPoint,
  }) {
    // Exact original 6-photo positions
    final original6Positions = [
      Offset(w * 0.04, h * 0.03),
      Offset(w * 0.44, h * 0.07),
      Offset(w * 0.10, h * 0.36),
      Offset(w * 0.48, h * 0.42),
      Offset(w * 0.03, h * 0.67),
      Offset(w * 0.43, h * 0.69),
    ];

    // Extended 10-photo positions maintaining the original aesthetic
    final original10Positions = [
      Offset(w * 0.04, h * 0.02),
      Offset(w * 0.44, h * 0.05),
      Offset(w * 0.09, h * 0.22),
      Offset(w * 0.48, h * 0.25),
      Offset(w * 0.03, h * 0.42),
      Offset(w * 0.45, h * 0.45),
      Offset(w * 0.08, h * 0.62),
      Offset(w * 0.47, h * 0.65),
      Offset(w * 0.04, h * 0.81),
      Offset(w * 0.44, h * 0.83),
    ];

    final targetPositions = count <= 6 ? original6Positions : original10Positions;

    // Exact deterministic rotations from original code
    final deterministicRotations = [
      -0.07, // ~ -4.0°
      0.05,  // ~ +2.9°
      -0.04, // ~ -2.3°
      0.06,  // ~ +3.4°
      -0.05, // ~ -2.8°
      0.04,  // ~ +2.3°
      -0.06,
      0.05,
      -0.04,
      0.06,
    ];

    final List<_FireworksTrajectoryConfig> configs = [];

    for (int i = 0; i < count; i++) {
      final finalPos = targetPositions[i % targetPositions.length];
      final finalRot = deterministicRotations[i % deterministicRotations.length];

      // Fireworks Radial Burst (360° nan hoa bùng nổ từ apex)
      final angle = (i * (2 * math.pi / math.max(1, count))) + (i % 2 == 0 ? 0.10 : -0.10);
      final burstRadiusX = (w * 0.35 + ((i * 11) % 25)).clamp(85.0, 155.0);
      final burstRadiusY = (h * 0.25 + ((i * 13) % 30)).clamp(75.0, 135.0);

      final burstX = (apexPoint.dx + math.cos(angle) * burstRadiusX).clamp(0.0, w - cardWidth);
      final burstY = (apexPoint.dy + math.sin(angle) * burstRadiusY).clamp(0.0, h - cardHeight);
      final burstPos = Offset(burstX, burstY);

      final burstRot = math.sin(angle) * 0.18;

      final burstArcBend = Offset(
        math.cos(angle + math.pi / 4) * 18.0,
        math.sin(angle + math.pi / 4) * 18.0,
      );

      final isLeftCol = (i % 2 == 0);
      final arrangeArcBend = Offset(
        isLeftCol ? -14.0 : 14.0,
        -10.0 + (i % 3) * 6.0,
      );

      configs.add(_FireworksTrajectoryConfig(
        spawnPoint: spawnPoint,
        apexPoint: apexPoint,
        burstPoint: burstPos,
        finalPoint: finalPos,
        launchRotation: (i % 2 == 0 ? -0.06 : 0.06),
        burstRotation: burstRot,
        finalRotation: finalRot,
        burstArcBend: burstArcBend,
        arrangeArcBend: arrangeArcBend,
        settleJitter: (i % 2 == 0 ? 2.0 : -2.0),
      ));
    }

    return configs;
  }
}

class _FireworksTrajectoryConfig {
  final Offset spawnPoint;
  final Offset apexPoint;
  final Offset burstPoint;
  final Offset finalPoint;
  final double launchRotation;
  final double burstRotation;
  final double finalRotation;
  final Offset burstArcBend;
  final Offset arrangeArcBend;
  final double settleJitter;

  const _FireworksTrajectoryConfig({
    required this.spawnPoint,
    required this.apexPoint,
    required this.burstPoint,
    required this.finalPoint,
    required this.launchRotation,
    required this.burstRotation,
    required this.finalRotation,
    required this.burstArcBend,
    required this.arrangeArcBend,
    required this.settleJitter,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// PHYSICAL POLAROID CARD COMPONENT
// ═════════════════════════════════════════════════════════════════════════════

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
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6), // Warm paper off-white
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Body
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.black38,
                        size: 24,
                      ),
                    ),
                  ),

                  // Amount Badge Stamp in bottom right corner
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        amountStr,
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Polaroid Bottom Label (Caption or Category + Date)
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.caption.isNotEmpty ? tx.caption : catDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 11,
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
                  fontSize: 9.5,
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
