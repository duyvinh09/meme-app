import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/services/locket/locket_upload_service.dart';
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

      final thumbnailFile = await _createVideoThumbnail(videoFile);

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
    );

    await _remote.addTransaction(transaction);

    if (type == 'expense') {
      await _budgetRepository.addSpentAmount(
        uid: userId,
        budgetName: category,
        amount: amount,
      );
    }

    return transaction;
  }

  Future<File?> _createVideoThumbnail(File videoFile) async {
    try {
      if (!await videoFile.exists()) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        maxHeight: 720,
        quality: 82,
      );

      if (thumbnailPath == null || thumbnailPath.trim().isEmpty) {
        return null;
      }

      final thumbnailFile = File(thumbnailPath);

      if (!await thumbnailFile.exists()) {
        return null;
      }

      return thumbnailFile;
    } catch (e) {
      // Nếu tạo thumbnail lỗi thì vẫn cho lưu video,
      // nhưng Home/Calendar sẽ không có ảnh đại diện video.
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

  Future<TransactionModel?> fetchTransactionById(String transactionId) async {
    try {
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

  Future<List<TransactionModel>> fetchFeedPosts({
    required String viewerUid,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return [];

    final List<TransactionModel> all = [];

    for (int i = 0; i < userIds.length; i += 10) {
      final batchIds = userIds.skip(i).take(10).toList();

      final snapshot = await _db
          .collectionGroup('transactions')
          .where('userId', whereIn: batchIds)
          .get();

      final items = <TransactionModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          final tx = TransactionModel.fromMap({
            ...data,
            'id': data['id'] ?? doc.id,
          });

          if (tx.userId == viewerUid) {
            items.add(tx);
            continue;
          }

          if (tx.sharedToFeed == true) {
            if (tx.privacy == 'friends' || tx.privacy == 'everyone') {
              items.add(tx);
            } else if (tx.privacy == 'close_friends') {
              if (tx.closeFriendUids.contains(viewerUid)) {
                items.add(tx);
              } else {
                final authorFriendDoc = await _db
                    .collection('users')
                    .doc(tx.userId)
                    .collection('friends')
                    .doc(viewerUid)
                    .get();

                if (authorFriendDoc.exists &&
                    authorFriendDoc.data()?['isCloseFriend'] == true) {
                  items.add(tx);
                }
              }
            } else if (tx.privacy == 'group') {
              if (tx.groupMemberIds.contains(viewerUid)) {
                items.add(tx);
              } else if (tx.groupId != null && tx.groupId!.isNotEmpty) {
                final userGroupDoc = await _db
                    .collection('users')
                    .doc(viewerUid)
                    .collection('groups')
                    .doc(tx.groupId)
                    .get();
                if (userGroupDoc.exists) {
                  items.add(tx);
                }
              }
            }
          }
        } catch (_) {
          continue;
        }
      }

      all.addAll(items);
    }

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<List<TransactionModel>> fetchFriendsFeed(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];

    final List<TransactionModel> all = [];

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

          all.add(
            TransactionModel.fromMap({
              ...data,
              'id': data['id'] ?? doc.id,
            }),
          );
        } catch (_) {
          continue;
        }
      }
    }

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  void dispose() {
    _locketUploadService.close();
  }
}