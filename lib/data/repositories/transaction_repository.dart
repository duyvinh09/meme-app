import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/services/locket/locket_upload_service.dart';
import '../../core/services/fcm_push_service.dart';
import '../../core/services/notification_service.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';
import 'budget_repository.dart';

class TransactionRepository {
  final TransactionRemoteDataSource _remote = TransactionRemoteDataSource();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BudgetRepository _budgetRepository = BudgetRepository();
  final Uuid _uuid = const Uuid();

  final LocketUploadService _locketUploadService = LocketUploadService();

  Future<TransactionModel> addTransaction({
    required String userId,
    required double amount,
    required String type,
    required String category,
    required String caption,
    required String note,
    required DateTime createdAt,

    // Giữ ảnh cũ.
    File? imageFile,

    // Thêm nhẹ cho video.
    File? videoFile,
    String mediaType = 'image',
    int? durationMs,

    String locationName = '',
    bool sharedToFeed = false,
    String privacy = 'private',
    List<String> closeFriendUids = const [],
    List<String> taggedUsernames = const [],
    String? groupId,
    String? groupName,
    List<String> groupMemberIds = const [],
    int? categoryIconCodePoint,
    String? categoryColorHex,
    double? latitude,
    double? longitude,
    bool? isGroupExpense,
    bool? isGroupContribution,
    bool isFrontCamera = false,
  }) async {
    final id = _uuid.v4();

    String finalMediaType = 'none';

    String imageUrl = '';
    String mediaUrl = '';
    String videoUrl = '';
    String thumbnailUrl = '';

    if (videoFile != null) {
      finalMediaType = 'video';

      final videoUploadResult = await _locketUploadService.uploadFile(
        videoFile,
      );

      videoUrl = videoUploadResult.downloadUrl;
      mediaUrl = videoUrl;

      final thumbnailFile = await _createVideoThumbnail(
        videoFile,
        isFrontCamera: isFrontCamera,
      );

      if (thumbnailFile != null) {
        final thumbnailUploadResult = await _locketUploadService.uploadFile(
          thumbnailFile,
        );

        thumbnailUrl = thumbnailUploadResult.downloadUrl;

        // Rất quan trọng:
        // imageUrl vẫn trỏ tới thumbnail để UI cũ như Home/Calendar/Recent không vỡ.
        imageUrl = thumbnailUrl;
      }
    } else if (imageFile != null) {
      finalMediaType = 'image';

      final imageUploadResult = await _locketUploadService.uploadFile(
        imageFile,
      );

      imageUrl = imageUploadResult.downloadUrl;
      mediaUrl = imageUrl;
      thumbnailUrl = imageUrl;
    } else {
      finalMediaType = 'none';
    }

    final transaction = TransactionModel(
      id: id,
      userId: userId,
      amount: amount,
      type: type,
      category: category,
      caption: caption,
      note: note,

      // Field cũ.
      imageUrl: imageUrl,

      // Field mới.
      mediaType: finalMediaType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      durationMs: finalMediaType == 'video' ? durationMs : null,

      createdAt: createdAt,
      locationName: locationName,
      sharedToFeed: sharedToFeed,
      privacy: privacy,
      closeFriendUids: closeFriendUids,
      taggedUsernames: taggedUsernames,
      categoryIconCodePoint: categoryIconCodePoint,
      categoryColorHex: categoryColorHex,
      groupId: groupId,
      groupName: groupName,
      groupMemberIds: groupMemberIds,
      latitude: latitude,
      longitude: longitude,
      isGroupExpense: isGroupExpense,
      isGroupContribution: isGroupContribution,
      isFrontCamera: isFrontCamera,
    );

    await _remote.addTransaction(transaction);

    if (transaction.groupId != null && transaction.groupId!.isNotEmpty) {
      try {
        await _db
            .collection('groups')
            .doc(transaction.groupId)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }

    // Chi tieu tu quy nhom khong phai la chi tieu ca nhan nen khong tru vao budget ca nhan
    if (type == 'expense' && !transaction.isGroupExpense) {
      await _budgetRepository.addSpentAmount(
        uid: userId,
        budgetName: category,
        amount: amount,
      );
    }

    // Push notification to group members if this is a group expense or contribution
    if (transaction.groupId != null && transaction.groupId!.isNotEmpty) {
      unawaited(() async {
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          final userData = userDoc.data();
          final userName =
              userData?['name'] ?? userData?['username'] ?? 'Thành viên';

          List<String> memberIds = List<String>.from(transaction.groupMemberIds);
          String gName = transaction.groupName ?? 'Nhóm';

          if (memberIds.isEmpty) {
            // 1. Check in chats collection
            final chatDoc = await _db.collection('chats').doc(transaction.groupId).get();
            if (chatDoc.exists && chatDoc.data() != null) {
              final cData = chatDoc.data()!;
              gName = cData['groupName']?.toString() ?? cData['name']?.toString() ?? gName;
              final rawMembers = cData['participants'] ?? cData['members'] ?? [];
              if (rawMembers is List) {
                memberIds = rawMembers.map((e) => e.toString()).toList();
              }
            }
            // 2. Check in user's groups subcollection if still empty
            if (memberIds.isEmpty) {
              final userGroupDoc = await _db.collection('users').doc(userId).collection('groups').doc(transaction.groupId).get();
              if (userGroupDoc.exists && userGroupDoc.data() != null) {
                final ugData = userGroupDoc.data()!;
                gName = ugData['name']?.toString() ?? ugData['groupName']?.toString() ?? gName;
                final rawMembers = ugData['memberIds'] ?? ugData['members'] ?? [];
                if (rawMembers is List) {
                  memberIds = rawMembers.map((e) => e.toString()).toList();
                }
              }
            }
            // 3. Check legacy group_chats
            if (memberIds.isEmpty) {
              final groupDoc = await _db.collection('group_chats').doc(transaction.groupId).get();
              if (groupDoc.exists && groupDoc.data() != null) {
                final gData = groupDoc.data()!;
                gName = gData['name'] ?? gName;
                final rawMembers = gData['members'] ?? gData['participants'] ?? [];
                if (rawMembers is List) {
                  memberIds = rawMembers.map((e) => e.toString()).toList();
                }
              }
            }
          }

          if (memberIds.isNotEmpty) {
            await FcmPushService.instance.sendGroupTransactionNotification(
              groupId: transaction.groupId!,
              groupName: gName,
              creatorUid: userId,
              creatorName: userName,
              amount: transaction.amount,
              category: transaction.category,
              caption: transaction.caption,
              isGroupContribution: transaction.isGroupContribution,
              memberIds: memberIds,
              transactionId: transaction.id,
            );
          }
        } catch (e) {
          debugPrint('Error sending group transaction FCM: $e');
        }
      }());
    }

    // Cancel today's 20:00 reminder since user has recorded an expense today
    unawaited(() async {
      try {
        await NotificationService.instance.onExpenseRecordedToday(uid: userId);
      } catch (_) {}
    }());

    return transaction;
  }

