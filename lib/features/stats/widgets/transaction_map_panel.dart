import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';

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

  const TransactionMapPanel({
    super.key,
    required this.transactions,
  });

  @override
  State<TransactionMapPanel> createState() => _TransactionMapPanelState();
}

class _TransactionMapPanelState extends State<TransactionMapPanel> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant TransactionMapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasTransactionsChanged(oldWidget.transactions, widget.transactions)) {
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
    // 4 chữ số giúp gom các giao dịch gần nhau trong cùng một địa điểm.
    return '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  }

  List<LatLng> _getPoints(List<_LocationGroup> groups) {
    return groups.map((g) => LatLng(g.latitude, g.longitude)).toList();
  }

  void _fitAllMarkers() {
    final items = locatedTransactions;
    if (items.isEmpty) return;
    final groups = _groupTransactionsByLocation(items);
    final points = _getPoints(groups);
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14.0);
    } else {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(45, 45, 45, 100),
          maxZoom: 15.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = locatedTransactions;

    if (items.isEmpty) {
      return Container(
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
    }

    final groups = _groupTransactionsByLocation(items);
    final points = _getPoints(groups);
    final center = points.first;

    final initialCameraFit = points.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(45, 45, 45, 100),
            maxZoom: 15.0,
          )
        : null;

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
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: initialCameraFit,
              initialCenter: center,
              initialZoom: 14.0,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.duyvinh09.memeapp',
              ),
              MarkerLayer(
                markers: groups.map((group) {
                  return Marker(
                    point: LatLng(group.latitude, group.longitude),
                    width: group.count > 1 ? 92 : 68,
                    height: group.count > 1 ? 82 : 68,
                    child: GestureDetector(
                      onTap: () {
                        if (group.count == 1) {
                          _showTransactionBottomSheet(
                            context,
                            group.transactions.first,
                          );
                        } else {
                          _showLocationGroupBottomSheet(context, group);
                        }
                      },
                      child: group.count == 1
                          ? _MapMomentMarker(
                              transaction: group.transactions.first,
                            )
                          : _MapMomentClusterMarker(
                              group: group,
                            ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Bottom Summary Pill (tapping it fits all markers!)
          Positioned(
            left: 14,
            right: 14,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _fitAllMarkers,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
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
                            color: Colors.white.withValues(alpha: 0.15),
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
        ],
      ),
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
                          final normalizedCategory = tx.category.trim().toLowerCase();
                          final normalizedLocalizedCategory =
                              localizedCategory.toLowerCase();

                          if (caption.isEmpty ||
                              normalizedCaption == normalizedCategory ||
                              normalizedCaption == normalizedLocalizedCategory) {
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

  List<TransactionModel> get previews {
    return transactions.take(3).toList();
  }
}

class _MapMomentMarker extends StatelessWidget {
  final TransactionModel transaction;

  const _MapMomentMarker({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TransactionMomentImage(
            imageUrl: transaction.imageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 14,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapMomentClusterMarker extends StatelessWidget {
  final _LocationGroup group;

  const _MapMomentClusterMarker({
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final previews = group.previews;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        for (int i = previews.length - 1; i >= 0; i--)
          Transform.translate(
            offset: _offsetFor(i, previews.length),
            child: Transform.rotate(
              angle: _angleFor(i),
              child: _ClusterPhotoFrame(
                transaction: previews[i],
                size: i == 0 ? 54 : 48,
              ),
            ),
          ),

        Positioned(
          right: 2,
          top: 0,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 26,
              minHeight: 26,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: AppColors.card(context),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                group.count > 99 ? '99+' : '${group.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 1,
          child: Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
        ),
      ],
    );
  }

  Offset _offsetFor(int index, int total) {
    if (total == 1) return Offset.zero;

    switch (index) {
      case 0:
        return const Offset(0, -2);
      case 1:
        return const Offset(-14, 4);
      case 2:
        return const Offset(14, 6);
      default:
        return Offset.zero;
    }
  }

  double _angleFor(int index) {
    switch (index) {
      case 0:
        return 0;
      case 1:
        return -10 * math.pi / 180;
      case 2:
        return 10 * math.pi / 180;
      default:
        return 0;
    }
  }
}

class _ClusterPhotoFrame extends StatelessWidget {
  final TransactionModel transaction;
  final double size;

  const _ClusterPhotoFrame({
    required this.transaction,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TransactionMomentImage(
        imageUrl: transaction.imageUrl,
        category: transaction.category,
        categoryIconCodePoint: transaction.categoryIconCodePoint,
        categoryColorHex: transaction.categoryColorHex,
        width: size - 6,
        height: size - 6,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
      ),
    );
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
      child: ListTile(
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
    );
  }
}