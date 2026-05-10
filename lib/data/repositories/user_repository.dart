import 'package:cloud_firestore/cloud_firestore.dart';

import '../datasources/remote/user_remote_datasource.dart';
import '../models/user_model.dart';

/// Connection state shown when searching a username on Add Friend.
enum AddFriendConnectionState {
  canSend,
  pendingSent,
  alreadyFriends,
}

class UserRepository {
  /// Max length for group names (Firestore + UI). UTF-16 code units.
  static const int maxGroupNameLength = 50;
  final UserRemoteDataSource _remote = UserRemoteDataSource();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserProfile(UserModel user) {
    return _remote.createUserProfile(user);
  }

  Future<UserModel?> getUserProfile(String uid) {
    return _remote.getUserProfile(uid);
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _remote.streamUserProfile(uid);
  }

  Stream<int> streamPendingFriendRequestCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> streamSentFriendRequests(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('sent_friend_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _remote.updateUserProfile(uid, data);
  }

  Future<void> updateUserEmail({
    required String uid,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).update({
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isUsernameTaken(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<UserModel?> findUserByUsername(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();

    if (data['isDeleted'] == true) {
      return null;
    }

    return UserModel.fromMap(data);
  }

  Future<void> migrateOldUserIfNeeded({
    required String uid,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    final Map<String, dynamic> updates = {};

    if (data['uid'] == null || data['uid'] != uid) {
      updates['uid'] = uid;
    }

    if (data['username'] == null ||
        (data['username'] as String).trim().isEmpty) {
      final displayName = (data['displayName'] ?? '').toString().trim();
      updates['username'] = displayName.toLowerCase();
    }

    if (data['avatarUrl'] == null) {
      updates['avatarUrl'] = '';
    }

    if (data['currency'] == null) {
      updates['currency'] = 'VND';
    }

    if (data['language'] == null) {
      updates['language'] = 'vi';
    }

    if (data['themeMode'] == null) {
      updates['themeMode'] = 'system';
    }

    if (data['currentStreak'] == null) {
      updates['currentStreak'] = data['streakCount'] ?? 0;
    }

    if (data['bestStreak'] == null) {
      updates['bestStreak'] = data['currentStreak'] ?? 0;
    }

    if (data['lastActiveDate'] == null) {
      updates['lastActiveDate'] =
          data['createdAt'] ?? FieldValue.serverTimestamp();
    }

    if (data['displayName'] != null) {
      updates['displayName'] = FieldValue.delete();
    }

    if (data['streakCount'] != null) {
      updates['streakCount'] = FieldValue.delete();
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Future<String?> sendFriendRequest({
    required String myUid,
    required UserModel targetUser,
  }) async {
    final myProfile = await getUserProfile(myUid);
    if (myProfile == null) return 'Không tìm thấy hồ sơ của bạn';

    if (myProfile.isDeleted == true) {
      return 'Tài khoản của bạn không còn hoạt động';
    }

    if (targetUser.isDeleted == true) {
      return 'Tài khoản này đã bị xoá';
    }

    if (myUid == targetUser.uid) {
      return 'Bạn không thể tự kết bạn với chính mình';
    }

    final myFriendRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(targetUser.uid);

    final alreadyFriend = await myFriendRef.get();
    if (alreadyFriend.exists) {
      return 'Hai bạn đã là bạn bè';
    }

    // Kiểm tra chiều bình thường: mình đã gửi chưa
    final requestRef = _db
        .collection('users')
        .doc(targetUser.uid)
        .collection('friend_requests')
        .doc(myUid);

    final existingRequest = await requestRef.get();
    if (existingRequest.exists) {
      return 'Đã gửi lời mời trước đó';
    }

    // Kiểm tra chiều ngược: người kia đã gửi cho mình chưa
    final reverseRequestRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(targetUser.uid);

    final reverseRequest = await reverseRequestRef.get();

    if (reverseRequest.exists) {
      // Auto accept luôn
      await _createFriendConnection(
        userA: myProfile,
        userB: targetUser,
      );
      return 'auto_accepted';
    }

    final sentRequestRef = _db
        .collection('users')
        .doc(myUid)
        .collection('sent_friend_requests')
        .doc(targetUser.uid);

    await requestRef.set({
      'fromUid': myProfile.uid,
      'fromName': myProfile.name,
      'fromUsername': myProfile.username,
      'fromEmail': myProfile.email,
      'fromAvatarUrl': myProfile.avatarUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await sentRequestRef.set({
      'toUid': targetUser.uid,
      'toName': targetUser.name,
      'toUsername': targetUser.username,
      'toEmail': targetUser.email,
      'toAvatarUrl': targetUser.avatarUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return null;
  }

  Stream<List<Map<String, dynamic>>> streamFriendRequests(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friend_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Future<void> acceptFriendRequest({
    required String myUid,
    required Map<String, dynamic> requestData,
  }) async {
    final fromUid = requestData['fromUid'] as String;

    final myProfile = await getUserProfile(myUid);
    final fromProfile = await getUserProfile(fromUid);

    if (myProfile == null || fromProfile == null) return;

    final batch = _db.batch();

    final myFriendRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(fromUid);

    final fromFriendRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(myUid);

    batch.set(myFriendRef, {
      'uid': fromProfile.uid,
      'username': fromProfile.username,
      'addedAt': FieldValue.serverTimestamp(),
    });

    batch.set(fromFriendRef, {
      'uid': myProfile.uid,
      'username': myProfile.username,
      'addedAt': FieldValue.serverTimestamp(),
    });

    final receivedRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(fromUid);

    final sentRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('sent_friend_requests')
        .doc(myUid);

    batch.delete(receivedRef);
    batch.delete(sentRef);

    await batch.commit();
  }

  Future<void> rejectFriendRequest({
    required String myUid,
    required String fromUid,
  }) async {
    final batch = _db.batch();

    final receivedRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(fromUid);

    final sentRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('sent_friend_requests')
        .doc(myUid);

    batch.delete(receivedRef);
    batch.delete(sentRef);

    await batch.commit();
  }

  /// Withdraw a friend request I sent to [toUid] (clears both sides).
  Future<void> cancelSentFriendRequest({
    required String myUid,
    required String toUid,
  }) async {
    final batch = _db.batch();

    final receivedRef = _db
        .collection('users')
        .doc(toUid)
        .collection('friend_requests')
        .doc(myUid);

    final sentRef = _db
        .collection('users')
        .doc(myUid)
        .collection('sent_friend_requests')
        .doc(toUid);

    batch.delete(receivedRef);
    batch.delete(sentRef);

    await batch.commit();
  }

  Future<AddFriendConnectionState> getAddFriendConnectionState({
    required String myUid,
    required String targetUid,
  }) async {
    if (myUid == targetUid) {
      return AddFriendConnectionState.canSend;
    }

    final friendDoc = await _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(targetUid)
        .get();

    if (friendDoc.exists) {
      return AddFriendConnectionState.alreadyFriends;
    }

    final sentDoc = await _db
        .collection('users')
        .doc(myUid)
        .collection('sent_friend_requests')
        .doc(targetUid)
        .get();

    if (sentDoc.exists) {
      final status = sentDoc.data()?['status']?.toString() ?? 'pending';
      if (status == 'pending') {
        return AddFriendConnectionState.pendingSent;
      }
    }

    return AddFriendConnectionState.canSend;
  }

  Stream<List<Map<String, dynamic>>> streamFriends(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      final docs = snapshot.docs;

      final items = await Future.wait(
        docs.map((doc) async {
          final data = doc.data();
          final friendUid = (data['uid'] ?? '').toString();
          final savedUsername = (data['username'] ?? '').toString();

          final profile = await getUserProfile(friendUid);
          final isDeleted = profile?.isDeleted == true;

          return {
            'uid': friendUid,
            'username': isDeleted
                ? 'deleted_user'
                : profile?.username.isNotEmpty == true
                ? profile!.username
                : savedUsername,
            'name': isDeleted
                ? 'Tài khoản đã xoá'
                : profile?.name ?? 'Người dùng',
            'avatarUrl': isDeleted ? '' : profile?.avatarUrl ?? '',
            'isDeleted': isDeleted,
            'addedAt': data['addedAt'],
          };
        }),
      );

      items.sort((a, b) {
        final aTime = a['addedAt'];
        final bTime = b['addedAt'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });

      return items;
    });
  }

  Future<void> _createFriendConnection({
    required UserModel userA,
    required UserModel userB,
  }) async {
    final batch = _db.batch();

    final aFriendRef = _db
        .collection('users')
        .doc(userA.uid)
        .collection('friends')
        .doc(userB.uid);

    final bFriendRef = _db
        .collection('users')
        .doc(userB.uid)
        .collection('friends')
        .doc(userA.uid);

    batch.set(aFriendRef, {
      'uid': userB.uid,
      'username': userB.username,
      'addedAt': FieldValue.serverTimestamp(),
    });

    batch.set(bFriendRef, {
      'uid': userA.uid,
      'username': userA.username,
      'addedAt': FieldValue.serverTimestamp(),
    });

    final aReceivedFromB = _db
        .collection('users')
        .doc(userA.uid)
        .collection('friend_requests')
        .doc(userB.uid);

    final aSentToB = _db
        .collection('users')
        .doc(userA.uid)
        .collection('sent_friend_requests')
        .doc(userB.uid);

    final bReceivedFromA = _db
        .collection('users')
        .doc(userB.uid)
        .collection('friend_requests')
        .doc(userA.uid);

    final bSentToA = _db
        .collection('users')
        .doc(userB.uid)
        .collection('sent_friend_requests')
        .doc(userA.uid);

    batch.delete(aReceivedFromB);
    batch.delete(aSentToB);
    batch.delete(bReceivedFromA);
    batch.delete(bSentToA);

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> streamGroups(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Future<void> updateGroup({
    required String myUid,
    required String groupId,
    required String name,
    required List<String> memberIds,
    required String colorHex,
    required double goalAmount,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > maxGroupNameLength) {
      throw ArgumentError(
        trimmedName.isEmpty
            ? 'Group name cannot be empty'
            : 'Group name must be at most $maxGroupNameLength characters',
      );
    }

    final groupRef = _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc(groupId);

    final snapshot = await groupRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final ownerUid = (data['ownerUid'] ?? '').toString();

    if (ownerUid != myUid) {
      throw Exception('Chỉ chủ nhóm mới có thể chỉnh sửa nhóm');
    }

    final oldMemberIds =
        (data['memberIds'] as List?)?.map((e) => e.toString()).toSet() ??
            <String>{};

    final newMemberIds = {...memberIds, ownerUid}.toSet();

    final oldContributions = Map<String, dynamic>.from(
      data['memberContributions'] ?? {},
    );

    final safeContributions = <String, dynamic>{};

    for (final uid in newMemberIds) {
      safeContributions[uid] = oldContributions[uid] ?? 0;
    }

    final updatedData = {
      ...data,
      'name': trimmedName,
      'ownerUid': ownerUid,
      'memberIds': newMemberIds.toList(),
      'memberCount': newMemberIds.length,
      'color': colorHex,
      'goalAmount': goalAmount,
      'memberContributions': safeContributions,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();

    for (final uid in newMemberIds) {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(groupId);

      batch.set(ref, updatedData);
    }

    final removedMembers = oldMemberIds.difference(newMemberIds);

    for (final uid in removedMembers) {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(groupId);

      batch.delete(ref);
    }

    await batch.commit();
  }

  Future<void> leaveGroup({
    required String myUid,
    required String groupId,
  }) async {
    final myGroupRef = _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc(groupId);

    final snapshot = await myGroupRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final ownerUid = (data['ownerUid'] ?? '').toString();
    final currentMembers =
        (data['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

    if (!currentMembers.contains(myUid)) return;

    final remainingMembers = [...currentMembers]..remove(myUid);

    final batch = _db.batch();

    if (remainingMembers.isEmpty) {
      batch.delete(myGroupRef);
      await batch.commit();
      return;
    }

    String nextOwnerUid = ownerUid;
    if (ownerUid == myUid) {
      nextOwnerUid = remainingMembers.first;
    }

    final oldContributions = Map<String, dynamic>.from(
      data['memberContributions'] ?? {},
    );

    oldContributions.remove(myUid);

    final updatedData = {
      ...data,
      'ownerUid': nextOwnerUid,
      'memberIds': remainingMembers,
      'memberCount': remainingMembers.length,
      'memberContributions': oldContributions,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    for (final uid in remainingMembers) {
      final ref = _db.collection('users').doc(uid).collection('groups').doc(groupId);
      batch.set(ref, updatedData);
    }

    batch.delete(myGroupRef);

    await batch.commit();
  }

  Future<void> deleteGroup({
    required String myUid,
    required String groupId,
  }) async {
    final groupRef = _db
        .collection('users')
        .doc(myUid)
        .collection('groups')
        .doc(groupId);

    final snapshot = await groupRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final ownerUid = (data['ownerUid'] ?? '').toString();
    if (ownerUid != myUid) {
      throw Exception('Chỉ chủ nhóm mới có thể xoá nhóm');
    }

    final memberIds =
        (data['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final batch = _db.batch();

    for (final uid in memberIds) {
      final ref = _db.collection('users').doc(uid).collection('groups').doc(groupId);
      batch.delete(ref);
    }

    await batch.commit();
  }

  Future<void> removeFriend({
    required String myUid,
    required String friendUid,
  }) async {
    final batch = _db.batch();

    final myFriendRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(friendUid);

    final friendRef = _db
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(myUid);

    batch.delete(myFriendRef);
    batch.delete(friendRef);

    await batch.commit();
  }

  Future<void> createGroup({
    required String uid,
    required String name,
    required double goalAmount,
    List<String> memberIds = const [],
    String colorHex = '#79AFFF',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > maxGroupNameLength) {
      throw ArgumentError(
        trimmedName.isEmpty
            ? 'Group name cannot be empty'
            : 'Group name must be at most $maxGroupNameLength characters',
      );
    }

    final doc = _db.collection('users').doc(uid).collection('groups').doc();

    final uniqueMemberIds = {uid, ...memberIds}.toList();

    final groupData = {
      'id': doc.id,
      'name': trimmedName,
      'ownerUid': uid,
      'memberIds': uniqueMemberIds,
      'memberCount': uniqueMemberIds.length,
      'color': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
      'goalAmount': goalAmount,
      'currentAmount': 0,
      'memberContributions': {
        uid: 0,
        for (final memberId in memberIds) memberId: 0,
      },
    };

    final batch = _db.batch();

    for (final memberUid in uniqueMemberIds) {
      final ref = _db.collection('users').doc(memberUid).collection('groups').doc(doc.id);
      batch.set(ref, groupData);
    }

    await batch.commit();
  }

  Future<void> addGroupContribution({
    required String groupId,
    required String actorUid,
    required String memberUid,
    required double amount,
  }) async {
    final actorGroupRef = _db
        .collection('users')
        .doc(actorUid)
        .collection('groups')
        .doc(groupId);

    final snapshot = await actorGroupRef.get();

    if (!snapshot.exists) {
      throw Exception('Nhóm không tồn tại');
    }

    final data = snapshot.data() ?? {};
    final ownerUid = (data['ownerUid'] ?? '').toString();

    final actorIsOwner = actorUid == ownerUid;

    if (!actorIsOwner && actorUid != memberUid) {
      throw Exception('Bạn chỉ có thể thêm tiền cho chính mình');
    }

    final memberIds =
        (data['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

    if (!memberIds.contains(memberUid)) {
      throw Exception('Thành viên không thuộc nhóm này');
    }

    final oldContributions = Map<String, dynamic>.from(
      data['memberContributions'] ?? {},
    );

    final currentMemberAmount = oldContributions[memberUid] is num
        ? (oldContributions[memberUid] as num).toDouble()
        : 0.0;

    oldContributions[memberUid] = currentMemberAmount + amount;

    final currentAmount = data['currentAmount'] is num
        ? (data['currentAmount'] as num).toDouble()
        : 0.0;

    final updatedData = {
      ...data,
      'currentAmount': currentAmount + amount,
      'memberContributions': oldContributions,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();

    for (final uid in memberIds) {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(groupId);

      batch.set(ref, updatedData, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Stream<List<String>> streamFriendIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => (doc.data()['uid'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }

  Future<void> markUserAsDeleted(String uid) async {
    await _db.collection('users').doc(uid).set(
      {
        'uid': uid,
        'name': 'Tài khoản đã xoá',
        'username': 'deleted_user',
        'email': '',
        'avatarUrl': '',
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}