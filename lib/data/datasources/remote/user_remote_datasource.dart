import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserRemoteDataSource {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    if (uid.trim().isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      try {
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromMap(doc.data()!);
      } catch (_) {
        return null;
      }
    });
  }

  Stream<int> streamPendingFriendRequestCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> streamSentFriendRequests(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('sentFriendRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
    );
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }
}