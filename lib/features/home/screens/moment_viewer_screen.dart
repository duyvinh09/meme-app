import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/video_cache_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/widgets/edit_transaction_sheet.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class MomentViewerScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final int initialIndex;

  const MomentViewerScreen({
    super.key,
    required this.transactions,
    required this.initialIndex,
  });

  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  late final PageController _pageController;
  late int currentIndex;
  late List<TransactionModel> _transactions;

  bool isSavingMedia = false;
  bool isSharingMedia = false;

  @override
  void initState() {
    super.initState();

    _transactions = List.from(widget.transactions);

    currentIndex = widget.initialIndex.clamp(
      0,
      _transactions.isEmpty ? 0 : _transactions.length - 1,
    );

    _pageController = PageController(
      initialPage: currentIndex,
    );

    _preloadUpcomingVideos(currentIndex);
  }

  void _preloadUpcomingVideos(int current) {
    if (_transactions.isEmpty) return;
    final urlsToPreload = <String>[];
    for (int offset = -1; offset <= 2; offset++) {
      final idx = current + offset;
      if (idx >= 0 && idx < _transactions.length) {
        final tx = _transactions[idx];
        if (tx.isVideo && tx.playableVideoUrl.isNotEmpty) {
          urlsToPreload.add(tx.playableVideoUrl);
        }
      }
    }
    if (urlsToPreload.isNotEmpty) {
      VideoCacheService.instance.preloadBatch(urlsToPreload);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _parseTransactionColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppColors.textSecondary(context);
    }

    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return AppColors.textSecondary(context);
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return AppColors.textSecondary(context);
    }
  }

  Color _chipColorFromTransaction(TransactionModel tx) {
    if (tx.isGroupContribution ||
        (tx.privacy == 'group' &&
            (tx.category == 'Quỹ nhóm' || tx.category == 'Group Fund'))) {
      return AppColors.income;
    }
    final savedHex = tx.categoryColorHex?.toString();

    if (savedHex != null && savedHex.trim().isNotEmpty) {
      return _parseTransactionColor(savedHex);
    }

    switch (tx.category) {
      case 'Ăn uống':
      case 'Food':
        return AppColors.income;
      case 'Lương':
      case 'Salary':
        return AppColors.income;
      case 'Mua sắm':
      case 'Shopping':
        return AppColors.primaryPink;
      case 'Đi lại':
      case 'Transport':
        return AppColors.primaryBlue;
      case 'Giải trí':
      case 'Entertainment':
        return AppColors.warning;
      case 'Học tập':
      case 'Education':
        return AppColors.primaryPurple;
      default:
        return AppColors.textSecondary(context);
    }
  }

  String _formatMoney(
      TransactionModel tx,
      String currency,
      ) {
    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount.abs(),
      currency: currency,
    );

    final isGroupDeposit = tx.isGroupContribution ||
        (tx.privacy == 'group' &&
            (tx.category == 'Quỹ nhóm' || tx.category == 'Group Fund'));
    final isExpense = tx.type == 'expense' && !isGroupDeposit;

    return '${isExpense ? '-' : '+'}$amountText';
  }

  String _formatUploadTime(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = context.l10n;
    final time = DateFormat.Hm(locale).format(date);
    final day = DateFormat.yMMMd(locale).format(date);
    return l10n.momentViewerUploadTime(time, day);
  }

  Future<void> _showMoreMenu(TransactionModel tx) async {
    if (isSavingMedia || isSharingMedia) return;
    final l10n = context.l10n;
    final myUid = context.read<AuthController>().user?.uid;
    final isMine = myUid != null && tx.userId == myUid;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary(context).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                const SizedBox(height: 16),
                if (isMine)
                  _BottomSheetActionTile(
                    icon: Icons.edit_note_rounded,
                    title: l10n.editTransaction,
                    color: AppColors.textPrimary(context),
                    onTap: () => Navigator.pop(sheetContext, 'edit'),
                  ),
                _BottomSheetActionTile(
                  icon: Icons.share_rounded,
                  title: l10n.share,
                  color: AppColors.textPrimary(context),
                  onTap: () => Navigator.pop(sheetContext, 'share'),
                ),
                _BottomSheetActionTile(
                  icon: Icons.download_rounded,
                  title: tx.isVideo
                      ? l10n.momentViewerSaveVideo
                      : l10n.momentViewerSaveImage,
                  color: AppColors.textPrimary(context),
                  onTap: () => Navigator.pop(sheetContext, 'save'),
                ),
                if (isMine)
                  _BottomSheetActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.momentViewerDeleteTransaction,
                    color: AppColors.expense,
                    onTap: () => Navigator.pop(sheetContext, 'delete'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == 'edit') {
      final updated = await EditTransactionSheet.show(
        context,
        transaction: tx,
      );
      if (updated != null && mounted) {
        setState(() {
          _transactions[currentIndex] = updated;
        });
      }
    } else if (result == 'share') {
      await _shareTransaction(tx);
    } else if (result == 'save') {
      await _saveMediaToGallery(tx);
    } else if (result == 'delete') {
      await _deleteTransaction(tx);
    }
  }

  Future<void> _shareTransaction(TransactionModel tx) async {
    final l10n = context.l10n;
    final currency = context.read<ProfileController>().currency;
    final isContribution = tx.isGroupContribution ||
        (tx.privacy == 'group' &&
            (tx.category == 'Quỹ nhóm' || tx.category == 'Group Fund'));
    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount.abs(),
      currency: currency,
    );

    final privacyText = tx.privacy == 'private'
        ? l10n.private
        : (tx.privacy == 'close_friends'
            ? l10n.closeFriends
            : (tx.privacy == 'group'
                ? (tx.groupName?.trim().isNotEmpty == true
                    ? tx.groupName!
                    : l10n.groupBadge)
                : l10n.everyone));

    final shareText = StringBuffer()
      ..writeln('Meme')
      ..writeln()
      ..writeln(l10n.shareType(isContribution
          ? l10n.groupFundDeposit
          : (tx.type == 'expense' ? l10n.expense : l10n.income)))
      ..writeln(l10n.shareCategory(
          BudgetNameLocalizer.display(context, tx.category)));

    if (tx.amount != 0) {
      shareText.writeln(l10n.shareAmount(
          '${(isContribution ? '+' : (tx.type == 'expense' ? '-' : '+'))}$amountText'));
    }

    final details = tx.caption.trim().isNotEmpty
        ? tx.caption.trim()
        : tx.note.trim();
    if (details.isNotEmpty) {
      shareText.writeln(l10n.shareDetails(details));
    }

    shareText.writeln(l10n.sharePrivacy(privacyText));

    final mediaUrl = tx.isVideo ? tx.playableVideoUrl : tx.displayImageUrl;

    try {
      setState(() {
        isSharingMedia = true;
      });

      File? shareFile;
      final trimmedUrl = mediaUrl.trim();

      if (trimmedUrl.isNotEmpty) {
        final localFile = File(trimmedUrl);
        if (await localFile.exists()) {
          shareFile = localFile;
        } else {
          // Ưu tiên lấy file từ Cache máy đã có sẵn để chia sẻ tức thì
          if (tx.isVideo) {
            shareFile = await VideoCacheService.instance.getCachedFile(trimmedUrl);
            shareFile ??= await DefaultCacheManager().getSingleFile(trimmedUrl);
          } else {
            final fileInfo = await DefaultCacheManager().getFileFromCache(trimmedUrl);
            if (fileInfo != null && await fileInfo.file.exists()) {
              shareFile = fileInfo.file;
            } else {
              shareFile = await DefaultCacheManager().getSingleFile(trimmedUrl);
            }
          }
        }
      }

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      if (shareFile != null && await shareFile.exists()) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(shareFile.path)],
          text: shareText.toString(),
          sharePositionOrigin: origin,
        );
      } else {
        // ignore: deprecated_member_use
        await Share.share(
          shareText.toString(),
          sharePositionOrigin: origin,
        );
      }
    } catch (e) {
      debugPrint('Share transaction error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.cannotShareNow),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSharingMedia = false;
        });
      }
    }
  }

  Future<void> _saveMediaToGallery(TransactionModel tx) async {
    final l10n = context.l10n;
    final mediaUrl = tx.isVideo ? tx.playableVideoUrl : tx.displayImageUrl;

    if (mediaUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(
            tx.isVideo
                ? l10n.momentViewerVideoNoLink
                : l10n.momentViewerImageNoLink,
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSavingMedia = true;
      });

      File? targetFile;

      if (tx.isVideo) {
        // 1. Lấy file video đã cache sẵn trong máy (từ VideoCacheService hoặc tải nhanh)
        targetFile = await VideoCacheService.instance.getCachedFile(mediaUrl);
        targetFile ??= await DefaultCacheManager().getSingleFile(mediaUrl);
      } else {
        // 2. Lấy file ảnh đã cache sẵn trong máy (từ DefaultCacheManager)
        final fileInfo = await DefaultCacheManager().getFileFromCache(mediaUrl);
        if (fileInfo != null && await fileInfo.file.exists()) {
          targetFile = fileInfo.file;
        } else {
          targetFile = await DefaultCacheManager().getSingleFile(mediaUrl);
        }
      }

      if (!await targetFile.exists()) {
        throw Exception('File does not exist');
      }

      // 3. Lưu trực tiếp file cục bộ vào Gallery thông qua Gal (tốc độ tức thì)
      if (tx.isVideo) {
        await Gal.putVideo(targetFile.path);
      } else {
        await Gal.putImage(targetFile.path);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(
            tx.isVideo
                ? l10n.momentViewerSaveVideoSuccess
                : l10n.momentViewerSaveImageSuccess,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Save media error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(
            tx.isVideo
                ? l10n.momentViewerSaveVideoFailed
                : l10n.momentViewerSaveImageFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingMedia = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.momentViewerDeleteConfirmTitle),
          content: Text(l10n.momentViewerDeleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.delete,
                style: TextStyle(
                  color: AppColors.expense,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<TransactionRepository>().deleteTransaction(
        userId: tx.userId,
        transactionId: tx.id,
      );

      if (!mounted) return;

      context.read<FeedController>().removeDeletedTransaction(tx.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.momentViewerDeleted),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.momentViewerDeleteFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_transactions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Center(
            child: Text(
              context.l10n.momentViewerEmpty,
              style: AppTextStyles.bodySecondary(context),
            ),
          ),
        ),
      );
    }

    final safeIndex = currentIndex.clamp(0, _transactions.length - 1);
    final tx = _transactions[safeIndex];
    final currency = context.watch<ProfileController>().currency;

    final isDark = AppColors.isDark(context);

    final primaryText = AppColors.textPrimary(context);
    final secondaryText = AppColors.textSecondary(context);

    final glassColor = AppColors.subtleOverlay(context);
    final glassBorder = AppColors.glassBorder(context);

    final timePillBg =
    isDark ? AppColors.darkSurface : Colors.black.withOpacity(0.055);

    final overlayCardBg =
    isDark ? Colors.black.withOpacity(0.38) : Colors.white.withOpacity(0.22);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  _TopGlassButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: (isSavingMedia || isSharingMedia)
                        ? null
                        : () => _showMoreMenu(tx),
                    backgroundColor: glassColor,
                    borderColor: glassBorder,
                    iconColor: primaryText,
                  ),
                  const Spacer(),
                  _TopGlassButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                    backgroundColor: glassColor,
                    borderColor: glassBorder,
                    iconColor: primaryText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: timePillBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: glassBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: secondaryText,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatUploadTime(tx.createdAt),
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _transactions.length,
                onPageChanged: (value) {
                  setState(() {
                    currentIndex = value;
                  });
                  _preloadUpcomingVideos(value);
                },
                itemBuilder: (context, index) {
                  final item = _transactions[index];

                  return Column(
                    children: [
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _MomentMediaCard(
                                    transaction: item,
                                    currency: currency,
                                    amountText: _formatMoney(item, currency),
                                    chipColor: _chipColorFromTransaction(item),
                                    primaryText: primaryText,
                                    glassBorder: glassBorder,
                                    overlayCardBg: overlayCardBg,
                                    isActive: index == currentIndex,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              if (item.note.trim().isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: glassColor,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                    border: Border.all(color: glassBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 19,
                                        color: secondaryText,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          item.note.trim(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: primaryText,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              if (isSavingMedia || isSharingMedia)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: CircularProgressIndicator(),
                                ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: glassColor,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: glassBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.collections_outlined,
                                      color: primaryText,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${currentIndex + 1} / ${widget.transactions.length}',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentMediaCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currency;
  final String amountText;
  final Color chipColor;
  final Color primaryText;
  final Color glassBorder;
  final Color overlayCardBg;
  final bool isActive;

  const _MomentMediaCard({
    required this.transaction,
    required this.currency,
    required this.amountText,
    required this.chipColor,
    required this.primaryText,
    required this.glassBorder,
    required this.overlayCardBg,
    this.isActive = true,
  });

  String _localizedCategoryLabel(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
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
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      case 'Quỹ nhóm':
      case 'Group Fund':
        return l10n.groupFundCategory;
      default:
        if (category.trim().toLowerCase() == 'quỹ nhóm' ||
            category.trim().toLowerCase() == 'group fund' ||
            category.trim().toLowerCase() == l10n.groupFundCategory.toLowerCase()) {
          return l10n.groupFundCategory;
        }
        return BudgetNameLocalizer.display(context, category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(56),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (transaction.isVideo && transaction.playableVideoUrl.isNotEmpty)
            _MomentMutedVideoPlayer(
              videoUrl: transaction.playableVideoUrl,
              thumbnailUrl: transaction.displayImageUrl,
              category: transaction.category,
              categoryIconCodePoint: transaction.categoryIconCodePoint,
              categoryColorHex: transaction.categoryColorHex,
              isFrontCamera: transaction.isFrontCamera,
              isActive: isActive,
            )
          else
            TransactionMomentImage(
              imageUrl: transaction.displayImageUrl,
              category: transaction.category,
              categoryIconCodePoint: transaction.categoryIconCodePoint,
              categoryColorHex: transaction.categoryColorHex,
              caption: null,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(56),
              isVideo: transaction.isVideo,
              showVideoBadge: false,
            ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.22),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(isDark ? 0.22 : 0.16),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: chipColor,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _localizedCategoryLabel(context, transaction.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (transaction.caption.trim().isNotEmpty) ...[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        transaction.caption.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          chipColor.withValues(alpha: 0.36),
                          chipColor.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.34),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: chipColor.withValues(alpha: 0.45),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: chipColor.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentMutedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String category;
  final int? categoryIconCodePoint;
  final String? categoryColorHex;
  final bool isFrontCamera;
  final bool isActive;

  const _MomentMutedVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.isFrontCamera = false,
    this.isActive = true,
  });

  @override
  State<_MomentMutedVideoPlayer> createState() => _MomentMutedVideoPlayerState();
}

class _MomentMutedVideoPlayerState extends State<_MomentMutedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void didUpdateWidget(covariant _MomentMutedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideo();
      _setupVideo();
    } else if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (_controller != null && _controller!.value.isInitialized) {
          _controller!.play();
        }
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _setupVideo() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    try {
      final controller = await VideoCacheService.instance.createOptimizedController(
        url,
        looping: true,
        volume: 0,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      _controller = controller;

      setState(() {
        _isReady = true;
      });

      if (widget.isActive) {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Moment viewer video error: $e');
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _isReady = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    Widget? videoWidget;
    if (_isReady && controller != null && controller.value.isInitialized) {
      videoWidget = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );

      if (widget.isFrontCamera) {
        videoWidget = Transform.flip(
          flipX: true,
          child: videoWidget,
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        TransactionMomentImage(
          imageUrl: widget.thumbnailUrl,
          category: widget.category,
          categoryIconCodePoint: widget.categoryIconCodePoint,
          categoryColorHex: widget.categoryColorHex,
          caption: null,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(34),
          isVideo: true,
          showVideoBadge: false,
        ),

        if (videoWidget != null)
          AnimatedOpacity(
            opacity: _isReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: videoWidget,
          ),
      ],
    );
  }
}

class _TopGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const _TopGlassButton({
    required this.icon,
    this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}

class _BottomSheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}