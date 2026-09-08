import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/currency_formatter.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../models/user_model.dart';
import 'chat_repository.dart';

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

  Future<bool> isFriendWith(String myUid, String targetUid) async {
    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(targetUid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('isFriendWith check error: $e');
      return false;
    }
  }

  Stream<bool> streamIsFriend(String myUid, String targetUid) {
    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) {
      return Stream.value(false);
    }
    return _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<bool> hasSentFriendRequestTo(String myUid, String targetUid) async {
    if (myUid.isEmpty || targetUid.isEmpty || myUid == targetUid) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(myUid)
          .collection('sent_friend_requests')
          .doc(targetUid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('hasSentFriendRequestTo check error: $e');
      return false;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('isUsernameTaken check error: $e');
      return false;
    }
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

  Future<bool> areFriends(String uidA, String uidB) async {
    if (uidA == uidB) return true;
    try {
      final friendDoc = await _db
          .collection('users')
          .doc(uidA)
          .collection('friends')
          .doc(uidB)
          .get();
      return friendDoc.exists;
    } catch (_) {
      return false;
    }
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

  Future<AddFriendConnectionState> checkConnectionState(
    String myUid,
    String targetUid,
  ) =>
      getAddFriendConnectionState(myUid: myUid, targetUid: targetUid);

  Future<void> updateUserPresence(String uid, {required bool isOnline}) async {
    if (uid.isEmpty) return;
    try {
      if (isOnline) {
        final profile = await getUserProfile(uid);
        if (profile != null && !profile.showActiveStatus) {
          await _db.collection('users').doc(uid).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
          return;
        }
      }
      await _db.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user presence: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamFriends(String uid) {
    if (uid.trim().isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final docs = snapshot.docs;

        final items = await Future.wait(
          docs.map((doc) async {
            try {
              final data = doc.data();
              final rawUid = (data['uid'] ?? '').toString().trim();
              final friendUid = rawUid.isNotEmpty ? rawUid : doc.id;
              if (friendUid.isEmpty) return null;

              final savedUsername = (data['username'] ?? '').toString();
              final savedName = (data['name'] ?? '').toString();
              final savedAvatarUrl = (data['avatarUrl'] ?? '').toString();
              final savedAvatarFrame = (data['avatarFrame'] ?? 'plain').toString();

              final profile = await getUserProfile(friendUid);

              final isDeleted = profile?.isDeleted == true;
              if (isDeleted) {
                return null;
              }

              final isOnline = profile?.isCurrentlyOnline ?? false;
              final showActiveStatus = profile?.showActiveStatus ?? true;

              return {
                'uid': friendUid,
                'username': profile?.username.isNotEmpty == true
                    ? profile!.username
                    : (savedUsername.isNotEmpty ? savedUsername : friendUid),
                'name': profile?.name.isNotEmpty == true
                    ? profile!.name
                    : (savedName.isNotEmpty ? savedName : 'Người dùng'),
                'avatarUrl': profile?.avatarUrl ?? savedAvatarUrl,
                'avatarFrame': profile?.avatarFrame ?? savedAvatarFrame,
                'isCloseFriend': data['isCloseFriend'] == true,
                'isDeleted': false,
                'isOnline': isOnline,
                'showActiveStatus': showActiveStatus,
                'userNote': profile?.userNote,
                'userNoteCreatedAt': profile?.userNoteCreatedAt,
                'hasActiveNote': profile?.hasActiveNote ?? false,
                'addedAt': data['addedAt'],
              };
            } catch (e) {
              debugPrint('Error processing friend item: $e');
              return null;
            }
          }),
        );

        final validItems = items.whereType<Map<String, dynamic>>().toList();

        validItems.sort((a, b) {
          final aTime = a['addedAt'];
          final bTime = b['addedAt'];

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          DateTime? aDt = aTime is Timestamp
              ? aTime.toDate()
              : (aTime is DateTime ? aTime : null);
          DateTime? bDt = bTime is Timestamp
              ? bTime.toDate()
              : (bTime is DateTime ? bTime : null);

          if (aDt == null && bDt == null) return 0;
          if (aDt == null) return 1;
          if (bDt == null) return -1;

          return bDt.compareTo(aDt);
        });

        return validItems;
      } catch (e) {
        debugPrint('Error in streamFriends asyncMap: $e');
        return [];
      }
    });
  }

  /// Lắng nghe danh sách bạn bè kết hợp với trạng thái realtime (online/offline/note) của từng bạn bè.
  /// Bất cứ khi nào bạn bè mở app, tắt app, hoặc cập nhật ghi chú, stream sẽ emit ngay lập tức.
  Stream<List<Map<String, dynamic>>> streamActiveFriendsRealtime(String uid) {
    if (uid.trim().isEmpty) return Stream.value([]);

    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription? friendsSub;
    final Map<String, StreamSubscription> userSubs = {};
    final Map<String, Map<String, dynamic>> friendsData = {};
    final Map<String, UserModel?> latestProfiles = {};

    void emitLatest() {
      if (controller.isClosed) return;
      try {
        final List<Map<String, dynamic>> items = [];
        for (final entry in friendsData.entries) {
          final friendUid = entry.key;
          final friendDoc = entry.value;
          final profile = latestProfiles[friendUid];

          if (profile?.isDeleted == true) continue;

          final savedUsername = (friendDoc['username'] ?? '').toString();
          final savedName = (friendDoc['name'] ?? '').toString();
          final savedAvatarUrl = (friendDoc['avatarUrl'] ?? '').toString();
          final savedAvatarFrame =
              (friendDoc['avatarFrame'] ?? 'plain').toString();

          final isOnline = profile?.isCurrentlyOnline ?? false;
          final showActiveStatus = profile?.showActiveStatus ?? true;

          items.add({
            'uid': friendUid,
            'username': profile?.username.isNotEmpty == true
                ? profile!.username
                : (savedUsername.isNotEmpty ? savedUsername : friendUid),
            'name': profile?.name.isNotEmpty == true
                ? profile!.name
                : (savedName.isNotEmpty ? savedName : 'Người dùng'),
            'email': profile?.email ?? (friendDoc['email'] ?? ''),
            'avatarUrl': profile?.avatarUrl ?? savedAvatarUrl,
            'avatarFrame': profile?.avatarFrame ?? savedAvatarFrame,
            'isCloseFriend': friendDoc['isCloseFriend'] == true,
            'isDeleted': false,
            'isOnline': isOnline,
            'showActiveStatus': showActiveStatus,
            'activeStatusMode': profile?.activeStatusMode ?? 'friends',
            'lastSeen': profile?.lastSeen,
            'lastActiveDate': profile?.lastActiveDate,
            'userNote': profile?.userNote,
            'userNoteCreatedAt': profile?.userNoteCreatedAt,
            'hasActiveNote': profile?.hasActiveNote ?? false,
            'addedAt': friendDoc['addedAt'],
            'chatBubbleTheme': profile?.chatBubbleTheme ?? 'default',
            'themeMode': profile?.themeMode ?? 'system',
          });
        }

        items.sort((a, b) {
          final aTime = a['addedAt'];
          final bTime = b['addedAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          DateTime? aDt = aTime is Timestamp
              ? aTime.toDate()
              : (aTime is DateTime ? aTime : null);
          DateTime? bDt = bTime is Timestamp
              ? bTime.toDate()
              : (bTime is DateTime ? bTime : null);
          if (aDt == null && bDt == null) return 0;
          if (aDt == null) return 1;
          if (bDt == null) return -1;
          return bDt.compareTo(aDt);
        });

        if (!controller.isClosed) {
          controller.add(items);
        }
      } catch (e) {
        debugPrint('Error emitting in streamActiveFriendsRealtime: $e');
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        friendsSub = _db
            .collection('users')
            .doc(uid)
            .collection('friends')
            .snapshots()
            .listen((snapshot) {
          final currentUids = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawUid = (data['uid'] ?? '').toString().trim();
            final friendUid = rawUid.isNotEmpty ? rawUid : doc.id;
            if (friendUid.isEmpty) continue;

            currentUids.add(friendUid);
            friendsData[friendUid] = data;

            if (!userSubs.containsKey(friendUid)) {
              userSubs[friendUid] =
                  _remote.streamUserProfile(friendUid).listen((profile) {
                latestProfiles[friendUid] = profile;
                emitLatest();
              }, onError: (e) {
                debugPrint('Error in streamUserProfile for $friendUid: $e');
              });
            }
          }

          // Cancel subscriptions for removed friends
          final removedUids =
              userSubs.keys.where((fUid) => !currentUids.contains(fUid)).toList();
          for (final fUid in removedUids) {
            userSubs[fUid]?.cancel();
            userSubs.remove(fUid);
            friendsData.remove(fUid);
            latestProfiles.remove(fUid);
          }

          emitLatest();
        }, onError: (e) {
          debugPrint('Error in streamActiveFriendsRealtime friendsSub: $e');
          if (!controller.isClosed) controller.addError(e);
        });
      },
      onCancel: () {
        friendsSub?.cancel();
        friendsSub = null;
        for (final sub in userSubs.values) {
          sub.cancel();
        }
        userSubs.clear();
        friendsData.clear();
        latestProfiles.clear();
      },
    );

    return controller.stream;
  }

  Future<void> updateUserNote(String uid, String noteText) async {
    if (uid.isEmpty) return;
    final trimmed = noteText.trim();
    if (trimmed.isEmpty) {
      await deleteUserNote(uid);
      return;
    }
    await _db.collection('users').doc(uid).update({
      'userNote': trimmed,
      'userNoteCreatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserNote(String uid) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).update({
      'userNote': FieldValue.delete(),
      'userNoteCreatedAt': FieldValue.delete(),
    });
  }

  Future<void> toggleCloseFriend({
    required String myUid,
    required String friendUid,
    required bool isCloseFriend,
  }) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(friendUid)
        .set({
      'isCloseFriend': isCloseFriend,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserChatBubbleTheme({
    required String uid,
    required String themeId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'chatBubbleTheme': themeId,
    }, SetOptions(merge: true));
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
      'name': userB.name,
      'username': userB.username,
      'avatarUrl': userB.avatarUrl,
      'avatarFrame': userB.avatarFrame,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(bFriendRef, {
      'uid': userA.uid,
      'name': userA.name,
      'username': userA.username,
      'avatarUrl': userA.avatarUrl,
      'avatarFrame': userA.avatarFrame,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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

    final addedMembers = newMemberIds.difference(oldMemberIds);
    final updater = await getUserProfile(myUid);
    final updaterName = (updater?.name.isNotEmpty == true)
        ? updater!.name
        : (updater?.username.isNotEmpty == true ? '@${updater!.username}' : 'Thành viên');

    for (final uid in addedMembers) {
      final notifDoc = _db.collection('users').doc(uid).collection('notifications').doc();
      batch.set(notifDoc, {
        'id': notifDoc.id,
        'type': 'group_invite',
        'title': 'Nhóm chi tiêu',
        'body': '$updaterName đã thêm bạn vào nhóm "$trimmedName"',
        'groupId': groupId,
        'groupName': trimmedName,
        'senderUid': myUid,
        'senderName': updaterName,
        'senderAvatar': updater?.avatarUrl ?? '',
        'senderAvatarFrame': updater?.avatarFrame ?? 'plain',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();

    try {
      await ChatRepository().updateGroupChatMetadata(
        groupId: groupId,
        groupName: trimmedName,
        groupColor: colorHex,
        participants: newMemberIds.toList(),
      );

      for (final addedUid in addedMembers) {
        final memberProfile = await getUserProfile(addedUid);
        final memberName = memberProfile?.name.isNotEmpty == true
            ? memberProfile!.name
            : (memberProfile?.username.isNotEmpty == true ? '@${memberProfile!.username}' : 'Thành viên');
        await ChatRepository().sendGroupSystemMessage(
          groupId: groupId,
          systemText: '$updaterName đã thêm $memberName vào nhóm',
          actorUid: myUid,
        );
      }

      for (final removedUid in removedMembers) {
        final memberProfile = await getUserProfile(removedUid);
        final memberName = memberProfile?.name.isNotEmpty == true
            ? memberProfile!.name
            : (memberProfile?.username.isNotEmpty == true ? '@${memberProfile!.username}' : 'Thành viên');
        await ChatRepository().sendGroupSystemMessage(
          groupId: groupId,
          systemText: '$updaterName đã xoá $memberName khỏi nhóm',
          actorUid: myUid,
        );
      }
    } catch (_) {}
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

    try {
      final leaver = await getUserProfile(myUid);
      final leaverName = leaver?.name.isNotEmpty == true
          ? leaver!.name
          : (leaver?.username.isNotEmpty == true ? '@${leaver!.username}' : 'Thành viên');

      await ChatRepository().sendGroupSystemMessage(
        groupId: groupId,
        systemText: '$leaverName đã rời khỏi nhóm',
        actorUid: myUid,
      );

      await ChatRepository().updateGroupChatMetadata(
        groupId: groupId,
        participants: remainingMembers,
      );
    } catch (_) {}
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

    final creator = await getUserProfile(uid);
    final creatorName = (creator?.name.isNotEmpty == true)
        ? creator!.name
        : (creator?.username.isNotEmpty == true ? '@${creator!.username}' : 'Thành viên');

    for (final memberUid in memberIds) {
      if (memberUid == uid) continue;
      final notifDoc = _db.collection('users').doc(memberUid).collection('notifications').doc();
      batch.set(notifDoc, {
        'id': notifDoc.id,
        'type': 'group_invite',
        'title': 'Nhóm chi tiêu',
        'body': '$creatorName đã thêm bạn vào nhóm "$trimmedName"',
        'groupId': doc.id,
        'groupName': trimmedName,
        'senderUid': uid,
        'senderName': creatorName,
        'senderAvatar': creator?.avatarUrl ?? '',
        'senderAvatarFrame': creator?.avatarFrame ?? 'plain',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();

    try {
      final initialSystemMessage = '$creatorName đã tạo nhóm "$trimmedName"';
      await ChatRepository().createGroupChat(
        groupId: doc.id,
        groupName: trimmedName,
        groupColor: colorHex,
        ownerUid: uid,
        memberUids: uniqueMemberIds,
        initialSystemMessage: initialSystemMessage,
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchUserGroups(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((e) => e.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addGroupContribution({
    required String groupId,
    required String actorUid,
    required String memberUid,
    required double amount,
    bool sendSystemMessage = true,
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

    if (sendSystemMessage) {
      try {
        final actor = await getUserProfile(actorUid);
        final member = actorUid == memberUid ? actor : await getUserProfile(memberUid);
        final actorName = actor?.name.isNotEmpty == true
            ? actor!.name
            : (actor?.username.isNotEmpty == true ? '@${actor!.username}' : 'Thành viên');
        final memberName = member?.name.isNotEmpty == true
            ? member!.name
            : (member?.username.isNotEmpty == true ? '@${member!.username}' : 'Thành viên');
        final moneyStr = AppCurrencyFormatter.formatFromVnd(
          amountVnd: amount,
          currency: 'VND',
        );

        final systemText = actorUid == memberUid
            ? '$actorName đã đóng góp $moneyStr vào quỹ nhóm'
            : '$actorName đã đóng góp $moneyStr cho $memberName trong nhóm';

        await ChatRepository().sendGroupSystemMessage(
          groupId: groupId,
          systemText: systemText,
          actorUid: actorUid,
        );
      } catch (_) {}
    }
  }

  /// Ghi nhận khoản chi tiêu từ quỹ nhóm khi thành viên tạo giao dịch nhóm
  Future<void> addGroupExpense({
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
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final memberIds =
        (data['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final oldSpentMap = Map<String, dynamic>.from(
      data['memberSpent'] ?? {},
    );

    final currentMemberSpent = oldSpentMap[memberUid] is num
        ? (oldSpentMap[memberUid] as num).toDouble()
        : 0.0;

    oldSpentMap[memberUid] = currentMemberSpent + amount;

    final currentSpent = data['spentAmount'] is num
        ? (data['spentAmount'] as num).toDouble()
        : 0.0;

    final updatedData = {
      ...data,
      'spentAmount': currentSpent + amount,
      'memberSpent': oldSpentMap,
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
    return streamFriends(uid).map(
      (friends) => friends
          .map((f) => (f['uid'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }

  Stream<List<String>> streamCloseFriendIds(String uid) {
    return streamFriends(uid).map(
      (friends) => friends
          .where((f) => f['isCloseFriend'] == true)
          .map((f) => (f['uid'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }

  Future<List<String>> getCloseFriendUids(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .where('isCloseFriend', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['uid'] ?? doc.id).toString())
        .where((id) => id.isNotEmpty)
        .toList();
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