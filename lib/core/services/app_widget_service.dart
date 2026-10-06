import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../../data/models/user_model.dart';
import '../routes/app_routes.dart';
import '../routes/route_names.dart';
import '../widgets/app_widgets/calendar_app_widget_view.dart';
import '../widgets/app_widgets/moment_app_widget_view.dart';
import '../widgets/app_widgets/stats_app_widget_view.dart';

class AppWidgetService {
  AppWidgetService._();
  static final AppWidgetService instance = AppWidgetService._();

  static const MethodChannel _widgetChannel =
      MethodChannel('com.duyvinh09.memeapp/widget_click');

  StreamSubscription<Uri?>? _homeWidgetSub;
  String? _pendingWidgetTarget;
  bool _isUpdating = false;
  bool _hasPendingUpdate = false;

  static const List<Color> _categoryColors = [
    Color(0xFFFF5B5B), // Red
    Color(0xFFFFC857), // Yellow
    Color(0xFF7DDC86), // Green
    Color(0xFF79AFFF), // Blue
    Color(0xFFB68CFF), // Purple
    Color(0xFF59D4C8), // Teal
    Color(0xFFFFA45B), // Orange
    Color(0xFF8E8E93), // Gray / Khác
  ];

  String? consumePendingWidgetTarget() {
    final target = _pendingWidgetTarget;
    _pendingWidgetTarget = null;
    return target;
  }

