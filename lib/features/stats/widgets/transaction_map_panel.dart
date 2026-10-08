import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../screens/transaction_map_screen.dart';

String _localizedTransactionCategory(BuildContext context, String category) {
  final l10n = context.l10n;
  switch (category.trim()) {
    case 'Ăn uống':
    case 'Food':
      return l10n.food;
    case 'Mua sắm':
    case 'Shopping':
      return l10n.shopping;
    case 'Đi lại':
    case 'Transport':
      return l10n.transport;
    case 'Giải trí':
    case 'Entertainment':
      return l10n.entertainment;
    case 'Học tập':
    case 'Education':
      return l10n.education;
    case 'Lương':
    case 'Salary':
      return l10n.salary;
    case 'Quà tặng':
    case 'Gift':
      return l10n.gift;
    case 'Khác':
    case 'Other':
      return l10n.other;
    default:
      return BudgetNameLocalizer.display(context, category);
  }
}

class TransactionMapPanel extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isFullScreen;
  final String? title;
  final VoidCallback? onBack;
  final bool showFullScreenButton;

  const TransactionMapPanel({
    super.key,
    required this.transactions,
    this.isFullScreen = false,
    this.title,
    this.onBack,
    this.showFullScreenButton = true,
  });

  @override
  State<TransactionMapPanel> createState() => _TransactionMapPanelState();
}

