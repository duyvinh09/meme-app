import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
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

  bool isSavingMedia = false;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex.clamp(
      0,
      widget.transactions.isEmpty ? 0 : widget.transactions.length - 1,
    );

    _pageController = PageController(
      initialPage: currentIndex,
    );
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
    final savedHex = tx.categoryColorHex?.toString();

    if (savedHex != null && savedHex.trim().isNotEmpty) {
      return _parseTransactionColor(savedHex);
    }

    switch (tx.category) {
      case 'Ăn uống':
      case 'Lương':
        return AppColors.income;
      case 'Mua sắm':
        return AppColors.primaryPink;
      case 'Đi lại':
        return AppColors.primaryBlue;
      case 'Giải trí':
        return AppColors.warning;
      case 'Học tập':
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

    return '${tx.type == 'expense' ? '-' : '+'}$amountText';
  }

  String _formatUploadTime(DateTime date) {
    return 'lúc ${DateFormat('H:mm', 'vi_VN').format(date)} ngày ${date.day} tháng ${date.month}, ${date.year}';
  }

  Future<void> _showMoreMenu(TransactionModel tx) async {
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
                    color: AppColors.textSecondary(context).withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                const SizedBox(height: 16),
                _BottomSheetActionTile(
                  icon: Icons.download_rounded,
                  title: tx.isVideo ? 'Lưu video vào máy' : 'Lưu ảnh vào máy',
                  color: AppColors.textPrimary(context),
                  onTap: () => Navigator.pop(sheetContext, 'save'),
                ),
                _BottomSheetActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Xoá giao dịch',
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

    if (result == 'save') {
      await _saveMediaToGallery(tx);
    } else if (result == 'delete') {
      await _deleteTransaction(tx);
    }
  }

  Future<void> _saveMediaToGallery(TransactionModel tx) async {
    final mediaUrl = tx.isVideo ? tx.playableVideoUrl : tx.displayImageUrl;

    if (mediaUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tx.isVideo
                ? 'Video này chưa có link để lưu vào máy'
                : 'Ảnh dạng icon/category không thể lưu trực tiếp vào máy',
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSavingMedia = true;
      });

      final ok = tx.isVideo
          ? await GallerySaver.saveVideo(mediaUrl)
          : await GallerySaver.saveImage(mediaUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok == true
                ? (tx.isVideo ? 'Đã lưu video vào máy' : 'Đã lưu ảnh vào máy')
                : (tx.isVideo ? 'Lưu video thất bại' : 'Lưu ảnh thất bại'),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Save media error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tx.isVideo ? 'Không thể lưu video vào máy' : 'Không thể lưu ảnh vào máy',
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoá giao dịch'),
          content: const Text('Bạn có chắc muốn xoá giao dịch này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Xoá',
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
        const SnackBar(
          content: Text('Đã xoá giao dịch'),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xoá giao dịch thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Center(
            child: Text(
              'Không có giao dịch để hiển thị',
              style: AppTextStyles.bodySecondary(context),
            ),
          ),
        ),
      );
    }

    final tx = widget.transactions[currentIndex];
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  _TopGlassButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _showMoreMenu(tx),
                    backgroundColor: glassColor,
                    borderColor: glassBorder,
                    iconColor: primaryText,
                    isWide: true,
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
                itemCount: widget.transactions.length,
                onPageChanged: (value) {
                  setState(() {
                    currentIndex = value;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.transactions[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: _MomentMediaCard(
                                  transaction: item,
                                  currency: currency,
                                  amountText: _formatMoney(item, currency),
                                  chipColor: _chipColorFromTransaction(item),
                                  primaryText: primaryText,
                                  glassBorder: glassBorder,
                                  overlayCardBg: overlayCardBg,
                                ),
                              ),

                              const SizedBox(height: 16),

                              if (isSavingMedia)
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
                    ),
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

  const _MomentMediaCard({
    required this.transaction,
    required this.currency,
    required this.amountText,
    required this.chipColor,
    required this.primaryText,
    required this.glassBorder,
    required this.overlayCardBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
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
              borderRadius: BorderRadius.circular(34),
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
            top: 18,
            left: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(isDark ? 0.22 : 0.16),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: chipColor,
                      width: 1.4,
                    ),
                  ),
                  child: Text(
                    transaction.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (transaction.caption.trim().isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      transaction.caption.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],

                Container(
                  constraints: const BoxConstraints(
                    minWidth: 160,
                    maxWidth: 285,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        chipColor.withOpacity(0.36),
                        chipColor.withOpacity(0.18),
                        Colors.black.withOpacity(0.34),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: chipColor.withOpacity(0.45),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: chipColor.withOpacity(0.18),
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

  const _MomentMutedVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
    this.categoryIconCodePoint,
    this.categoryColorHex,
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
    }
  }

  Future<void> _setupVideo() async {
    if (widget.videoUrl.trim().isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (!mounted) return;

      setState(() {
        _isReady = true;
      });
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

        if (_isReady && controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
      ],
    );
  }
}

class _TopGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final bool isWide;

  const _TopGlassButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        width: isWide ? null : 56,
        height: 56,
        padding: isWide
            ? const EdgeInsets.symmetric(horizontal: 20)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isWide ? BoxShape.rectangle : BoxShape.circle,
          borderRadius:
          isWide ? BorderRadius.circular(AppSizes.radiusPill) : null,
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: isWide ? 26 : 30,
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