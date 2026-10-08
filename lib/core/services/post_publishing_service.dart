import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../data/models/transaction_model.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/budget/controllers/budget_controller.dart';
import '../../features/feed/controllers/feed_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../routes/app_routes.dart';
import '../routes/route_names.dart';
import 'app_widget_service.dart';

enum PostPublishStatus {
  idle,
  uploading,
  success,
  error,
}

class PostPublishingService extends ChangeNotifier {
  static final PostPublishingService instance = PostPublishingService._();
  PostPublishingService._();

  PostPublishStatus _status = PostPublishStatus.idle;
  PostPublishStatus get status => _status;

  File? _mediaFile;
  File? get mediaFile => _mediaFile;

  File? _thumbnailFile;
  File? get thumbnailFile => _thumbnailFile;

  bool _isVideo = false;
  bool get isVideo => _isVideo;

  String? _category;
  String? get category => _category;

  int? _categoryIconCodePoint;
  int? get categoryIconCodePoint => _categoryIconCodePoint;

  String? _categoryColorHex;
  String? get categoryColorHex => _categoryColorHex;

  bool _isFinalizing = false;
  bool get isFinalizing => _isFinalizing;

  String? _postId;
  String? get postId => _postId;

  TransactionModel? _createdTransaction;
  TransactionModel? get createdTransaction => _createdTransaction;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _dismissTimer;

  bool get isVisible => _status != PostPublishStatus.idle;
  bool get isUploading => _status == PostPublishStatus.uploading;
  bool get isSuccess => _status == PostPublishStatus.success;
  bool get isError => _status == PostPublishStatus.error;

  void publishPost({
    required Future<TransactionModel?> Function() uploadTask,
    File? mediaFile,
    File? thumbnailFile,
    bool isVideo = false,
    String? category,
    int? categoryIconCodePoint,
    String? categoryColorHex,
  }) {
    _dismissTimer?.cancel();
    _mediaFile = mediaFile;
    _thumbnailFile = thumbnailFile;
    _isVideo = isVideo;
    _category = category;
    _categoryIconCodePoint = categoryIconCodePoint;
    _categoryColorHex = categoryColorHex;
    _postId = null;
    _createdTransaction = null;
    _errorMessage = null;
    _isFinalizing = false;
    _status = PostPublishStatus.uploading;
    notifyListeners();

    // After 2.8s of uploading, transition to finalizing state ("Đang đăng..." single line)
    Timer(const Duration(milliseconds: 2800), () {
      if (_status == PostPublishStatus.uploading && !_isFinalizing) {
        _isFinalizing = true;
        notifyListeners();
      }
    });

    if (_isVideo && _thumbnailFile == null && _mediaFile != null) {
      _generateVideoThumbnail(_mediaFile!);
    }

    unawaited(() async {
      try {
        final tx = await uploadTask();
        if (tx != null) {
          _createdTransaction = tx;
          _postId = tx.id;
          _category ??= tx.category;
          _categoryIconCodePoint ??= tx.categoryIconCodePoint;
          _categoryColorHex ??= tx.categoryColorHex;
          _status = PostPublishStatus.success;
          notifyListeners();

          // Silently refresh feed and user profile in background without reloading Home
          final navContext = AppRoutes.navigatorKey.currentContext;
          if (navContext != null) {
            final uid = navContext.read<AuthController>().user?.uid;
            if (uid != null) {
              navContext.read<FeedController>().addNewTransaction(tx);
              unawaited(navContext.read<FeedController>().refresh());
              navContext.read<BudgetController>().load(uid);
              navContext.read<ProfileController>().refreshUser(uid);
            }
          }

          // Trigger home widget update after uploading moment/transaction
          unawaited(AppWidgetService.instance.updateWidgets(
            transactions: [tx, ...AppWidgetService.instance.cachedTransactions],
            feedTransactions: [tx, ...AppWidgetService.instance.cachedFeedTransactions],
          ));

          _startAutoDismissTimer(const Duration(seconds: 5));
        } else {
          _status = PostPublishStatus.error;
          _errorMessage = 'Đăng bài thất bại';
          notifyListeners();
          final navContext = AppRoutes.navigatorKey.currentContext;
          if (navContext != null) {
            final uid = navContext.read<AuthController>().user?.uid;
            if (uid != null) {
              unawaited(navContext.read<FeedController>().refresh());
            }
          }
          _startAutoDismissTimer(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('PostPublishingService publishPost error: $e');
        _status = PostPublishStatus.error;
        _errorMessage = 'Đăng bài thất bại';
        notifyListeners();
        final navContext = AppRoutes.navigatorKey.currentContext;
        if (navContext != null) {
          final uid = navContext.read<AuthController>().user?.uid;
          if (uid != null) {
            unawaited(navContext.read<FeedController>().refresh());
          }
        }
        _startAutoDismissTimer(const Duration(seconds: 4));
      }
    }());
  }

  void _startAutoDismissTimer(Duration duration) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  void viewPost({String? targetId}) {
    final effectiveId = targetId ?? _postId;
    final createdTx = _createdTransaction;
    dismiss();

    if (effectiveId != null && effectiveId.isNotEmpty) {
      final navContext = AppRoutes.navigatorKey.currentContext;
      if (navContext != null) {
        final myUid = navContext.read<AuthController>().user?.uid;
        if (createdTx != null) {
          navContext.read<FeedController>().addNewTransaction(createdTx);
        }
        navContext.read<FeedController>().setTargetPostId(effectiveId);
        if (myUid != null) {
          unawaited(navContext.read<FeedController>().load(myUid));
        }
      }

      if (MainShell.mainShellKey.currentState != null) {
        final nav = AppRoutes.navigatorKey.currentState;
        nav?.popUntil((route) => route.isFirst);
        MainShell.switchTab(2);
      } else {
        AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.mainShell,
          (route) => false,
          arguments: {
            'initialIndex': 2,
            'targetPostId': effectiveId,
          },
        );
      }
    }
  }

  Future<void> _generateVideoThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: 300,
        maxWidth: 240,
        maxHeight: 240,
        quality: 80,
      );
      if (thumbPath != null && thumbPath.isNotEmpty) {
        _thumbnailFile = File(thumbPath);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PostPublishingService _generateVideoThumbnail error: $e');
    }
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _status = PostPublishStatus.idle;
    _mediaFile = null;
    _thumbnailFile = null;
    _isVideo = false;
    _category = null;
    _categoryIconCodePoint = null;
    _categoryColorHex = null;
    _isFinalizing = false;
    _postId = null;
    _createdTransaction = null;
    _errorMessage = null;
    notifyListeners();
  }
}
