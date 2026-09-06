import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';

class FeedController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final UserRepository userRepository;

  FeedController({
    required this.transactionRepository,
    required this.userRepository,
  });

  List<TransactionModel> feedTransactions = [];
  bool isLoading = false;
  String? errorMessage;
  String? targetPostId;

  Future<void> setTargetPostId(String? postId) async {
    targetPostId = postId;
    if (postId != null && postId.isNotEmpty) {
      final exists = feedTransactions.any((tx) => tx.id == postId);
      if (!exists) {
        final tx = await transactionRepository.fetchTransactionById(postId);
        if (tx != null) {
          final alreadyIn = feedTransactions.any((t) => t.id == tx.id);
          if (!alreadyIn) {
            feedTransactions.insert(0, tx);
          }
        }
      }
    }
    notifyListeners();
  }

  StreamSubscription<List<String>>? _friendSub;
  Timer? _pollingTimer;

  String? _currentUid;
  List<String> _currentFriendIds = [];

  Future<void> load(String uid) async {
    _currentUid = uid;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _friendSub?.cancel();
    _pollingTimer?.cancel();

    _friendSub = userRepository.streamFriendIds(uid).listen(
      (friendIds) async {
        _currentFriendIds = friendIds;
        await _fetchFeed(uid: uid, friendIds: friendIds);
      },
      onError: (e) {
        debugPrint('Friend stream error: $e');
        feedTransactions = [];
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      },
    );

    // Periodically fetch new feed updates in background
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_currentUid != null && !isLoading) {
        _fetchFeed(
          uid: _currentUid!,
          friendIds: _currentFriendIds,
          showLoading: false,
        );
      }
    });
  }

  Future<void> refresh() async {
    final uid = _currentUid;
    if (uid == null) return;

    await _fetchFeed(
      uid: uid,
      friendIds: _currentFriendIds,
      showLoading: false,
    );
  }

  Future<void> _fetchFeed({
    required String uid,
    required List<String> friendIds,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        isLoading = true;
        errorMessage = null;
        notifyListeners();
      }

      final allIds = <String>{uid, ...friendIds}.toList();

      final data = await transactionRepository.fetchFeedPosts(
        viewerUid: uid,
        userIds: allIds,
      );

      feedTransactions = data;
      isLoading = false;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Feed load error: $e');
      feedTransactions = [];
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void addNewTransaction(TransactionModel transaction) {
    final uid = _currentUid;
    if (uid == null) return;

    final alreadyExists = feedTransactions.any((tx) => tx.id == transaction.id);
    if (alreadyExists) return;

    final isMine = transaction.userId == uid;

    final shouldShow = isMine ||
        (transaction.sharedToFeed == true &&
            (transaction.privacy == 'friends' ||
                transaction.privacy == 'close_friends' ||
                transaction.privacy == 'everyone'));

    if (!shouldShow) return;

    feedTransactions.insert(0, transaction);

    feedTransactions.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    notifyListeners();
  }

  void removeDeletedTransaction(String transactionId) {
    feedTransactions.removeWhere((tx) => tx.id == transactionId);
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _friendSub?.cancel();
    super.dispose();
  }
}