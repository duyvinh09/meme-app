import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/location_service.dart';
import '../../../data/models/user_model.dart';
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

    final nowDay = DateTime(
      newTransactionDate.year,
      newTransactionDate.month,
      newTransactionDate.day,
    );

    final lastActiveDay = DateTime(
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

    await userRepository.updateUserProfile(userId, {
      'currentStreak': newCurrent,
      'bestStreak': newBest,
      'lastActiveDate': newTransactionDate,
    });
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

      await transactionRepository.addTransaction(
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
        categoryIconCodePoint: categoryIconCodePoint,
        categoryColorHex: categoryColorHex,
        locationName: selectedLocation?.locationName ?? locationName,
        latitude: selectedLocation?.latitude ?? latitude,
        longitude: selectedLocation?.longitude ?? longitude,
      );

      await _updateUserStreak(
        userId: userId,
        newTransactionDate: now,
      );

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
}