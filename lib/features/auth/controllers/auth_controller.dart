import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  AuthController({
    required this.authRepository,
    required this.userRepository,
  });

  User? user;
  bool isLoading = false;
  String? error;

  StreamSubscription<User?>? _authSub;

  void init() {
    _authSub?.cancel();

    _authSub = authRepository.authStateChanges().listen((firebaseUser) {
      user = firebaseUser;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final credential = await authRepository.login(
        email: email.trim(),
        password: password,
      );

      user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      error = _firebaseErrorMessage(e, fallback: 'Đăng nhập thất bại');
      return false;
    } catch (e) {
      debugPrint('login error: $e');
      error = 'Đăng nhập thất bại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final cleanedName = name.trim();
      final cleanedEmail = email.trim();
      final cleanedUsername = username.trim().toLowerCase();

      if (cleanedName.isEmpty) {
        error = 'Vui lòng nhập tên';
        return false;
      }

      if (cleanedUsername.isEmpty) {
        error = 'Vui lòng nhập username';
        return false;
      }

      final existed = await userRepository.isUsernameTaken(cleanedUsername);

      if (existed) {
        error = 'Username đã tồn tại';
        return false;
      }

      final credential = await authRepository.register(
        email: cleanedEmail,
        password: password,
      );

      user = credential.user;

      if (user != null) {
        final now = DateTime.now();

        await userRepository.createUserProfile(
          UserModel(
            uid: user!.uid,
            name: cleanedName,
            username: cleanedUsername,
            email: cleanedEmail,
            avatarUrl: '',
            currency: 'VND',
            language: 'vi',
            themeMode: 'system',
            currentStreak: 0,
            bestStreak: 0,
            createdAt: now,
            lastActiveDate: now,
          ),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      error = _firebaseErrorMessage(e, fallback: 'Đăng ký thất bại');
      return false;
    } catch (e) {
      debugPrint('register error: $e');
      error = 'Đăng ký thất bại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
      user = null;
      error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('logout error: $e');
    }
  }

  Future<bool> sendResetPassword(String email) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await authRepository.sendPasswordReset(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      error = _firebaseErrorMessage(e, fallback: 'Gửi email đặt lại mật khẩu thất bại');
      return false;
    } catch (e) {
      debugPrint('sendResetPassword error: $e');
      error = 'Gửi email đặt lại mật khẩu thất bại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _firebaseErrorMessage(
      FirebaseAuthException e, {
        required String fallback,
      }) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hoá';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần, vui lòng thử lại sau';
      default:
        return e.message ?? fallback;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}