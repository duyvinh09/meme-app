import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';

class CaptureController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final UserRepository userRepository;

  AppLocationResult? selectedLocation;
  bool isLoadingLocation = false;

  CaptureController({
    required this.transactionRepository,
    required this.userRepository,
  });

  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  File? selectedVideo;

  String selectedMediaType = 'none'; // none | image | video
  int? selectedVideoDurationMs;

  bool isSaving = false;

  bool get hasImage => selectedMediaType == 'image' && selectedImage != null;
  bool get hasVideo => selectedMediaType == 'video' && selectedVideo != null;
  bool get hasMedia => hasImage || hasVideo;

  void setImage(File file) {
    selectedImage = file;
    selectedVideo = null;
    selectedMediaType = 'image';
    selectedVideoDurationMs = null;
    notifyListeners();
  }

  void setVideo(
      File file, {
        int? durationMs,
      }) {
    selectedVideo = file;
    selectedImage = null;
    selectedMediaType = 'video';
    selectedVideoDurationMs = durationMs;
    notifyListeners();
  }

  Future<void> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (file != null) {
      setImage(File(file.path));
    }
  }

  Future<void> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (file != null) {
      setImage(File(file.path));
    }
  }

  Future<void> pickVideoFromGallery() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 5),
    );

    if (file != null) {
      setVideo(
        File(file.path),
        durationMs: null,
      );
    }
  }

  void clearImage() {
    if (selectedMediaType == 'image') {
      selectedMediaType = 'none';
    }

    selectedImage = null;
    notifyListeners();
  }

  void clearVideo() {
    if (selectedMediaType == 'video') {
      selectedMediaType = 'none';
    }

    selectedVideo = null;
    selectedVideoDurationMs = null;
    notifyListeners();
  }

  void clearMedia() {
    selectedImage = null;
    selectedVideo = null;
    selectedMediaType = 'none';
    selectedVideoDurationMs = null;
    notifyListeners();
  }

  Future<void> prepareLocation() async {
    try {
      isLoadingLocation = true;
      notifyListeners();

      selectedLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      debugPrint('prepareLocation error: $e');
      selectedLocation = null;
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  void clearLocation() {
    selectedLocation = null;
    notifyListeners();
  }

  Future<void> _updateUserStreak({
    required String userId,
    required DateTime newTransactionDate,
  }) async {
    final UserModel? profile = await userRepository.getUserProfile(userId);
    if (profile == null) return;

    final nowDay = DateTime.utc(
      newTransactionDate.year,
      newTransactionDate.month,
      newTransactionDate.day,
    );

    final lastActiveDay = DateTime.utc(
      profile.lastActiveDate.year,
      profile.lastActiveDate.month,
      profile.lastActiveDate.day,
    );

    int newCurrent = profile.currentStreak;
    int newBest = profile.bestStreak;

    final diff = nowDay.difference(lastActiveDay).inDays;

    if (profile.currentStreak == 0) {
      newCurrent = 1;
      newBest = 1;
    } else if (diff == 0) {
      newCurrent = profile.currentStreak;
      newBest = profile.bestStreak;
    } else if (diff == 1) {
      newCurrent = profile.currentStreak + 1;
      newBest = newCurrent > profile.bestStreak
          ? newCurrent
          : profile.bestStreak;
    } else {
      newCurrent = 1;
      newBest = profile.bestStreak > 0 ? profile.bestStreak : 1;
    }

    final Map<String, dynamic> streakUpdates = {
      'currentStreak': newCurrent,
      'bestStreak': newBest,
      'lastActiveDate': newTransactionDate,
    };

    await userRepository.updateUserProfile(userId, streakUpdates);
  }

  Future<bool> saveTransaction({
    required String userId,
    required double amount,
    required String type,
    required String category,
    required String caption,
    required String note,
    required bool sharedToFeed,
    required String privacy,
    List<String> closeFriendUids = const [],
    String? groupId,
    String? groupName,
    List<String> groupMemberIds = const [],
    int? categoryIconCodePoint,
    String? categoryColorHex,
    String locationName = '',
    double? latitude,
    double? longitude,
  }) async {
    try {
      isSaving = true;
      notifyListeners();

      final now = DateTime.now();

      // Resolve valid tagged usernames:
      // 1. If privacy == 'private': NO valid tags (treated as plain text).
      // 2. If privacy == 'close_friends': ONLY friends whose UID is in closeFriendUids.
      // 3. If privacy == 'friends': all valid existing friends.
      final validTaggedUsernames = <String>[];
      final mentionRegex = RegExp(r'@([a-zA-Z0-9_.]+)');
      final matches = mentionRegex.allMatches(caption);

      if (caption.trim().isNotEmpty && privacy != 'private' && matches.isNotEmpty) {
        final checkedUsernames = <String>{};
        for (final m in matches) {
          final uName = m.group(1)?.toLowerCase();
          if (uName == null || uName.isEmpty || checkedUsernames.contains(uName)) continue;
          checkedUsernames.add(uName);

          final taggedUser = await userRepository.findUserByUsername(uName);
          if (taggedUser == null || taggedUser.uid == userId) continue;

          // If close_friends, user MUST be in closeFriendUids to be an active tag
          if (privacy == 'close_friends' && !closeFriendUids.contains(taggedUser.uid)) {
            continue;
          }

          validTaggedUsernames.add(uName);
        }
      }

      final savedTx = await transactionRepository.addTransaction(
        userId: userId,
        amount: amount,
        type: type,
        category: category,
        caption: caption,
        note: note,
        createdAt: now,

        imageFile: selectedMediaType == 'image' ? selectedImage : null,
        videoFile: selectedMediaType == 'video' ? selectedVideo : null,
        mediaType: selectedMediaType,
        durationMs: selectedMediaType == 'video'
            ? selectedVideoDurationMs
            : null,

        sharedToFeed: sharedToFeed,
        privacy: privacy,
        closeFriendUids: closeFriendUids,
        taggedUsernames: validTaggedUsernames,
        categoryIconCodePoint: categoryIconCodePoint,
        categoryColorHex: categoryColorHex,
        groupId: groupId,
        groupName: groupName,
        groupMemberIds: groupMemberIds,
        locationName: selectedLocation?.locationName ?? locationName,
        latitude: selectedLocation?.latitude ?? latitude,
        longitude: selectedLocation?.longitude ?? longitude,
      );

      await _updateUserStreak(
        userId: userId,
        newTransactionDate: now,
      );

      // If this spending was logged for a group, update group contribution and log system message
      if (privacy == 'group' && groupId != null && groupId.isNotEmpty) {
        if (type == 'expense') {
          try {
            await userRepository.addGroupContribution(
              groupId: groupId,
              actorUid: userId,
              memberUid: userId,
              amount: amount,
              sendSystemMessage: false,
            );
          } catch (_) {}
        }

        try {
          final author = await userRepository.getUserProfile(userId);
          final authorName = author?.name.isNotEmpty == true
              ? author!.name
              : (author?.username.isNotEmpty == true
                  ? '@${author!.username}'
                  : 'Thành viên');
          final moneyStr = AppCurrencyFormatter.formatFromVnd(
            amountVnd: amount,
            currency: 'VND',
          );
          await ChatRepository().sendGroupSystemMessage(
            groupId: groupId,
            systemText:
                '$authorName đã thêm chi tiêu $moneyStr cho "$category"',
            actorUid: userId,
          );
        } catch (_) {}
      }

      // Notify mentioned friends in caption if post is visible to them
      if (validTaggedUsernames.isNotEmpty && sharedToFeed) {
        _notifyMentionedUsers(
          authorUid: userId,
          caption: caption.trim(),
          postId: savedTx.id,
          postImageUrl: savedTx.thumbnailUrl.isNotEmpty
              ? savedTx.thumbnailUrl
              : savedTx.imageUrl,
          validTaggedUsernames: validTaggedUsernames,
        );
      }

      clearMedia();
      clearLocation();

      return true;
    } catch (e) {
      debugPrint('saveTransaction error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Send notifications to friends tagged via @username in caption
  Future<void> _notifyMentionedUsers({
    required String authorUid,
    required String caption,
    required String postId,
    required String postImageUrl,
    required List<String> validTaggedUsernames,
  }) async {
    if (validTaggedUsernames.isEmpty) return;

    try {
      final author = await userRepository.getUserProfile(authorUid);
      final authorName = author?.name.isNotEmpty == true
          ? author!.name
          : (author?.username.isNotEmpty == true ? '@${author!.username}' : 'Bạn bè');

      for (final username in validTaggedUsernames) {
        final taggedUser = await userRepository.findUserByUsername(username);
        if (taggedUser == null || taggedUser.uid == authorUid) {
          continue;
        }

        final notifDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(taggedUser.uid)
            .collection('notifications')
            .doc();

        await notifDoc.set({
          'id': notifDoc.id,
          'type': 'mention',
          'senderUid': authorUid,
          'senderName': authorName,
          'senderAvatar': author?.avatarUrl ?? '',
          'senderAvatarFrame': author?.avatarFrame ?? 'plain',
          'postId': postId,
          'postImageUrl': postImageUrl,
          'caption': caption,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      debugPrint('Error notifying mentioned users: $e');
    }
  }
}