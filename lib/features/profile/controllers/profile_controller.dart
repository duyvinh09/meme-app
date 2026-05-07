import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/services/local_settings_service.dart';
import '../../../core/services/cloudinary_service.dart';
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

  Future<void> setLanguage(String value) async {
    await localSettingsService.setLanguageCode(value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    await localSettingsService.setCurrency(value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    await localSettingsService.setThemeMode(value);
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