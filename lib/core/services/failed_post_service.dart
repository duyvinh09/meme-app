import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/failed_post_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/budget/controllers/budget_controller.dart';
import '../../features/feed/controllers/feed_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../constants/app_durations.dart';
import 'app_widget_service.dart';

class FailedPostService extends ChangeNotifier {
  static final FailedPostService instance = FailedPostService._();
  FailedPostService._();

  static const String _keyPrefix = 'failed_posts_';

  final Set<String> _retryingPostIds = {};
  bool isRetrying(String id) => _retryingPostIds.contains(id);

  Future<String> _getPersistentDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final persistentDir = Directory(path.join(docDir.path, 'failed_posts'));
    if (!await persistentDir.exists()) {
      await persistentDir.create(recursive: true);
    }
    return persistentDir.path;
  }

  Future<String> _copyFileToPersistentDir(File sourceFile, String filenamePrefix) async {
    final targetDir = await _getPersistentDirectory();
    final extension = path.extension(sourceFile.path);
    final targetFileName = '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = path.join(targetDir, targetFileName);
    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  Future<FailedPostModel> saveFailedPost({
    required String userId,
    required double amount,
    required String type,
    required String category,
    required String caption,
    required String note,
    File? mediaFile,
    File? thumbnailFile,
    String mediaType = 'image',
    int? durationMs,
    required bool sharedToFeed,
    required String privacy,
    List<String> closeFriendUids = const [],
    List<String> taggedUsernames = const [],
    String? groupId,
    String? groupName,
    List<String> groupMemberIds = const [],
    int? categoryIconCodePoint,
    String? categoryColorHex,
    String locationName = '',
    double? latitude,
    double? longitude,
    bool isGroupContribution = false,
    bool isGroupExpense = false,
    bool isFrontCamera = false,
  }) async {
    final draftId = 'failed_tx_${DateTime.now().millisecondsSinceEpoch}';

    String persistentMediaPath = '';
    if (mediaFile != null && mediaFile.path.isNotEmpty && await mediaFile.exists()) {
      persistentMediaPath = await _copyFileToPersistentDir(mediaFile, '${draftId}_media');
    }

    String? persistentThumbnailPath;
    if (thumbnailFile != null && thumbnailFile.path.isNotEmpty && await thumbnailFile.exists()) {
      persistentThumbnailPath = await _copyFileToPersistentDir(thumbnailFile, '${draftId}_thumb');
    }

    final failedPost = FailedPostModel(
      id: draftId,
      userId: userId,
      amount: amount,
      type: type,
      category: category,
      caption: caption,
      note: note,
      mediaPath: persistentMediaPath,
      thumbnailPath: persistentThumbnailPath,
      mediaType: mediaType,
      durationMs: durationMs,
      originalCreatedAt: DateTime.now(),
      sharedToFeed: sharedToFeed,
      privacy: privacy,
      closeFriendUids: closeFriendUids,
      taggedUsernames: taggedUsernames,
      groupId: groupId,
      groupName: groupName,
      groupMemberIds: groupMemberIds,
      categoryIconCodePoint: categoryIconCodePoint,
      categoryColorHex: categoryColorHex,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      isGroupContribution: isGroupContribution,
      isGroupExpense: isGroupExpense,
      isFrontCamera: isFrontCamera,
    );

    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$userId';
    final currentList = prefs.getStringList(key) ?? [];
    currentList.insert(0, jsonEncode(failedPost.toMap()));
    await prefs.setStringList(key, currentList);

    notifyListeners();
    return failedPost;
  }

  Future<List<FailedPostModel>> getFailedPosts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final list = prefs.getStringList(key) ?? [];

      final result = <FailedPostModel>[];
      for (final item in list) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final post = FailedPostModel.fromMap(map);
          // Check if media file still exists or if it has no media (e.g. voice expense)
          if (post.mediaType == 'none' ||
              post.mediaPath.isEmpty ||
              File(post.mediaPath).existsSync()) {
            result.add(post);
          }
        } catch (e) {
          debugPrint('FailedPostService getFailedPosts parse error: $e');
        }
      }
      return result;
    } catch (e) {
      debugPrint('FailedPostService getFailedPosts error: $e');
      return [];
    }
  }

  Future<FailedPostModel?> getFailedPostById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      for (final key in keys) {
        final list = prefs.getStringList(key) ?? [];
        for (final item in list) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            if (map['id'] == id) {
              return FailedPostModel.fromMap(map);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('FailedPostService getFailedPostById error: $e');
    }
    return null;
  }

  Future<void> deleteFailedPost(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));

      for (final key in keys) {
        final list = prefs.getStringList(key) ?? [];
        final updatedList = <String>[];
        bool changed = false;

        for (final item in list) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            if (map['id'] == id) {
              changed = true;
              // Clean up local media files from disk
              final mediaPath = map['mediaPath']?.toString();
              if (mediaPath != null && mediaPath.isNotEmpty) {
                final f = File(mediaPath);
                if (f.existsSync()) {
                  try {
                    f.deleteSync();
                  } catch (_) {}
                }
              }
              final thumbPath = map['thumbnailPath']?.toString();
              if (thumbPath != null && thumbPath.isNotEmpty) {
                final tf = File(thumbPath);
                if (tf.existsSync()) {
                  try {
                    tf.deleteSync();
                  } catch (_) {}
                }
              }
            } else {
              updatedList.add(item);
            }
          } catch (_) {
            updatedList.add(item);
          }
        }

        if (changed) {
          await prefs.setStringList(key, updatedList);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('FailedPostService deleteFailedPost error: $e');
    }
  }

  Future<void> retryPost(BuildContext context, String failedPostId) async {
    final txRepo = context.read<TransactionRepository>();
    final userRepo = context.read<UserRepository>();
    final authUser = context.read<AuthController>().user;
    final isEn = context.read<ProfileController>().languageCode == 'en';
    final feedCtrl = context.read<FeedController>();
    final budgetCtrl = context.read<BudgetController>();
    final profileCtrl = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    final failedPost = await getFailedPostById(failedPostId);
    if (failedPost == null) {
      debugPrint('FailedPostService retryPost: failed post $failedPostId not found');
      return;
    }

    final hasMedia = failedPost.mediaType != 'none' && failedPost.mediaPath.isNotEmpty;
    File? mediaFile;
    if (hasMedia) {
      mediaFile = File(failedPost.mediaPath);
      if (!mediaFile.existsSync()) {
        debugPrint('FailedPostService retryPost: media file does not exist on disk');
        await deleteFailedPost(failedPostId);
        feedCtrl.removeDeletedTransaction(failedPostId);
        return;
      }
    }

    // Format note specifying original post date as requested by user
    final formattedOriginalDate = DateFormat('dd/MM/yyyy HH:mm').format(failedPost.originalCreatedAt);
    final repostTag = isEn
        ? '(Reposted from $formattedOriginalDate)'
        : '(Đăng lại từ bài ngày $formattedOriginalDate)';

    final originalNote = failedPost.note.trim();
    final effectiveNote = originalNote.isNotEmpty
        ? '$originalNote $repostTag'
        : repostTag;

    final authUid = authUser?.uid ?? failedPost.userId;

    _retryingPostIds.add(failedPostId);
    notifyListeners();

    try {
      final now = DateTime.now();

      // 1. Resolve mentions if any
      final validTaggedUsernames = <String>[];
      final mentionRegex = RegExp(r'@([a-zA-Z0-9_.]+)');
      final matches = mentionRegex.allMatches(failedPost.caption);

      if (failedPost.caption.trim().isNotEmpty &&
          failedPost.privacy != 'private' &&
          matches.isNotEmpty) {
        final checkedUsernames = <String>{};
        for (final m in matches) {
          final uName = m.group(1)?.toLowerCase();
          if (uName == null || uName.isEmpty || checkedUsernames.contains(uName)) continue;
          checkedUsernames.add(uName);

          final taggedUser = await userRepo.findUserByUsername(uName);
          if (taggedUser == null || taggedUser.uid == authUid) continue;

          if (failedPost.privacy == 'friends') {
            final isFriend = await userRepo.isFriendWith(authUid, taggedUser.uid);
            if (isFriend) validTaggedUsernames.add(uName);
          } else if (failedPost.privacy == 'close_friends') {
            final isFriend = await userRepo.isFriendWith(authUid, taggedUser.uid);
            final isClose = failedPost.closeFriendUids.contains(taggedUser.uid);
            if (isFriend && isClose) validTaggedUsernames.add(uName);
          } else if (failedPost.privacy == 'group') {
            final inGroup = failedPost.groupMemberIds.contains(taggedUser.uid);
            final isFriend = await userRepo.isFriendWith(authUid, taggedUser.uid);
            if (inGroup && isFriend) validTaggedUsernames.add(uName);
          }
        }
      }

      final savedTx = await txRepo.addTransaction(
        userId: failedPost.userId,
        amount: failedPost.amount,
        type: failedPost.type,
        category: failedPost.category,
        caption: failedPost.caption,
        note: effectiveNote,
        createdAt: now,
        imageFile: (hasMedia && !failedPost.isVideo) ? mediaFile : null,
        videoFile: (hasMedia && failedPost.isVideo) ? mediaFile : null,
        mediaType: failedPost.mediaType,
        durationMs: failedPost.durationMs,
        sharedToFeed: failedPost.sharedToFeed,
        privacy: failedPost.privacy,
        closeFriendUids: failedPost.closeFriendUids,
        taggedUsernames: validTaggedUsernames,
        categoryIconCodePoint: failedPost.categoryIconCodePoint,
        categoryColorHex: failedPost.categoryColorHex,
        groupId: failedPost.groupId,
        groupName: failedPost.groupName,
        groupMemberIds: failedPost.groupMemberIds,
        locationName: failedPost.locationName,
        latitude: failedPost.latitude,
        longitude: failedPost.longitude,
        isGroupExpense: failedPost.isGroupExpense,
        isGroupContribution: failedPost.isGroupContribution,
        isFrontCamera: failedPost.isFrontCamera,
      );

      // Update group fund balance if needed
      if (failedPost.privacy == 'group' &&
          failedPost.groupId != null &&
          failedPost.groupId!.isNotEmpty) {
        if (failedPost.isGroupContribution) {
          try {
            await userRepo.addGroupContribution(
              groupId: failedPost.groupId!,
              actorUid: failedPost.userId,
              memberUid: failedPost.userId,
              amount: failedPost.amount,
              sendSystemMessage: false,
            );
          } catch (_) {}
        } else if (failedPost.isGroupExpense) {
          try {
            await userRepo.addGroupExpense(
              groupId: failedPost.groupId!,
              actorUid: failedPost.userId,
              memberUid: failedPost.userId,
              amount: failedPost.amount,
            );
          } catch (_) {}
        }
      }

      // On successful upload:
      // Delete the failed post record and local cached file
      await deleteFailedPost(failedPostId);

      feedCtrl.removeDeletedTransaction(failedPostId);
      feedCtrl.addNewTransaction(savedTx);
      budgetCtrl.load(authUid);
      profileCtrl.refreshUser(authUid);

      // Update home widgets after successfully retrying post upload
      unawaited(AppWidgetService.instance.updateWidgets(
        transactions: [savedTx, ...AppWidgetService.instance.cachedTransactions],
        feedTransactions: [savedTx, ...AppWidgetService.instance.cachedFeedTransactions],
      ));
    } catch (e) {
      debugPrint('FailedPostService retryPost error: $e');
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: AppDurations.snackBar,
          content: Text(isEn
              ? 'Retry upload failed. Please check network connection.'
              : 'Thử lại thất bại. Vui lòng kiểm tra kết nối mạng.'),
        ),
      );
    } finally {
      _retryingPostIds.remove(failedPostId);
      notifyListeners();
    }
  }
}