  Future<File?> _createVideoThumbnail(
    File videoFile, {
    bool isFrontCamera = false,
  }) async {
    try {
      if (!await videoFile.exists()) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();

      // 1. Trích xuất frame ở mốc thời gian ~300ms (hoặc fallback 100ms/0ms)
      // để tránh bị dính frame đen lúc cảm biến camera/video encoder vừa khởi động.
      String? thumbnailPath;
      try {
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: 300,
          maxWidth: 1080,
          maxHeight: 1080,
          quality: 85,
        );
      } catch (_) {
        // Fallback nếu video quá ngắn hoặc timeMs 300 lỗi
        try {
          thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoFile.path,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            timeMs: 100,
            maxWidth: 1080,
            maxHeight: 1080,
            quality: 85,
          );
        } catch (_) {
          thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoFile.path,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 1080,
            maxHeight: 1080,
            quality: 85,
          );
        }
      }

      if (thumbnailPath == null || thumbnailPath.trim().isEmpty) {
        return null;
      }

      final thumbnailFile = File(thumbnailPath);

      if (!await thumbnailFile.exists()) {
        return null;
      }

      // 2. Xử lý ảnh thumbnail y hệt như ảnh chụp thông thường:
      //    - Chuẩn hóa hướng xoay EXIF (bakeOrientation)
      //    - Lật gương nếu quay bằng camera trước (copyFlip)
      //    - Cắt vuông 1:1 từ trung tâm (copyCrop)
      //    - Lưu lại ảnh JPEG chất lượng cao
      try {
        final bytes = await thumbnailFile.readAsBytes();
        var thumbImg = img.decodeImage(bytes);
        if (thumbImg != null) {
          // Chuẩn hóa xoay
          thumbImg = img.bakeOrientation(thumbImg);

          // Lật gương nếu là camera trước
          if (isFrontCamera) {
            thumbImg = img.copyFlip(
              thumbImg,
              direction: img.FlipDirection.horizontal,
            );
          }

          // Cắt vuông 1:1 từ trung tâm
          final cropSize = thumbImg.width < thumbImg.height
              ? thumbImg.width
              : thumbImg.height;
          final offsetX = (thumbImg.width - cropSize) ~/ 2;
          final offsetY = (thumbImg.height - cropSize) ~/ 2;

          final croppedThumb = img.copyCrop(
            thumbImg,
            x: offsetX,
            y: offsetY,
            width: cropSize,
            height: cropSize,
          );

          await thumbnailFile.writeAsBytes(
            img.encodeJpg(croppedThumb, quality: 85),
            flush: true,
          );
        }
      } catch (e) {
        debugPrint('Thumbnail crop/process error: $e');
      }

      return thumbnailFile;
    } catch (e) {
      debugPrint('Video thumbnail creation failed: $e');
      return null;
    }
  }

  Stream<List<TransactionModel>> streamTransactions(String uid) {
    return _remote.streamTransactions(uid);
  }

  Future<List<TransactionModel>> fetchTransactions(String uid) {
    return _remote.fetchTransactions(uid);
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    final txRef = _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId);

    final snapshot = await txRef.get();
    final data = snapshot.data();

    if (data != null) {
      final tx = TransactionModel.fromMap({
        ...data,
        'id': data['id'] ?? transactionId,
      });

      if (tx.type == 'expense') {
        await _budgetRepository.removeSpentAmount(
          uid: userId,
          budgetName: tx.category,
          amount: tx.amount,
        );
      }
    }

    await _remote.deleteTransaction(userId, transactionId);
  }

  Future<void> updateTransaction({
    required TransactionModel oldTransaction,
    required TransactionModel newTransaction,
  }) async {
    await _remote.updateTransaction(newTransaction);

    if (newTransaction.groupId != null && newTransaction.groupId!.isNotEmpty) {
      try {
        await _db
            .collection('groups')
            .doc(newTransaction.groupId)
            .collection('transactions')
            .doc(newTransaction.id)
            .set(newTransaction.toMap(), SetOptions(merge: true));
      } catch (_) {}
    } else if (oldTransaction.groupId != null &&
        oldTransaction.groupId!.isNotEmpty &&
        oldTransaction.groupId != newTransaction.groupId) {
      try {
        await _db
            .collection('groups')
            .doc(oldTransaction.groupId)
            .collection('transactions')
            .doc(oldTransaction.id)
            .delete();
      } catch (_) {}
    }

    final oldWasPersonalExpense = oldTransaction.isPersonalExpense;
    final newIsPersonalExpense = newTransaction.isPersonalExpense;

    if (oldWasPersonalExpense && newIsPersonalExpense) {
      if (oldTransaction.category == newTransaction.category) {
        final diff = newTransaction.amount - oldTransaction.amount;
        if (diff > 0) {
          await _budgetRepository.addSpentAmount(
            uid: newTransaction.userId,
            budgetName: newTransaction.category,
            amount: diff,
          );
        } else if (diff < 0) {
          await _budgetRepository.removeSpentAmount(
            uid: newTransaction.userId,
            budgetName: newTransaction.category,
            amount: -diff,
          );
        }
      } else {
        await _budgetRepository.removeSpentAmount(
          uid: oldTransaction.userId,
          budgetName: oldTransaction.category,
          amount: oldTransaction.amount,
        );
        await _budgetRepository.addSpentAmount(
          uid: newTransaction.userId,
          budgetName: newTransaction.category,
          amount: newTransaction.amount,
        );
      }
    } else if (oldWasPersonalExpense && !newIsPersonalExpense) {
      await _budgetRepository.removeSpentAmount(
        uid: oldTransaction.userId,
        budgetName: oldTransaction.category,
        amount: oldTransaction.amount,
      );
    } else if (!oldWasPersonalExpense && newIsPersonalExpense) {
      await _budgetRepository.addSpentAmount(
        uid: newTransaction.userId,
        budgetName: newTransaction.category,
        amount: newTransaction.amount,
      );
    }
  }

  Future<TransactionModel?> fetchTransactionById(
    String transactionId, {
    String? groupId,
  }) async {
    try {
      if (groupId != null && groupId.isNotEmpty) {
        final groupDoc = await _db
            .collection('groups')
            .doc(groupId)
            .collection('transactions')
            .doc(transactionId)
            .get();
        if (groupDoc.exists && groupDoc.data() != null) {
          final data = groupDoc.data()!;
          return TransactionModel.fromMap({
            ...data,
            'id': data['id'] ?? groupDoc.id,
          });
        }
      }

      final snapshot = await _db
          .collectionGroup('transactions')
          .where('id', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      return TransactionModel.fromMap({
        ...data,
        'id': data['id'] ?? doc.id,
      });
    } catch (e) {
      return null;
    }
  }

  /// Finds a group expense transaction matching the group and message timestamp.
  /// Useful for backfilling or displaying posts for historical system log messages.
  Future<TransactionModel?> findGroupExpenseTransaction({
    required String groupId,
    required DateTime messageTime,
    String? actorUid,
  }) async {
    try {
      // 1. Try querying from groups/{groupId}/transactions subcollection first
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
      try {
        final groupSnap = await _db
            .collection('groups')
            .doc(groupId)
            .collection('transactions')
            .get();
        docs.addAll(groupSnap.docs);
      } catch (_) {}

      // 2. If empty, fallback to collectionGroup
      if (docs.isEmpty) {
        try {
          final snapshot = await _db
              .collectionGroup('transactions')
              .where('groupId', isEqualTo: groupId)
              .get();
          docs.addAll(snapshot.docs);
        } catch (_) {}
      }

      TransactionModel? bestMatch;
      Duration? minDiff;

      for (final doc in docs) {
        try {
          final data = doc.data();
          final tx = TransactionModel.fromMap({
            ...data,
            'id': data['id'] ?? doc.id,
          });

          if (actorUid != null && actorUid.isNotEmpty && actorUid != 'system') {
            if (tx.userId != actorUid) continue;
          }

          final diff = (tx.createdAt.difference(messageTime)).abs();
          if (diff <= const Duration(hours: 1)) {
            if (minDiff == null || diff < minDiff) {
              minDiff = diff;
              bestMatch = tx;
            }
          }
        } catch (_) {}
      }

      return bestMatch;
    } catch (_) {
      return null;
    }
  }

  Future<List<TransactionModel>> fetchFeedPosts({
    required String viewerUid,
    required List<String> userIds,
    List<String> friendIds = const [],
  }) async {
    if (userIds.isEmpty) return [];

    // Use a Set for O(1) look-up when checking actual friendship
    final friendIdSet = {...friendIds};

    final Map<String, TransactionModel> uniqueMap = {};

    for (int i = 0; i < userIds.length; i += 10) {
      final batchIds = userIds.skip(i).take(10).toList();

      final snapshot = await _db
          .collectionGroup('transactions')
          .where('userId', whereIn: batchIds)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final txId = (data['id'] ?? doc.id).toString();

          // Tránh lặp bài do giao dịch nhóm được lưu ở cả users/ và groups/
          if (uniqueMap.containsKey(txId)) continue;

          final tx = TransactionModel.fromMap({
            ...data,
            'id': txId,
          });

          if (tx.userId == viewerUid) {
            uniqueMap[tx.id] = tx;
            continue;
          }

          if (tx.sharedToFeed == true) {
            if (tx.privacy == 'friends') {
              // Only show if the author is an actual friend (not just a shared group member)
              if (friendIdSet.isEmpty || friendIdSet.contains(tx.userId)) {
                uniqueMap[tx.id] = tx;
              }
            } else if (tx.privacy == 'close_friends') {
              if (tx.closeFriendUids.contains(viewerUid)) {
                uniqueMap[tx.id] = tx;
              } else if (tx.closeFriendUids.isEmpty) {
                // Fallback for legacy posts saved before closeFriendUids list was recorded on the transaction
                final authorFriendDoc = await _db
                    .collection('users')
                    .doc(tx.userId)
                    .collection('friends')
                    .doc(viewerUid)
                    .get();

                if (authorFriendDoc.exists &&
                    authorFriendDoc.data()?['isCloseFriend'] == true) {
                  uniqueMap[tx.id] = tx;
                }
              }
            } else if (tx.privacy == 'group') {
              if (tx.groupMemberIds.contains(viewerUid)) {
                uniqueMap[tx.id] = tx;
              } else if (tx.groupId != null && tx.groupId!.isNotEmpty) {
                final userGroupDoc = await _db
                    .collection('users')
                    .doc(viewerUid)
                    .collection('groups')
                    .doc(tx.groupId)
                    .get();
                if (userGroupDoc.exists) {
                  uniqueMap[tx.id] = tx;
                }
              }
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    final all = uniqueMap.values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }


  Future<List<TransactionModel>> fetchFriendsFeed(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];

    final Map<String, TransactionModel> uniqueMap = {};

    for (int i = 0; i < friendIds.length; i += 10) {
      final batchIds = friendIds.skip(i).take(10).toList();

      final snapshot = await _db
          .collectionGroup('transactions')
          .where('userId', whereIn: batchIds)
          .where('sharedToFeed', isEqualTo: true)
          .where('privacy', isEqualTo: 'friends')
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final txId = (data['id'] ?? doc.id).toString();

          if (uniqueMap.containsKey(txId)) continue;

          final tx = TransactionModel.fromMap({
            ...data,
            'id': txId,
          });

          uniqueMap[tx.id] = tx;
        } catch (_) {
          continue;
        }
      }
    }

    final all = uniqueMap.values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Lắng nghe theo thời gian thực danh sách tất cả giao dịch chi tiêu của nhóm
  Stream<List<TransactionModel>> streamGroupTransactions(String groupId) {
    if (groupId.isEmpty) return Stream.value([]);
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('transactions')
        .snapshots()
        .asyncMap((groupSnap) async {
      final Map<String, TransactionModel> map = {};

      for (final doc in groupSnap.docs) {
        try {
          final data = doc.data();
          final tx = TransactionModel.fromMap({
            ...data,
            'id': data['id'] ?? doc.id,
          });
          map[tx.id] = tx;
        } catch (_) {}
      }

      // Query thêm từ collectionGroup để backfill các transaction lịch sử cũ (nếu có)
      try {
        final cgSnap = await _db
            .collectionGroup('transactions')
            .where('groupId', isEqualTo: groupId)
            .get();
        for (final doc in cgSnap.docs) {
          try {
            final data = doc.data();
            final tx = TransactionModel.fromMap({
              ...data,
              'id': data['id'] ?? doc.id,
            });
            if (!map.containsKey(tx.id)) {
              map[tx.id] = tx;
              // Đồng bộ ngầm vào subcollection của nhóm để các lần sau tải nhanh hơn
              _db
                  .collection('groups')
                  .doc(groupId)
                  .collection('transactions')
                  .doc(tx.id)
                  .set(tx.toMap(), SetOptions(merge: true))
                  .catchError((_) {});
            }
          } catch (_) {}
        }
      } catch (_) {}

      final list = map.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  void dispose() {
    _locketUploadService.close();
  }
}