  /// Initialize deep linking & initial launch handler
  Future<void> init() async {
    // 1. Listen for native Android MethodChannel events
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetClick') {
        final uriStr = call.arguments as String?;
        if (uriStr != null) {
          _handleUriString(uriStr);
        }
      }
    });

    // 2. Query initial URL if cold started
    try {
      final initialUrl =
          await _widgetChannel.invokeMethod<String>('getInitialUrl');
      if (initialUrl != null && initialUrl.isNotEmpty) {
        _handleUriString(initialUrl);
      }
    } catch (e) {
      debugPrint('[AppWidgetService] Error getting initial URL: $e');
    }

    // 3. Also check HomeWidget plugin channels as fallback
    try {
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      _homeWidgetSub?.cancel();
      _homeWidgetSub = HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null) {
          _handleUri(uri);
        }
      });
    } catch (e) {
      debugPrint('[AppWidgetService] Error listening to HomeWidget: $e');
    }
  }

  void _handleUriString(String uriStr) {
    final uri = Uri.tryParse(uriStr);
    if (uri != null) {
      _handleUri(uri);
    }
  }

  void _handleUri(Uri uri) {
    debugPrint('[AppWidgetService] Handling widget URI: $uri');
    String? target;
    if (uri.host == 'stats' || uri.path.contains('stats')) {
      target = 'stats';
    } else if (uri.host == 'calendar' || uri.path.contains('calendar')) {
      target = 'calendar';
    } else if (uri.host == 'moment' ||
        uri.path.contains('moment') ||
        uri.host == 'home' ||
        uri.path.contains('home')) {
      target = 'home';
    }

    if (target == null) return;
    _navigateToTarget(target);
  }

  void _navigateToTarget(String target) {
    // If MainShell is already mounted on screen
    if (MainShell.mainShellKey.currentState != null) {
      final nav = AppRoutes.navigatorKey.currentState;
      if (nav != null) {
        nav.popUntil((route) => route.isFirst);
      }

      if (target == 'stats') {
        MainShell.switchTab(1);
      } else if (target == 'calendar') {
        MainShell.switchTab(0);
        nav?.pushNamed(RouteNames.calendar);
      } else if (target == 'home') {
        MainShell.switchTab(0);
      }
    } else {
      // MainShell not mounted yet (app is in splash/preloader)
      _pendingWidgetTarget = target;
    }
  }

  /// Compact number formatter (e.g. 7.4Mđ, 150Kđ, 500đ)
  String _formatCompactVnd(double amount) {
    if (amount <= 0) return '0đ';
    if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}Bđ';
    }
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val.toStringAsFixed(1).replaceAll('.0', '')}Mđ';
    }
    if (amount >= 1000) {
      final val = amount / 1000;
      return '${val.toStringAsFixed(0)}Kđ';
    }
    return '${amount.toInt()}đ';
  }

  List<TransactionModel> _cachedTransactions = [];
  List<TransactionModel> _cachedFeedTransactions = [];
  UserModel? _cachedProfile;

  /// Localize default categories to EN or VI
  static String localizeCategory(String rawCategory, {required bool isEn}) {
    final trimmed = rawCategory.trim();
    if (trimmed.isEmpty) return isEn ? 'Other' : 'Khác';

    if (isEn) {
      switch (trimmed) {
        case 'Ăn uống':
        case 'Food':
          return 'Food';
        case 'Mua sắm':
        case 'Shopping':
          return 'Shopping';
        case 'Đi lại':
        case 'Di chuyển':
        case 'Transport':
          return 'Transport';
        case 'Giải trí':
        case 'Entertainment':
          return 'Entertainment';
        case 'Học tập':
        case 'Giáo dục':
        case 'Education':
          return 'Education';
        case 'Lương':
        case 'Salary':
          return 'Salary';
        case 'Quà tặng':
        case 'Gift':
          return 'Gift';
        case 'Khác':
        case 'Other':
          return 'Other';
        case 'Quỹ nhóm':
        case 'Group Fund':
          return 'Group Fund';
        default:
          return trimmed;
      }
    } else {
      switch (trimmed) {
        case 'Food':
        case 'Ăn uống':
          return 'Ăn uống';
        case 'Shopping':
        case 'Mua sắm':
          return 'Mua sắm';
        case 'Transport':
        case 'Đi lại':
        case 'Di chuyển':
          return 'Di chuyển';
        case 'Entertainment':
        case 'Giải trí':
          return 'Giải trí';
        case 'Education':
        case 'Học tập':
        case 'Giáo dục':
          return 'Giáo dục';
        case 'Salary':
        case 'Lương':
          return 'Lương';
        case 'Gift':
        case 'Quà tặng':
          return 'Quà tặng';
        case 'Other':
        case 'Khác':
          return 'Khác';
        case 'Group Fund':
        case 'Quỹ nhóm':
          return 'Quỹ nhóm';
        default:
          return trimmed;
      }
    }
  }

  Future<ui.Image?> _decodeImage(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  /// Update Stats, Calendar, and 2x2 Moment home widgets
  Future<void> updateWidgets({
    List<TransactionModel>? transactions,
    List<TransactionModel>? feedTransactions,
    UserModel? profile,
    String? currency,
  }) async {
    if (transactions != null) {
      _cachedTransactions = transactions;
    }
    if (feedTransactions != null) {
      _cachedFeedTransactions = feedTransactions;
    }
    if (profile != null) {
      _cachedProfile = profile;
    }

    if (_isUpdating) {
      _hasPendingUpdate = true;
      return;
    }
    _isUpdating = true;

    try {
      do {
        _hasPendingUpdate = false;
        await _performUpdate(currency: currency);
      } while (_hasPendingUpdate);
    } catch (e, stack) {
      debugPrint('[AppWidgetService] Error in updateWidgets loop: $e\n$stack');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _performUpdate({String? currency}) async {
    final currentTxs = _cachedTransactions;
    final currentProfile = _cachedProfile;

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      final isEn = currentProfile?.language == 'en';
      final statsMonthLabel = isEn ? 'This Month' : 'Tháng này';
      final calendarMonthLabel = isEn
          ? DateFormat('MMMM yyyy', 'en_US').format(now)
          : 'Tháng $currentMonth $currentYear';

      // 1. Filter transactions for current month
      final thisMonthTxs = currentTxs.where((tx) {
        return tx.createdAt.year == currentYear &&
            tx.createdAt.month == currentMonth;
      }).toList();

      // 2. Filter transactions for previous month (for comparison)
      final prevMonthDate = DateTime(currentYear, currentMonth - 1);
      final prevMonthTxs = currentTxs.where((tx) {
        return tx.createdAt.year == prevMonthDate.year &&
            tx.createdAt.month == prevMonthDate.month;
      }).toList();

      // Calculate Expenses & Incomes
      final double totalExpense = thisMonthTxs
          .where((e) => (e.type == 'expense' && !e.isGroupExpense) || e.isGroupContribution)
          .fold(0.0, (sum, e) => sum + e.amount);

      final double totalIncome = thisMonthTxs
          .where((e) => e.type == 'income' && !e.isGroupContribution)
          .fold(0.0, (sum, e) => sum + e.amount);

      final double prevTotalExpense = prevMonthTxs
          .where((e) => (e.type == 'expense' && !e.isGroupExpense) || e.isGroupContribution)
          .fold(0.0, (sum, e) => sum + e.amount);

      // 3. Category Breakdown for Donut Chart
      final Map<String, double> categoryMap = {};
      for (final tx in thisMonthTxs) {
        if ((tx.type == 'expense' && !tx.isGroupExpense) || tx.isGroupContribution) {
          final rawCat = tx.category.isNotEmpty ? tx.category : (isEn ? 'Other' : 'Khác');
          final localizedCat = localizeCategory(rawCat, isEn: isEn);
          categoryMap[localizedCat] = (categoryMap[localizedCat] ?? 0.0) + tx.amount;
        }
      }

      final sortedCategories = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<CategoryShare> categoryShares = [];
      for (int i = 0; i < sortedCategories.length; i++) {
        final entry = sortedCategories[i];
        final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
        final color = _categoryColors[i % _categoryColors.length];
        categoryShares.add(
          CategoryShare(
            name: entry.key,
            amount: entry.value,
            percentage: pct,
            color: color,
          ),
        );
      }

      bool isDark = true;
      if (currentProfile != null) {
        if (currentProfile.themeMode == 'light') {
          isDark = false;
        } else if (currentProfile.themeMode == 'dark') {
          isDark = true;
        } else {
          final brightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          isDark = brightness == Brightness.dark;
        }
      }

      final statsData = StatsWidgetData(
        totalExpense: totalExpense,
        previousMonthExpense: prevTotalExpense > 0 ? prevTotalExpense : null,
        categories: categoryShares,
        currency: currency ?? currentProfile?.currency ?? 'VND',
        monthLabel: statsMonthLabel,
        noExpenseLabel: isEn ? 'No spending yet' : 'Chưa có chi tiêu',
        isDark: isDark,
        isEn: isEn,
      );

      // 4. Calendar Thumbnails & Spending Days
      final Map<int, Uint8List> dayThumbnails = {};
      final Set<int> daysWithSpending = {};

      // Map days of this month to their latest moment photo
      final Map<int, String> dayImageUrls = {};
      for (final tx in thisMonthTxs) {
        final day = tx.createdAt.day;
        daysWithSpending.add(day);
        final url = tx.thumbnailUrl.isNotEmpty
            ? tx.thumbnailUrl
            : (tx.imageUrl.isNotEmpty ? tx.imageUrl : tx.mediaUrl);
        if (url.isNotEmpty && !dayImageUrls.containsKey(day)) {
          dayImageUrls[day] = url;
        }
      }

      // Pre-fetch thumbnails (limit to 31 max)
      for (final entry in dayImageUrls.entries) {
        final bytes = await _loadImageBytes(entry.value);
        if (bytes != null) {
          dayThumbnails[entry.key] = bytes;
        }
      }

      final calendarData = CalendarWidgetData(
        monthLabel: calendarMonthLabel,
        streak: currentProfile?.currentStreak ?? 0,
        totalExpenseCompact: _formatCompactVnd(totalExpense),
        transactionCount: thisMonthTxs.length,
        totalIncomeCompact: _formatCompactVnd(totalIncome),
        year: currentYear,
        month: currentMonth,
        dayThumbnails: dayThumbnails,
        daysWithSpending: daysWithSpending,
        today: now.day,
        isDark: isDark,
        expenseLabel: isEn ? 'Expense' : 'Chi tiêu',
        txCountLabel: isEn ? 'Transactions' : 'Số giao dịch',
        incomeLabel: isEn ? 'Income' : 'Thu vào',
        weekdayLabels: isEn
            ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : const ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'],
      );

      // 5. 2x2 Moment Widget - Find latest transaction with photo
      final allAvailableTxs = <TransactionModel>[
        ...currentTxs,
        ..._cachedFeedTransactions,
      ];
      final seenIds = <String>{};
      final uniqueTxs = <TransactionModel>[];
      for (final tx in allAvailableTxs) {
        if (seenIds.add(tx.id)) {
          uniqueTxs.add(tx);
        }
      }
      uniqueTxs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      TransactionModel? latestTx = uniqueTxs.isNotEmpty ? uniqueTxs.first : null;
      Uint8List? latestMomentBytes;

      // Scan for the most recent transaction whose photo can be loaded
      for (final tx in uniqueTxs) {
        final imgUrl = tx.displayImageUrl.trim().isNotEmpty
            ? tx.displayImageUrl.trim()
            : (tx.thumbnailUrl.trim().isNotEmpty
                ? tx.thumbnailUrl.trim()
                : (tx.mediaUrl.trim().isNotEmpty
                    ? tx.mediaUrl.trim()
                    : tx.imageUrl.trim()));
        if (imgUrl.isNotEmpty) {
          final bytes = await _loadImageBytes(imgUrl);
          if (bytes != null && bytes.isNotEmpty) {
            latestMomentBytes = bytes;
            latestTx = tx;
            break;
          }
        }
      }

      // If still no transaction photo, fallback to user's profile avatar
      if (latestMomentBytes == null && currentProfile?.avatarUrl.isNotEmpty == true) {
        latestMomentBytes = await _loadImageBytes(currentProfile!.avatarUrl);
      }

      ui.Image? decodedMomentImage;
      if (latestMomentBytes != null && latestMomentBytes.isNotEmpty) {
        try {
          decodedMomentImage = await _decodeImage(latestMomentBytes);
        } catch (e) {
          debugPrint('[AppWidgetService] Error pre-decoding moment image: $e');
        }
      }

      final rawCat = latestTx?.category ?? '';
      final localizedCat =
          rawCat.isNotEmpty ? localizeCategory(rawCat, isEn: isEn) : '';

      final momentData = MomentWidgetData(
        streak: currentProfile?.currentStreak ?? 0,
        type: latestTx?.type ?? 'expense',
        amount: latestTx?.amount ?? 0.0,
        formattedAmount: latestTx != null
            ? _formatCompactVnd(latestTx.amount)
            : '0đ',
        caption: latestTx?.caption.isNotEmpty == true
            ? latestTx!.caption
            : (localizedCat.isNotEmpty
                ? localizedCat
                : (latestTx != null
                    ? (latestTx.type == 'expense'
                        ? (isEn ? 'New Expense' : 'Chi tiêu mới')
                        : (isEn ? 'New Income' : 'Thu nhập mới'))
                    : (isEn ? 'Tap to add spending 📸' : 'Chạm để thêm chi tiêu 📸'))),
        category: localizedCat,
        categoryIconCodePoint: latestTx?.categoryIconCodePoint,
        categoryColorHex: latestTx?.categoryColorHex,
        groupName: latestTx?.groupName,
        imageBytes: latestMomentBytes,
        decodedImage: decodedMomentImage,
        isVideo: latestTx?.isVideo ?? false,
        isDark: isDark,
        isEn: isEn,
        hasTransaction: latestTx != null,
        widgetFrame: currentProfile?.widgetFrame ?? 'none',
      );

      // 6. Render Flutter Widgets to Bitmaps
      await HomeWidget.renderFlutterWidget(
        StatsAppWidgetView(data: statsData),
        key: 'stats_widget_image',
        logicalSize: const Size(380, 180),
        pixelRatio: 2.5,
      );

      await HomeWidget.renderFlutterWidget(
        CalendarAppWidgetView(data: calendarData),
        key: 'calendar_widget_image',
        logicalSize: const Size(370, 380),
        pixelRatio: 2.5,
      );

      await HomeWidget.renderFlutterWidget(
        MomentAppWidgetView(data: momentData),
        key: 'moment_widget_image',
        logicalSize: const Size(220, 220),
        pixelRatio: 2.5,
      );

      // 7. Notify native Android AppWidget providers
      await HomeWidget.updateWidget(
        name: 'StatsWidgetProvider',
        androidName: 'StatsWidgetProvider',
      );

      await HomeWidget.updateWidget(
        name: 'CalendarWidgetProvider',
        androidName: 'CalendarWidgetProvider',
      );

      await HomeWidget.updateWidget(
        name: 'MomentWidgetProvider',
        androidName: 'MomentWidgetProvider',
      );

      debugPrint('[AppWidgetService] Successfully updated home widgets!');
    } catch (e, stack) {
      debugPrint('[AppWidgetService] Error updating home widgets: $e\n$stack');
    }
  }

  Future<Uint8List?> _loadImageBytes(String pathOrUrl) async {
    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) return null;
    try {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        try {
          // 1. Check local cache first for instant 0ms access
          final cacheInfo = await DefaultCacheManager().getFileFromCache(trimmed);
          if (cacheInfo != null && await cacheInfo.file.exists()) {
            final bytes = await cacheInfo.file.readAsBytes();
            if (bytes.isNotEmpty) return bytes;
          }

          // 2. Fetch via Cache Manager with timeout
          final file = await DefaultCacheManager().getSingleFile(trimmed).timeout(
            const Duration(seconds: 6),
          );
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        } catch (_) {
          // 3. Fallback direct HTTP
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 6);
          final request = await client.getUrl(Uri.parse(trimmed));
          final response = await request.close().timeout(const Duration(seconds: 6));
          if (response.statusCode == 200) {
            final bytes = await consolidateHttpClientResponseBytes(response);
            if (bytes.isNotEmpty) return bytes;
          }
        }
      } else {
        final localPath = trimmed.startsWith('file://')
            ? Uri.parse(trimmed).toFilePath()
            : trimmed;
        final file = File(localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      }
    } catch (e) {
      debugPrint('[AppWidgetService] Error loading image bytes: $e');
    }
    return null;
  }

  void dispose() {
    _homeWidgetSub?.cancel();
  }
}
