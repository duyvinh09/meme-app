import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/services/local_settings_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfileController extends ChangeNotifier {
  final LocalSettingsService localSettingsService;
  final UserRepository userRepository;

  ProfileController({
    required this.localSettingsService,
    required this.userRepository,
  });

  final CloudinaryService _cloudinaryService = CloudinaryService();

  UserModel? user;
  bool isSaving = false;

  String get languageCode => localSettingsService.languageCode;
  String get rawLanguageCode => localSettingsService.rawLanguageCode;
  String get currency => localSettingsService.currency;
  ThemeMode get themeMode => localSettingsService.themeMode;

  Future<void> loadUser(String uid) async {
    user = await userRepository.getUserProfile(uid);
    notifyListeners();
  }

  Future<void> refreshUser(String uid) async {
    user = await userRepository.getUserProfile(uid);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String uid,
    required String name,
    File? avatarFile,
  }) async {
    try {
      isSaving = true;
      notifyListeners();

      String? avatarUrl;

      if (avatarFile != null) {
        avatarUrl = await _cloudinaryService.uploadTransactionImage(
          file: avatarFile,
          folder: 'moment_money/$uid/avatar',
        );
      }

      final Map<String, dynamic> data = {
        'name': name.trim(),
      };

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        data['avatarUrl'] = avatarUrl;
      }

      await userRepository.updateUserProfile(uid, data);
      await refreshUser(uid);

      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatarFrame(String uid, String frameId) async {
    try {
      await userRepository.updateUserProfile(uid, {'avatarFrame': frameId});
      await refreshUser(uid);
      return true;
    } catch (e) {
      debugPrint('updateAvatarFrame error: $e');
      return false;
    }
  }

  Future<void> setLanguage(String value, [String? uid]) async {
    await localSettingsService.setLanguageCode(value);
    if (uid != null && uid.isNotEmpty) {
      await userRepository.updateUserProfile(uid, {'language': value});
    }
    notifyListeners();
  }

  Future<void> setCurrency(String value, [String? uid]) async {
    await localSettingsService.setCurrency(value);
    if (uid != null && uid.isNotEmpty) {
      await userRepository.updateUserProfile(uid, {'currency': value});
    }
    notifyListeners();

    if (value.toUpperCase() == 'USD') {
      await ExchangeRateService.refresh();
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String value, [String? uid]) async {
    await localSettingsService.setThemeMode(value);
    if (uid != null && uid.isNotEmpty) {
      await userRepository.updateUserProfile(uid, {'themeMode': value});
    }
    notifyListeners();
  }

  String get cameraTheme => localSettingsService.cameraTheme;

  Future<void> setCameraTheme(String value, [String? uid]) async {
    await localSettingsService.setCameraTheme(value);
    if (uid != null && uid.isNotEmpty) {
      await userRepository.updateUserProfile(uid, {'cameraTheme': value});
    }
    notifyListeners();
  }

  bool get showActiveStatus => localSettingsService.showActiveStatus;
  String get activeStatusMode => localSettingsService.activeStatusMode;

  Future<void> setShowActiveStatus(bool value, [String? uid]) async {
    await localSettingsService.setShowActiveStatus(value);
    if (uid != null && uid.isNotEmpty) {
      await userRepository.updateUserProfile(uid, {
        'showActiveStatus': value,
        if (!value) 'isOnline': false,
      });
      await userRepository.updateUserPresence(uid, isOnline: value);
    }
    notifyListeners();
  }

  Future<void> setActiveStatusMode(String mode, [String? uid]) async {
    await localSettingsService.setActiveStatusMode(mode);
    if (uid != null && uid.isNotEmpty) {
      final isOnline = mode != 'none';
      await userRepository.updateUserProfile(uid, {
        'showActiveStatus': isOnline,
        'activeStatusMode': mode,
        if (!isOnline) 'isOnline': false,
      });
      await userRepository.updateUserPresence(uid, isOnline: isOnline);
    }
    notifyListeners();
  }

  Future<bool> updateEmailAddress({
    required AuthRepository authRepository,
    required String uid,
    required String currentEmail,
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      isSaving = true;
      notifyListeners();

      await authRepository.reauthenticateWithPassword(
        email: currentEmail,
        password: currentPassword,
      );

      await authRepository.verifyBeforeUpdateEmail(newEmail);

      await userRepository.updateUserEmail(
        uid: uid,
        email: newEmail,
      );

      await refreshUser(uid);

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('updateEmailAddress Firebase error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('updateEmailAddress error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}