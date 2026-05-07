import 'package:firebase_auth/firebase_auth.dart';

import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _remote = AuthRemoteDataSource();

  User? get currentUser => _remote.currentUser;

  Stream<User?> authStateChanges() {
    return _remote.authStateChanges();
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _remote.login(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _remote.register(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _remote.sendPasswordReset(email.trim());
  }

  Future<void> logout() {
    return _remote.logout();
  }

  Future<void> reloadCurrentUser() async {
    await _remote.currentUser?.reload();
  }

  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  }) async {
    final user = _remote.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Không tìm thấy người dùng hiện tại',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    final user = _remote.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Không tìm thấy người dùng hiện tại',
      );
    }

    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> deleteCurrentUser() async {
    final user = _remote.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Không tìm thấy người dùng hiện tại',
      );
    }

    await user.delete();
  }
}