class _TransactionMapPanelState extends State<TransactionMapPanel> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  static final Map<String, BitmapDescriptor> _iconCache = {};
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkNow = AppColors.isDark(context);
    if (_isDark != isDarkNow) {
      _isDark = isDarkNow;
    }
  }

  @override
  void didUpdateWidget(covariant TransactionMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasTransactionsChanged(oldWidget.transactions, widget.transactions)) {
      _buildMarkers();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitAllMarkers();
        }
      });
    }
  }

  bool _hasTransactionsChanged(
    List<TransactionModel> a,
    List<TransactionModel> b,
  ) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return true;
    }
    return false;
  }

  List<TransactionModel> get locatedTransactions {
    final items = widget.transactions.where((tx) {
      return tx.latitude != null && tx.longitude != null;
    }).toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<_LocationGroup> _groupTransactionsByLocation(
    List<TransactionModel> items,
  ) {
    final groups = <String, List<TransactionModel>>{};

    for (final tx in items) {
      final key = _locationKey(tx.latitude!, tx.longitude!);
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(tx);
    }

    final result = groups.entries.map((entry) {
      final groupItems = entry.value
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final first = groupItems.first;

      return _LocationGroup(
        latitude: first.latitude!,
        longitude: first.longitude!,
        transactions: groupItems,
      );
    }).toList();

    result.sort((a, b) {
      return b.latest.createdAt.compareTo(a.latest.createdAt);
    });

    return result;
  }

  String _locationKey(double lat, double lng) {
    return '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  }

  Future<void> _buildMarkers() async {
    final items = locatedTransactions;
    if (items.isEmpty) {
      if (mounted) setState(() => _markers = {});
      return;
    }

    final groups = _groupTransactionsByLocation(items);
    final pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final markers = <Marker>{};

    for (final group in groups) {
      final leadTx = group.latest;
      final categoryColor = _resolveCategoryColor(leadTx);
      final cacheKey =
          '${leadTx.id}_${leadTx.imageUrl}_${group.count}_${categoryColor.toARGB32()}_${pixelRatio.toStringAsFixed(1)}';

      BitmapDescriptor? icon = _iconCache[cacheKey];

      if (icon == null) {
        icon = await _generateMarkerIcon(
          group: group,
          categoryColor: categoryColor,
          pixelRatio: pixelRatio,
        );
        _iconCache[cacheKey] = icon;
      }

      markers.add(
        Marker(
          markerId: MarkerId(
            '${group.latitude.toStringAsFixed(4)}_${group.longitude.toStringAsFixed(4)}',
          ),
          position: LatLng(group.latitude, group.longitude),
          icon: icon,
          anchor: const Offset(0.5, 0.95),
          onTap: () {
            if (group.count == 1) {
              _showTransactionBottomSheet(context, group.transactions.first);
            } else {
              _showLocationGroupBottomSheet(context, group);
            }
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<BitmapDescriptor> _generateMarkerIcon({
    required _LocationGroup group,
    required Color categoryColor,
    required double pixelRatio,
  }) async {
    final leadTx = group.latest;
    ui.Image? momentImage;

    final imageUrl = leadTx.imageUrl.trim();
    if (imageUrl.isNotEmpty) {
      try {
        final file = await DefaultCacheManager().getSingleFile(imageUrl);
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: (54 * pixelRatio).round(),
          targetHeight: (54 * pixelRatio).round(),
        );
        final frame = await codec.getNextFrame();
        momentImage = frame.image;
      } catch (_) {}
    }

    final ratio = pixelRatio.clamp(1.5, 3.0);
    final isCluster = group.count > 1;
    final baseWidth = isCluster ? 64.0 : 54.0;
    final baseHeight = isCluster ? 62.0 : 58.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);

    final cardWidth = isCluster ? 50.0 : 48.0;
    final cardHeight = isCluster ? 50.0 : 48.0;
    final cardLeft = (baseWidth - cardWidth) / 2;
    final cardTop = isCluster ? 6.0 : 2.0;

    // Cluster stack background card
    if (isCluster) {
      final backCardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cardLeft - 4, cardTop - 3, cardWidth, cardHeight),
        const Radius.circular(12),
      );
      final backPaint = Paint()
        ..color = categoryColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(backCardRect, backPaint);
    }

    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(14),
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(cardRRect.shift(const Offset(0, 3)), shadowPaint);

    // Category Border / Background
    final bgPaint = Paint()
      ..color = categoryColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRRect, bgPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(cardRRect, strokePaint);

    // Inner photo / placeholder
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cardLeft + 2,
        cardTop + 2,
        cardWidth - 4,
        cardHeight - 4,
      ),
      const Radius.circular(12),
    );

    if (momentImage != null) {
      canvas.save();
      canvas.clipRRect(innerRRect);
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(
          cardLeft + 2,
          cardTop + 2,
          cardWidth - 4,
          cardHeight - 4,
        ),
        image: momentImage,
        fit: BoxFit.cover,
      );
      canvas.restore();
    } else {
      // Fallback icon / symbol inside marker
      final innerBgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(innerRRect, innerBgPaint);

      final iconData = (leadTx.categoryIconCodePoint != null &&
              leadTx.categoryIconCodePoint! > 0)
          ? AppIconRegistry.fromCodePoint(leadTx.categoryIconCodePoint!)
          : Icons.account_balance_wallet_rounded;

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: 22,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      iconPainter.paint(
        canvas,
        Offset(
          cardLeft + (cardWidth - iconPainter.width) / 2,
          cardTop + (cardHeight - iconPainter.height) / 2,
        ),
      );
    }

    // Pointer notch at bottom
    final pointerPath = Path();
    final centerX = baseWidth / 2;
    final bottomY = cardTop + cardHeight;
    pointerPath.moveTo(centerX - 5, bottomY - 1);
    pointerPath.lineTo(centerX + 5, bottomY - 1);
    pointerPath.lineTo(centerX, bottomY + 5);
    pointerPath.close();

    final pointerPaint = Paint()
      ..color = categoryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pointerPath, pointerPaint);

    // Badge for cluster count
    if (isCluster) {
      final badgeText = group.count > 99 ? '99+' : '${group.count}';
      final badgePainter = TextPainter(
        text: TextSpan(
          text: badgeText,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const badgePadding = 5.0;
      final badgeW = math.max(18.0, badgePainter.width + badgePadding * 2);
      const badgeH = 18.0;
      final badgeLeft = baseWidth - badgeW;
      const badgeTop = 0.0;

      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeLeft, badgeTop, badgeW, badgeH),
        const Radius.circular(9),
      );

      final badgePaint = Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.fill;
      canvas.drawRRect(badgeRRect, badgePaint);

      final badgeBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(badgeRRect, badgeBorder);

      badgePainter.paint(
        canvas,
        Offset(
          badgeLeft + (badgeW - badgePainter.width) / 2,
          badgeTop + (badgeH - badgePainter.height) / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final finalImg = await picture.toImage(
      (baseWidth * ratio).round(),
      (baseHeight * ratio).round(),
    );
    final byteData = await finalImg.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }

  void _fitAllMarkers() {
    final items = locatedTransactions;
    if (items.isEmpty || _mapController == null) return;
    final groups = _groupTransactionsByLocation(items);
    if (groups.isEmpty) return;

    if (groups.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(groups.first.latitude, groups.first.longitude),
          15.0,
        ),
      );
    } else {
      double minLat = groups.first.latitude;
      double maxLat = groups.first.latitude;
      double minLng = groups.first.longitude;
      double maxLng = groups.first.longitude;

      for (final g in groups) {
        if (g.latitude < minLat) minLat = g.latitude;
        if (g.latitude > maxLat) maxLat = g.latitude;
        if (g.longitude < minLng) minLng = g.longitude;
        if (g.longitude > maxLng) maxLng = g.longitude;
      }

      if ((maxLat - minLat).abs() < 0.001) {
        minLat -= 0.002;
        maxLat += 0.002;
      }
      if ((maxLng - minLng).abs() < 0.001) {
        minLng -= 0.002;
        maxLng += 0.002;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      final padding = widget.isFullScreen ? 90.0 : 50.0;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionMapScreen(
          transactions: widget.transactions,
          title: widget.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = locatedTransactions;

    if (items.isEmpty) {
      final emptyWidget = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 34,
        ),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: AppColors.textSecondary(context),
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.mapEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle(context).copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.mapEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

      if (widget.isFullScreen) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXLarge),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card(context),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary(context),
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.title ?? context.l10n.transactionMap,
                      style: AppTextStyles.sectionTitle(context).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: emptyWidget,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return emptyWidget;
    }

    final groups = _groupTransactionsByLocation(items);
    final initialLat = groups.first.latitude;
    final initialLng = groups.first.longitude;

    final mapContent = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(initialLat, initialLng),
            zoom: 14.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _fitAllMarkers();
          },
          markers: _markers,
          style: _isDark ? _darkMapStyle : _lightMapStyle,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          mapType: MapType.normal,
        ),

        // Full Screen mode overlays: Top Header Bar & Side Zoom controls
        if (widget.isFullScreen) ...[
          // Top Bar with Back Button, Title, and Recenter action
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.60),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title ?? context.l10n.transactionMap,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _fitAllMarkers,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.60),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Zoom Controls on Right Side
          Positioned(
            right: 16,
            bottom: 96,
            child: SafeArea(
              top: false,
              left: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(11),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      width: 32,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(11),
                          child: Icon(
                            Icons.remove_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Embedded mode Fullscreen button inside the map (top-right)
        if (!widget.isFullScreen && widget.showFullScreenButton)
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openFullScreen(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

        // Bottom Summary Pill (compact in embedded mode, roomy in full screen mode)
        if (widget.isFullScreen)
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fitAllMarkers,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.mapSummary(items.length, groups.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (groups.length > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.center_focus_strong_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fitAllMarkers,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.mapSummary(items.length, groups.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (groups.length > 1) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.center_focus_strong_rounded,
                            color: Colors.white70,
                            size: 11,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.isFullScreen) {
      return SizedBox.expand(
        child: mapContent,
      );
    }

    return Container(
      height: 430,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: mapContent,
    );
  }

  void _showLocationGroupBottomSheet(
    BuildContext context,
    _LocationGroup group,
  ) {
    final latest = group.latest;
    final locationText = latest.locationName.trim().isEmpty
        ? '${latest.latitude?.toStringAsFixed(5)}, ${latest.longitude?.toStringAsFixed(5)}'
        : latest.locationName;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.36,
            maxChildSize: 0.86,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withValues(alpha: 0.14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primaryBlue,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.mapTransactionsHere(group.count),
                              style: AppTextStyles.sectionTitle(context)
                                  .copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locationText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...group.transactions.map((tx) {
                    return _LocationTransactionTile(
                      transaction: tx,
                      onTap: () {
                        Navigator.pop(context);
                        _showTransactionBottomSheet(context, tx);
                      },
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showTransactionBottomSheet(
    BuildContext context,
    TransactionModel tx,
  ) {
    final locationText = tx.locationName.trim().isEmpty
        ? '${tx.latitude?.toStringAsFixed(5)}, ${tx.longitude?.toStringAsFixed(5)}'
        : tx.locationName;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
            child: Row(
              children: [
                TransactionMomentImage(
                  imageUrl: tx.imageUrl,
                  category: tx.category,
                  categoryIconCodePoint: tx.categoryIconCodePoint,
                  categoryColorHex: tx.categoryColorHex,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        () {
                          final caption = tx.caption.trim();
                          final localizedCategory =
                              _localizedTransactionCategory(context, tx.category);
                          final normalizedCaption = caption.toLowerCase();
                          final normalizedCategory =
                              tx.category.trim().toLowerCase();
                          final normalizedLocalizedCategory =
                              localizedCategory.toLowerCase();

                          if (caption.isEmpty ||
                              normalizedCaption == normalizedCategory ||
                              normalizedCaption ==
                                  normalizedLocalizedCategory) {
                            return localizedCategory;
                          }

                          return caption;
                        }(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle(context).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        locationText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationGroup {
  final double latitude;
  final double longitude;
  final List<TransactionModel> transactions;

  const _LocationGroup({
    required this.latitude,
    required this.longitude,
    required this.transactions,
  });

  int get count => transactions.length;

  TransactionModel get latest => transactions.first;
}

Color _resolveCategoryColor(TransactionModel transaction) {
  final hex = transaction.categoryColorHex;
  if (hex != null && hex.trim().isNotEmpty) {
    var cleaned = hex.trim().replaceAll('#', '');
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) {
        return Color(val);
      }
    }
  }

  switch (transaction.category.trim()) {
    case 'Ăn uống':
    case 'Food':
      return const Color(0xFF59D46F);
    case 'Mua sắm':
    case 'Shopping':
      return const Color(0xFFFF4D8D);
    case 'Đi lại':
    case 'Transport':
      return const Color(0xFF2F9BFF);
    case 'Giải trí':
    case 'Entertainment':
      return const Color(0xFFFFA52F);
    case 'Học tập':
    case 'Education':
      return const Color(0xFF8B7CFF);
    case 'Lương':
    case 'Salary':
      return const Color(0xFF59D46F);
    case 'Quà tặng':
    case 'Gift':
      return const Color(0xFFFF4D8D);
    case 'Khác':
    case 'Other':
      return const Color(0xFF79AFFF);
    default:
      const fallbackColors = [
        Color(0xFF59D46F),
        Color(0xFFFF4D8D),
        Color(0xFF2F9BFF),
        Color(0xFFFFA52F),
        Color(0xFF8B7CFF),
        Color(0xFF1CC5C0),
        Color(0xFFFF8B8B),
      ];
      final hash = transaction.category.hashCode.abs();
      return fallbackColors[hash % fallbackColors.length];
  }
}

class _LocationTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _LocationTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final localizedCategory =
        _localizedTransactionCategory(context, transaction.category);
    final caption = transaction.caption.trim();
    final normalizedCaption = caption.toLowerCase();
    final normalizedCategory = transaction.category.trim().toLowerCase();
    final normalizedLocalizedCategory = localizedCategory.toLowerCase();
    final titleText = caption.isEmpty ||
            normalizedCaption == normalizedCategory ||
            normalizedCaption == normalizedLocalizedCategory
        ? localizedCategory
        : caption;

    final isExpense = transaction.type == 'expense';
    final sign = isExpense ? '-' : '+';

    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: transaction.amount,
      currency: currency,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          leading: TransactionMomentImage(
            imageUrl: transaction.imageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle(context).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            localizedCategory,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context),
          ),
          trailing: Text(
            '$sign$amountText',
            style: TextStyle(
              color: isExpense ? AppColors.expense : AppColors.income,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181A20"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8E8E93"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#181A20"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2C2C2E"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8E8E93"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1C241E"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#262A34"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8E8E93"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2E3340"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3A4050"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#11141A"
      }
    ]
  }
]
''';

const String _lightMapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';