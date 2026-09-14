import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/services/expense_parser.dart';
import '../../../core/services/voice_input_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../home/widgets/streak_milestone_dialog.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/capture_controller.dart';

class VoiceExpenseEditResult {
  final ParsedExpenseResult parsed;
  final String audience; // 'private', 'friends', 'close_friends', 'group', or 'friends_custom'
  final Set<String> selectedFriendUids;
  final String? selectedGroupId;
  final String? selectedGroupName;
  final List<String> selectedGroupMemberIds;

  const VoiceExpenseEditResult({
    required this.parsed,
    required this.audience,
    this.selectedFriendUids = const {},
    this.selectedGroupId,
    this.selectedGroupName,
    this.selectedGroupMemberIds = const [],
  });
}

class QuickVoiceExpenseSheet extends StatefulWidget {
  const QuickVoiceExpenseSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const QuickVoiceExpenseSheet(),
    );
  }

  @override
  State<QuickVoiceExpenseSheet> createState() => _QuickVoiceExpenseSheetState();
}

class _QuickVoiceExpenseSheetState extends State<QuickVoiceExpenseSheet>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService.instance;

  String _transcript = '';
  ParsedExpenseResult? _parsedResult;
  VoiceInputStatus _voiceStatus = VoiceInputStatus.idle;
  double _soundLevel = 0.0;
  double _targetSoundLevel = 0.0;
  double _smoothedSoundLevel = 0.0;
  String? _errorMessage;
  String _selectedSpeechLanguage = 'vi'; // 'vi' or 'en'

  // Audience & Privacy State
  String _selectedAudience = 'friends'; // 'private', 'friends', 'close_friends', 'group', 'friends_custom'
  final Set<String> _selectedFriendUids = {};
  String? _selectedGroupId;
  String? _selectedGroupName;
  List<String> _selectedGroupMemberIds = [];

  List<Map<String, dynamic>> _friends = [];
  List<String> _closeFriendUids = [];
  List<Map<String, dynamic>> _userGroups = [];

  StreamSubscription<List<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<List<String>>? _closeFriendsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _groupsSub;

  bool _isSaving = false;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  final List<double> _barHeights = [8, 14, 20, 26, 20, 14, 8];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _waveController.addListener(() {
      if (!mounted) return;
      if (_voiceStatus == VoiceInputStatus.listening) {
        // Fast attack, smooth decay EMA filter for voice sensitivity
        final decay = _targetSoundLevel > _smoothedSoundLevel ? 0.45 : 0.18;
        _smoothedSoundLevel += (_targetSoundLevel - _smoothedSoundLevel) * decay;

        setState(() {
          final t = _waveController.value;
          final s = _smoothedSoundLevel; // 0.0 to 1.0 based on real mic volume

          // 7 Waveform bars: dynamically react to real audio level + harmonic frequency
          _barHeights[0] = (5.0 + 14.0 * s + 5.0 * math.sin(t * 2 * math.pi + 0.0).abs()).clamp(5.0, 30.0);
          _barHeights[1] = (7.0 + 18.0 * s + 7.0 * math.sin(t * 2 * math.pi + 1.1).abs()).clamp(5.0, 30.0);
          _barHeights[2] = (9.0 + 22.0 * s + 9.0 * math.sin(t * 2 * math.pi + 2.2).abs()).clamp(5.0, 32.0);
          _barHeights[3] = (11.0 + 26.0 * s + 11.0 * math.sin(t * 2 * math.pi + 3.3).abs()).clamp(6.0, 34.0); // Center peak
          _barHeights[4] = (9.0 + 22.0 * s + 9.0 * math.sin(t * 2 * math.pi + 4.4).abs()).clamp(5.0, 32.0);
          _barHeights[5] = (7.0 + 18.0 * s + 7.0 * math.sin(t * 2 * math.pi + 5.5).abs()).clamp(5.0, 30.0);
          _barHeights[6] = (5.0 + 14.0 * s + 5.0 * math.sin(t * 2 * math.pi + 6.6).abs()).clamp(5.0, 30.0);
        });
      } else {
        if (_smoothedSoundLevel > 0.01) {
          setState(() {
            _smoothedSoundLevel = 0.0;
            for (int i = 0; i < _barHeights.length; i++) {
              _barHeights[i] = 6.0;
            }
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appLang = context.read<ProfileController>().languageCode;
      _selectedSpeechLanguage = appLang == 'en' ? 'en' : 'vi';
      _startVoiceListening();
      _initAudienceStreams();
    });
  }

  void _initAudienceStreams() {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null || uid.isEmpty) return;
    final userRepo = context.read<UserRepository>();

    _friendsSub = userRepo.streamFriends(uid).listen((friendsList) {
      if (mounted) {
        setState(() {
          _friends = friendsList;
        });
      }
    });

    _closeFriendsSub = userRepo.streamCloseFriendIds(uid).listen((ids) {
      if (mounted) {
        setState(() {
          _closeFriendUids = ids;
          if (_closeFriendUids.isEmpty && _selectedAudience == 'close_friends') {
            _selectedAudience = 'friends';
          }
        });
      }
    });

    _groupsSub = userRepo.streamGroups(uid).listen((groupsList) {
      if (mounted) {
        setState(() {
          _userGroups = groupsList;
        });
      }
    });
  }

  Future<void> _startVoiceListening({bool clearExisting = false}) async {
    setState(() {
      if (clearExisting) {
        _transcript = '';
        _parsedResult = null;
      }
      _errorMessage = null;
    });

    final defaultCurrency = context.read<ProfileController>().currency;
    final locale = _selectedSpeechLanguage == 'en' ? 'en_US' : 'vi_VN';

    final success = await _voiceService.startListening(
      localeId: locale,
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcript = words;
          if (words.trim().isNotEmpty) {
            _parsedResult = ExpenseParser.parse(
              words,
              defaultCurrency: defaultCurrency,
            );
          }
        });
      },
      onSoundLevel: (level) {
        if (!mounted) return;
        _soundLevel = level;
        // Normalize sound level from Android/iOS dB to 0.0 - 1.0 range
        double norm;
        if (level < 0) {
          if (level < -10) {
            norm = ((level + 55) / 45).clamp(0.0, 1.0);
          } else {
            norm = ((level + 2) / 10).clamp(0.0, 1.0);
          }
        } else {
          norm = (level / 8.5).clamp(0.0, 1.0);
        }
        _targetSoundLevel = norm;
      },
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          _voiceStatus = status;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _voiceStatus = VoiceInputStatus.error;
        });
      },
    );

    if (!success && mounted) {
      final isEnUI = context.read<ProfileController>().languageCode == 'en';
      setState(() {
        _errorMessage = isEnUI
            ? 'Unable to start recording. Please check microphone permission.'
            : 'Không thể bắt đầu ghi âm. Vui lòng kiểm tra quyền microphone.';
      });
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.selectionClick();
    if (_voiceStatus == VoiceInputStatus.listening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() {
          _voiceStatus = VoiceInputStatus.stopped;
        });
      }
    } else {
      // User tapped mic: clear old voice and auto-filled data for clean new voice input
      await _startVoiceListening(clearExisting: true);
    }
  }

  Future<void> _switchSpeechLanguage(String lang) async {
    if (_selectedSpeechLanguage == lang) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSpeechLanguage = lang;
      _errorMessage = null;
      _transcript = '';
      _parsedResult = null;
    });
    await _voiceService.cancelListening();
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _startVoiceListening(clearExisting: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _voiceService.stopListening();
    _friendsSub?.cancel();
    _closeFriendsSub?.cancel();
    _groupsSub?.cancel();
    super.dispose();
  }

  String _formatDisplayMoney(double amount, String currency) {
    if (currency == 'USD') {
      final formattedUsd = '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
      final convertedVnd = AppCurrencyFormatter.toVnd(inputAmount: amount, currency: 'USD');
      final vndStr = AppCurrencyFormatter.formatFromVnd(amountVnd: convertedVnd, currency: 'VND');
      return '$formattedUsd (≈ $vndStr)';
    }
    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: amount,
      currency: 'VND',
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Đi lại':
        return Icons.directions_bus_rounded;
      case 'Giải trí':
        return Icons.movie_rounded;
      case 'Học tập':
        return Icons.menu_book_rounded;
      case 'Lương':
        return Icons.payments_rounded;
      case 'Quà tặng':
        return Icons.card_giftcard_rounded;
      case 'Quỹ nhóm':
        return Icons.savings_rounded;
      case 'Khác':
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return const Color(0xFF59D46F);
      case 'Mua sắm':
        return const Color(0xFFFF4D8D);
      case 'Đi lại':
        return const Color(0xFF2F9BFF);
      case 'Giải trí':
        return const Color(0xFFFFA52F);
      case 'Học tập':
        return const Color(0xFF8B7CFF);
      case 'Lương':
        return const Color(0xFF10B981);
      case 'Quà tặng':
        return const Color(0xFFFF4D4D);
      case 'Quỹ nhóm':
        return const Color(0xFF10B981);
      case 'Khác':
      default:
        return const Color(0xFFAAAAAA);
    }
  }

  String _localizedCategoryName(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'Ăn uống':
        return l10n.food;
      case 'Mua sắm':
        return l10n.shopping;
      case 'Đi lại':
        return l10n.transport;
      case 'Giải trí':
        return l10n.entertainment;
      case 'Học tập':
        return l10n.education;
      case 'Lương':
        return l10n.salary;
      case 'Quà tặng':
        return l10n.gift;
      case 'Quỹ nhóm':
        return l10n.groupFundCategory;
      case 'Khác':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, cat);
    }
  }

  Future<void> _onSaveExpense() async {
    if (_parsedResult == null || _parsedResult!.amount <= 0) {
      _openEditDialog(promptForAmount: true);
      return;
    }

    final parsed = _parsedResult!;
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final capture = context.read<CaptureController>();
      final catColor = _colorForCategory(parsed.category);
      final catIcon = _iconForCategory(parsed.category);
      final catHex = '#${catColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      // Auto convert USD to VND via exchange rate API
      final double effectiveVndAmount = parsed.currency == 'USD'
          ? AppCurrencyFormatter.toVnd(inputAmount: parsed.amount, currency: 'USD')
          : parsed.amount;

      capture.clearMedia();

      // Resolve privacy, close friends, and group based on audience selection
      String effectivePrivacy = 'friends';
      List<String> effectiveCloseFriends = const [];
      bool sharedToFeed = true;
      String? effectiveGroupId;
      String? effectiveGroupName;
      List<String> effectiveGroupMemberIds = const [];

      if (_selectedAudience == 'private') {
        effectivePrivacy = 'private';
        sharedToFeed = false;
      } else if (_selectedAudience == 'friends') {
        effectivePrivacy = 'friends';
        sharedToFeed = true;
      } else if (_selectedAudience == 'close_friends') {
        effectivePrivacy = 'close_friends';
        sharedToFeed = true;
        effectiveCloseFriends = _closeFriendUids;
      } else if (_selectedAudience == 'group' && _selectedGroupId != null) {
        effectivePrivacy = 'group';
        sharedToFeed = true;
        effectiveGroupId = _selectedGroupId;
        effectiveGroupName = _selectedGroupName;
        effectiveGroupMemberIds = _selectedGroupMemberIds;
      } else if (_selectedAudience == 'friends_custom' || _selectedFriendUids.isNotEmpty) {
        effectivePrivacy = 'close_friends';
        sharedToFeed = true;
        effectiveCloseFriends = _selectedFriendUids.toList();
      }

      final ok = await capture.saveTransaction(
        userId: uid,
        amount: effectiveVndAmount,
        type: parsed.type,
        category: parsed.category,
        caption: parsed.caption,
        note: 'voice',
        sharedToFeed: sharedToFeed,
        privacy: effectivePrivacy,
        closeFriendUids: effectiveCloseFriends,
        groupId: effectiveGroupId,
        groupName: effectiveGroupName,
        groupMemberIds: effectiveGroupMemberIds,
        categoryIconCodePoint: catIcon.codePoint,
        categoryColorHex: catHex,
      );

      if (!mounted) return;

      if (ok) {
        final unlockedMilestone = capture.consumeLastUnlockedMilestone();
        if (unlockedMilestone != null && mounted) {
          await StreakMilestoneDialog.show(
            context,
            milestone: unlockedMilestone,
          );
        }

        if (mounted) {
          final isEnUI = context.read<ProfileController>().languageCode == 'en';
          AppToast.show(
            context,
            isEnUI ? 'Expense saved successfully! 🎉' : 'Đã lưu chi tiêu thành công! 🎉',
          );
          await context.read<FeedController>().refresh();
          Navigator.of(context).pop(true);
        }
      } else {
        AppToast.show(context, 'Lưu chi tiêu không thành công.');
      }
    } catch (e) {
      debugPrint('Voice expense save error: $e');
      if (mounted) {
        AppToast.show(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openEditDialog({
    bool promptForAmount = false,
  }) async {
    await _voiceService.stopListening();

    if (!mounted) return;

    final defaultCurrency = context.read<ProfileController>().currency;
    final initialParsed = _parsedResult ??
        ExpenseParser.parse(
          _transcript.isNotEmpty ? _transcript : '',
          defaultCurrency: defaultCurrency,
        );

    final updated = await showModalBottomSheet<VoiceExpenseEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceExpenseEditorSheet(
        initial: initialParsed,
        autoFocusAmount: promptForAmount,
        initialAudience: _selectedAudience,
        initialSelectedFriendUids: _selectedFriendUids,
        initialGroupId: _selectedGroupId,
        initialGroupName: _selectedGroupName,
        initialGroupMemberIds: _selectedGroupMemberIds,
        friends: _friends,
        closeFriendUids: _closeFriendUids,
        userGroups: _userGroups,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _parsedResult = updated.parsed;
        _selectedAudience = updated.audience;
        _selectedFriendUids.clear();
        _selectedFriendUids.addAll(updated.selectedFriendUids);
        _selectedGroupId = updated.selectedGroupId;
        _selectedGroupName = updated.selectedGroupName;
        _selectedGroupMemberIds = updated.selectedGroupMemberIds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final themeBg = isDark ? const Color(0xFF1E212A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF272B37) : const Color(0xFFF4F7FC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A2238);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    final isEnUI = context.watch<ProfileController>().languageCode == 'en';
    final isListening = _voiceStatus == VoiceInputStatus.listening;
    final primaryColor = AppColors.primaryBlue;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: themeBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Title & Language Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEnUI ? 'Voice Expense Input' : 'Nhập chi tiêu bằng giọng nói',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Speech Language Switcher Pill: [ 🇻🇳 VN ] | [ 🇺🇸 EN ]
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF272B37) : const Color(0xFFEEF2F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _switchSpeechLanguage('vi'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedSpeechLanguage == 'vi' ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇻🇳', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'VN',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedSpeechLanguage == 'vi'
                                          ? Colors.white
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _switchSpeechLanguage('en'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedSpeechLanguage == 'en' ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇺🇸', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedSpeechLanguage == 'en'
                                          ? Colors.white
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFEEF2F8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // FIXED HEIGHT CONTAINER: Mic + Pulse + Waveform + Status text
                SizedBox(
                  height: 175,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mic Button with Fixed-size concentric pulse container
                      SizedBox(
                        width: 110,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isListening) ...[
                              // Outer Glowing Aura - expands dynamically with voice level + pulse
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final pulse = _pulseController.value;
                                  final voiceBloom = _smoothedSoundLevel * 26.0;
                                  final size = 74.0 + voiceBloom + (pulse * 10.0);
                                  final opacity = (0.12 + (_smoothedSoundLevel * 0.22) * (1 - pulse * 0.4)).clamp(0.06, 0.40);

                                  return Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryColor.withValues(alpha: opacity),
                                    ),
                                  );
                                },
                              ),

                              // Inner Glowing Aura - tighter, brighter pulse responding to voice
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final pulse = _pulseController.value;
                                  final voiceBloom = _smoothedSoundLevel * 16.0;
                                  final size = 68.0 + voiceBloom + (pulse * 6.0);
                                  final opacity = (0.22 + (_smoothedSoundLevel * 0.28) * (1 - pulse * 0.3)).clamp(0.12, 0.55);

                                  return Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryColor.withValues(alpha: opacity),
                                    ),
                                  );
                                },
                              ),
                            ],

                            // Central Mic Button with subtle micro-scale bump when speaking
                            Transform.scale(
                              scale: isListening ? (1.0 + (_smoothedSoundLevel * 0.07)).clamp(1.0, 1.08) : 1.0,
                              child: GestureDetector(
                                onTap: _toggleListening,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isListening
                                        ? primaryColor
                                        : (isDark ? const Color(0xFF262B38) : const Color(0xFFEDF0F5)),
                                    border: Border.all(
                                      color: isListening
                                          ? Colors.white.withValues(alpha: (0.45 + (_smoothedSoundLevel * 0.35)).clamp(0.45, 0.95))
                                          : (isDark ? const Color(0xFF3B4154) : const Color(0xFFD8DCE4)),
                                      width: 3.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isListening ? primaryColor : Colors.black).withValues(
                                          alpha: isListening
                                              ? (0.35 + (_smoothedSoundLevel * 0.30)).clamp(0.35, 0.70)
                                              : (isDark ? 0.30 : 0.08),
                                        ),
                                        blurRadius: isListening ? (16 + (_smoothedSoundLevel * 14)) : 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                                      color: isListening
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF8E95A5) : const Color(0xFF757D8E)),
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Fixed Height Waveform Container (Height: 32)
                      SizedBox(
                        height: 32,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_barHeights.length, (i) {
                              final h = isListening ? _barHeights[i] : 6.0;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                width: 4,
                                height: h,
                                decoration: BoxDecoration(
                                  color: isListening ? primaryColor : textSecondary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Fixed Height Status text Container (Height: 20)
                      SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(
                            isListening
                                ? (_selectedSpeechLanguage == 'en' ? 'Listening in English...' : 'Đang lắng nghe... bạn hãy nói')
                                : (_errorMessage != null
                                    ? _errorMessage!
                                    : (_transcript.isNotEmpty
                                        ? (isEnUI ? 'Recognized! Tap mic to speak again' : 'Đã ghi nhận! Chạm mic để nói lại')
                                        : (isEnUI ? 'Tap mic to start speaking' : 'Chạm vào mic để bắt đầu nói'))),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _errorMessage != null ? Colors.redAccent : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Realtime Speech Bubble / Transcript
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEnUI ? 'YOU SAID:' : 'LỜI BẠN NÓI:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _transcript.isNotEmpty
                            ? '"$_transcript"'
                            : (_selectedSpeechLanguage == 'en'
                                ? 'e.g.: "Lunch with friends \$15", "Gas 30 dollars" |'
                                : 'Ví dụ: "Ăn trưa phở bò 45k", "Đổ xăng 70 ngàn" |'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                          fontWeight: _transcript.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          color: _transcript.isNotEmpty ? textPrimary : textSecondary.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Parsed Preview & Confidence Card
                if (_parsedResult != null && _transcript.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildParsedPreviewCard(context, _parsedResult!, isDark, isEnUI),
                ],

                const SizedBox(height: 16),

                // Audience & Privacy Selector
                _AudienceSelectorRow(
                  selectedAudience: _selectedAudience,
                  selectedFriendUids: _selectedFriendUids,
                  selectedGroupId: _selectedGroupId,
                  friends: _friends,
                  closeFriendUids: _closeFriendUids,
                  userGroups: _userGroups,
                  onPrivateSelected: () {
                    setState(() {
                      _selectedAudience = 'private';
                      _selectedFriendUids.clear();
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                      _selectedGroupMemberIds = [];
                      if (_parsedResult != null && _parsedResult!.category == 'Quỹ nhóm') {
                        _parsedResult = _parsedResult!.copyWith(category: 'Ăn uống', categoryKey: 'food');
                      }
                    });
                  },
                  onAllFriendsSelected: () {
                    setState(() {
                      _selectedAudience = 'friends';
                      _selectedFriendUids.clear();
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                      _selectedGroupMemberIds = [];
                      if (_parsedResult != null && _parsedResult!.category == 'Quỹ nhóm') {
                        _parsedResult = _parsedResult!.copyWith(category: 'Ăn uống', categoryKey: 'food');
                      }
                    });
                  },
                  onCloseFriendsSelected: () {
                    setState(() {
                      _selectedAudience = 'close_friends';
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                      _selectedGroupMemberIds = [];
                      _selectedFriendUids.clear();
                      _selectedFriendUids.addAll(_closeFriendUids);
                      if (_parsedResult != null && _parsedResult!.category == 'Quỹ nhóm') {
                        _parsedResult = _parsedResult!.copyWith(category: 'Ăn uống', categoryKey: 'food');
                      }
                    });
                  },
                  onGroupSelected: (group) {
                    final gId = (group['id'] ?? group['groupId'] ?? '').toString();
                    final gName = (group['name'] ?? 'Nhóm').toString();
                    final gMembers = (group['memberIds'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    setState(() {
                      _selectedAudience = 'group';
                      _selectedGroupId = gId;
                      _selectedGroupName = gName;
                      _selectedGroupMemberIds = gMembers;
                      _selectedFriendUids.clear();
                    });
                  },
                  onFriendToggled: (friend) {
                    final fUid = (friend['uid'] ?? '').toString();
                    setState(() {
                      _selectedGroupId = null;
                      _selectedGroupName = null;
                      _selectedGroupMemberIds = [];

                      if (_selectedFriendUids.contains(fUid)) {
                        _selectedFriendUids.remove(fUid);
                        if (_selectedFriendUids.isEmpty) {
                          _selectedAudience = 'friends';
                        }
                      } else {
                        _selectedFriendUids.add(fUid);
                        _selectedAudience = 'friends_custom';
                      }

                      if (_parsedResult != null && _parsedResult!.category == 'Quỹ nhóm') {
                        _parsedResult = _parsedResult!.copyWith(category: 'Ăn uống', categoryKey: 'food');
                      }
                    });
                  },
                  isDark: isDark,
                  isEnUI: isEnUI,
                ),

                const SizedBox(height: 18),

                // Action Buttons: [ ✏️ Sửa chi tiết ] and [ ✓ Lưu chi tiêu ]
                Row(
                  children: [
                    // Sửa chi tiết button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditDialog(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white,
                        ),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 17,
                          color: textPrimary,
                        ),
                        label: Text(
                          isEnUI ? 'Edit details' : 'Sửa chi tiết',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Lưu chi tiêu button
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _onSaveExpense,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSaving
                              ? (isEnUI ? 'Saving...' : 'Đang lưu...')
                              : (isEnUI ? 'Save expense' : 'Lưu chi tiêu'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParsedPreviewCard(
    BuildContext context,
    ParsedExpenseResult parsed,
    bool isDark,
    bool isEnUI,
  ) {
    final catColor = _colorForCategory(parsed.category);
    final catIcon = _iconForCategory(parsed.category);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A2238);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: catColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category Chip
              GestureDetector(
                onTap: () => _openEditDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(catIcon, size: 14, color: catColor),
                      const SizedBox(width: 5),
                      Text(
                        _localizedCategoryName(context, parsed.category),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Confidence / Category Alert Badge
              if (!parsed.hasCategory)
                GestureDetector(
                  onTap: () => _openEditDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEnUI ? 'Choose category' : 'Chưa chọn mục',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                )
              else if (parsed.isHighConfidence)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEnUI ? 'High confidence' : 'Độ tin cậy cao',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _openEditDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEnUI ? 'Please check' : 'Kiểm tra lại',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Caption & Amount Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  parsed.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (parsed.hasAmount && parsed.amount > 0)
                Text(
                  _formatDisplayMoney(parsed.amount, parsed.currency),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: parsed.type == 'income' ? const Color(0xFF10B981) : catColor,
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _openEditDialog(promptForAmount: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 13, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          isEnUI ? 'Enter amount' : 'Nhập số tiền',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceExpenseEditorSheet extends StatefulWidget {
  final ParsedExpenseResult initial;
  final bool autoFocusAmount;
  final String initialAudience;
  final Set<String> initialSelectedFriendUids;
  final String? initialGroupId;
  final String? initialGroupName;
  final List<String> initialGroupMemberIds;
  final List<Map<String, dynamic>> friends;
  final List<String> closeFriendUids;
  final List<Map<String, dynamic>> userGroups;

  const _VoiceExpenseEditorSheet({
    required this.initial,
    this.autoFocusAmount = false,
    this.initialAudience = 'friends',
    this.initialSelectedFriendUids = const {},
    this.initialGroupId,
    this.initialGroupName,
    this.initialGroupMemberIds = const [],
    this.friends = const [],
    this.closeFriendUids = const [],
    this.userGroups = const [],
  });

  @override
  State<_VoiceExpenseEditorSheet> createState() => _VoiceExpenseEditorSheetState();
}

class _VoiceExpenseEditorSheetState extends State<_VoiceExpenseEditorSheet> {
  late TextEditingController _captionController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  late String _selectedType;
  late String _selectedCurrency;

  late String _selectedAudience;
  late Set<String> _selectedFriendUids;
  late String? _selectedGroupId;
  late String? _selectedGroupName;
  late List<String> _selectedGroupMemberIds;

  List<String> get _allCategories {
    if (_selectedAudience == 'group') {
      return const [
        'Quỹ nhóm',
        'Ăn uống',
        'Mua sắm',
        'Đi lại',
        'Giải trí',
        'Học tập',
        'Lương',
        'Quà tặng',
        'Khác',
      ];
    }
    return const [
      'Ăn uống',
      'Mua sắm',
      'Đi lại',
      'Giải trí',
      'Học tập',
      'Lương',
      'Quà tặng',
      'Khác',
    ];
  }

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initial.caption);
    _selectedType = widget.initial.type;
    _selectedCurrency = widget.initial.currency;

    _selectedAudience = widget.initialAudience;
    _selectedFriendUids = Set<String>.from(widget.initialSelectedFriendUids);
    _selectedGroupId = widget.initialGroupId;
    _selectedGroupName = widget.initialGroupName;
    _selectedGroupMemberIds = List<String>.from(widget.initialGroupMemberIds);

    _selectedCategory = widget.initial.category;
    if (_selectedAudience != 'group' && _selectedCategory == 'Quỹ nhóm') {
      _selectedCategory = 'Ăn uống';
    }

    final initialAmountStr = widget.initial.amount > 0
        ? (_selectedCurrency == 'USD'
            ? widget.initial.amount.toStringAsFixed(widget.initial.amount.truncateToDouble() == widget.initial.amount ? 0 : 2)
            : widget.initial.amount.toStringAsFixed(0))
        : '';
    _amountController = TextEditingController(text: initialAmountStr);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Đi lại':
        return Icons.directions_bus_rounded;
      case 'Giải trí':
        return Icons.movie_rounded;
      case 'Học tập':
        return Icons.menu_book_rounded;
      case 'Lương':
        return Icons.payments_rounded;
      case 'Quà tặng':
        return Icons.card_giftcard_rounded;
      case 'Quỹ nhóm':
        return Icons.savings_rounded;
      case 'Khác':
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return const Color(0xFF59D46F);
      case 'Mua sắm':
        return const Color(0xFFFF4D8D);
      case 'Đi lại':
        return const Color(0xFF2F9BFF);
      case 'Giải trí':
        return const Color(0xFFFFA52F);
      case 'Học tập':
        return const Color(0xFF8B7CFF);
      case 'Lương':
        return const Color(0xFF10B981);
      case 'Quà tặng':
        return const Color(0xFFFF4D4D);
      case 'Quỹ nhóm':
        return const Color(0xFF10B981);
      case 'Khác':
      default:
        return const Color(0xFFAAAAAA);
    }
  }

  String _localizedCategoryName(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'Ăn uống':
        return l10n.food;
      case 'Mua sắm':
        return l10n.shopping;
      case 'Đi lại':
        return l10n.transport;
      case 'Giải trí':
        return l10n.entertainment;
      case 'Học tập':
        return l10n.education;
      case 'Lương':
        return l10n.salary;
      case 'Quà tặng':
        return l10n.gift;
      case 'Quỹ nhóm':
        return l10n.groupFundCategory;
      case 'Khác':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, cat);
    }
  }

  void _onConfirm() {
    final rawAmount = _selectedCurrency == 'USD'
        ? _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
        : _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(rawAmount) ?? 0;
    final caption = _captionController.text.trim();

    final result = widget.initial.copyWith(
      caption: caption.isNotEmpty ? caption : widget.initial.caption,
      amount: amount,
      currency: _selectedCurrency,
      category: _selectedCategory,
      type: _selectedType,
      hasAmount: amount > 0,
      hasCategory: true,
      confidence: 1.0,
    );

    Navigator.of(context).pop(VoiceExpenseEditResult(
      parsed: result,
      audience: _selectedAudience,
      selectedFriendUids: _selectedFriendUids,
      selectedGroupId: _selectedGroupId,
      selectedGroupName: _selectedGroupName,
      selectedGroupMemberIds: _selectedGroupMemberIds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final themeBg = isDark ? const Color(0xFF1E212A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A2238);
    final inputBg = isDark ? const Color(0xFF272B37) : const Color(0xFFF3F5F4);
    final isEnUI = context.watch<ProfileController>().languageCode == 'en';
    final primaryColor = AppColors.primaryBlue;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: themeBg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEnUI ? 'Edit Expense Details' : 'Chỉnh sửa thông tin chi tiêu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Caption Field
                  Text(
                    isEnUI ? 'Description / Caption' : 'Nội dung / Caption',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _captionController,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: isEnUI ? 'e.g. Lunch with team' : 'Ví dụ: Ăn trưa phở bò',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Amount & Currency Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEnUI ? 'Amount' : 'Số tiền',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        ),
                      ),

                      // Currency Toggle: VND | USD
                      Container(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['VND', 'USD'].map((cur) {
                            final isSelected = cur == _selectedCurrency;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCurrency = cur;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cur,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    autofocus: widget.autoFocusAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      if (_selectedCurrency == 'VND') ...[
                        FilteringTextInputFormatter.digitsOnly,
                        MoneyInputFormatter(maxDigits: 12),
                      ],
                    ],
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedCurrency == 'USD' ? '15.00' : '45.000',
                      suffixText: _selectedCurrency == 'USD' ? '\$' : '₫',
                      suffixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Category Selector
                  Text(
                    isEnUI ? 'Category' : 'Danh mục',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCategories.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            if (cat == 'Lương') {
                              _selectedType = 'income';
                            } else {
                              _selectedType = 'expense';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? const Color(0xFF2C303E) : const Color(0xFFEBF0ED)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconForCategory(cat),
                                size: 15,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF2D3748)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _localizedCategoryName(context, cat),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF2D3748)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Audience / Privacy Selector in Edit Sheet
                  Text(
                    isEnUI ? 'Audience / Privacy' : 'Đối tượng xem',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AudienceSelectorRow(
                    selectedAudience: _selectedAudience,
                    selectedFriendUids: _selectedFriendUids,
                    selectedGroupId: _selectedGroupId,
                    friends: widget.friends,
                    closeFriendUids: widget.closeFriendUids,
                    userGroups: widget.userGroups,
                    onPrivateSelected: () {
                      setState(() {
                        _selectedAudience = 'private';
                        _selectedFriendUids.clear();
                        _selectedGroupId = null;
                        _selectedGroupName = null;
                        _selectedGroupMemberIds = [];
                        if (_selectedCategory == 'Quỹ nhóm') {
                          _selectedCategory = 'Ăn uống';
                        }
                      });
                    },
                    onAllFriendsSelected: () {
                      setState(() {
                        _selectedAudience = 'friends';
                        _selectedFriendUids.clear();
                        _selectedGroupId = null;
                        _selectedGroupName = null;
                        _selectedGroupMemberIds = [];
                        if (_selectedCategory == 'Quỹ nhóm') {
                          _selectedCategory = 'Ăn uống';
                        }
                      });
                    },
                    onCloseFriendsSelected: () {
                      setState(() {
                        _selectedAudience = 'close_friends';
                        _selectedGroupId = null;
                        _selectedGroupName = null;
                        _selectedGroupMemberIds = [];
                        _selectedFriendUids.clear();
                        _selectedFriendUids.addAll(widget.closeFriendUids);
                        if (_selectedCategory == 'Quỹ nhóm') {
                          _selectedCategory = 'Ăn uống';
                        }
                      });
                    },
                    onGroupSelected: (group) {
                      final gId = (group['id'] ?? group['groupId'] ?? '').toString();
                      final gName = (group['name'] ?? 'Nhóm').toString();
                      final gMembers = (group['memberIds'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          <String>[];
                      setState(() {
                        _selectedAudience = 'group';
                        _selectedGroupId = gId;
                        _selectedGroupName = gName;
                        _selectedGroupMemberIds = gMembers;
                        _selectedFriendUids.clear();
                        if (widget.initial.category == 'Quỹ nhóm') {
                          _selectedCategory = 'Quỹ nhóm';
                        }
                      });
                    },
                    onFriendToggled: (friend) {
                      final fUid = (friend['uid'] ?? '').toString();
                      setState(() {
                        _selectedGroupId = null;
                        _selectedGroupName = null;
                        _selectedGroupMemberIds = [];

                        if (_selectedFriendUids.contains(fUid)) {
                          _selectedFriendUids.remove(fUid);
                          if (_selectedFriendUids.isEmpty) {
                            _selectedAudience = 'friends';
                          }
                        } else {
                          _selectedFriendUids.add(fUid);
                          _selectedAudience = 'friends_custom';
                        }

                        if (_selectedCategory == 'Quỹ nhóm') {
                          _selectedCategory = 'Ăn uống';
                        }
                      });
                    },
                    isDark: isDark,
                    isEnUI: isEnUI,
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isEnUI ? 'Apply Changes' : 'Xong & Áp dụng',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal Audience & Privacy Selector Row
class _AudienceSelectorRow extends StatelessWidget {
  final String selectedAudience;
  final Set<String> selectedFriendUids;
  final String? selectedGroupId;
  final List<Map<String, dynamic>> friends;
  final List<String> closeFriendUids;
  final List<Map<String, dynamic>> userGroups;
  final VoidCallback onPrivateSelected;
  final VoidCallback onAllFriendsSelected;
  final VoidCallback onCloseFriendsSelected;
  final ValueChanged<Map<String, dynamic>> onGroupSelected;
  final ValueChanged<Map<String, dynamic>> onFriendToggled;
  final bool isDark;
  final bool isEnUI;

  const _AudienceSelectorRow({
    required this.selectedAudience,
    required this.selectedFriendUids,
    required this.selectedGroupId,
    required this.friends,
    required this.closeFriendUids,
    required this.userGroups,
    required this.onPrivateSelected,
    required this.onAllFriendsSelected,
    required this.onCloseFriendsSelected,
    required this.onGroupSelected,
    required this.onFriendToggled,
    required this.isDark,
    required this.isEnUI,
  });

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF10B981);
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryBlue;

    final isPrivateSelected = selectedAudience == 'private';
    final isAllSelected = selectedAudience == 'friends' && selectedFriendUids.isEmpty && selectedGroupId == null;
    final isCloseFriendsSelected = selectedAudience == 'close_friends';

    // Always display full friends list
    final displayedFriends = friends;

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          // 1. Riêng tư (Private)
          _buildItem(
            label: isEnUI ? 'Private' : 'Riêng tư',
            isSelected: isPrivateSelected,
            onTap: onPrivateSelected,
            child: Icon(
              Icons.lock_rounded,
              size: 24,
              color: isPrivateSelected
                  ? (isDark ? Colors.white : primaryColor)
                  : (isDark ? const Color(0xFF8E95A5) : const Color(0xFF6B7280)),
            ),
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 14),

          // 2. Tất cả (All Friends)
          _buildItem(
            label: isEnUI ? 'All' : 'Tất cả',
            isSelected: isAllSelected,
            onTap: onAllFriendsSelected,
            child: Icon(
              Icons.groups_rounded,
              size: 26,
              color: isAllSelected
                  ? (isDark ? Colors.white : primaryColor)
                  : (isDark ? const Color(0xFF8E95A5) : const Color(0xFF6B7280)),
            ),
            isDark: isDark,
            primaryColor: primaryColor,
          ),

          // 3. Bạn thân (Close Friends) - Only show if user has close friends!
          if (closeFriendUids.isNotEmpty) ...[
            const SizedBox(width: 14),
            _buildItem(
              label: isEnUI ? 'Close friends' : 'Bạn thân',
              isSelected: isCloseFriendsSelected,
              onTap: onCloseFriendsSelected,
              child: const Icon(
                Icons.star_rounded,
                size: 26,
                color: Color(0xFFFBBF24),
              ),
              isDark: isDark,
              primaryColor: primaryColor,
            ),
          ],

          // 4. Nhóm (Groups)
          for (final group in userGroups) ...[
            const SizedBox(width: 14),
            _buildGroupItem(
              group: group,
              isSelected: selectedAudience == 'group' &&
                  (group['id'] ?? group['groupId'] ?? '').toString() == selectedGroupId,
              onTap: () => onGroupSelected(group),
              isDark: isDark,
              primaryColor: primaryColor,
            ),
          ],

          // 5. Friends list (Multi-selectable)
          for (final friend in displayedFriends) ...[
            const SizedBox(width: 14),
            _buildFriendItem(
              friend: friend,
              isCloseFriend: closeFriendUids.contains((friend['uid'] ?? '').toString()),
              isSelected: selectedFriendUids.contains((friend['uid'] ?? '').toString()),
              onTap: () => onFriendToggled(friend),
              isDark: isDark,
              primaryColor: primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
    required bool isDark,
    required Color primaryColor,
  }) {
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? (isDark ? primaryColor.withValues(alpha: 0.22) : primaryColor.withValues(alpha: 0.12))
                  : (isDark ? const Color(0xFF262B38) : const Color(0xFFE9ECF2)),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : primaryColor)
                    : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    final groupName = (group['name'] ?? 'Nhóm').toString();
    final groupColor = _parseHexColor(group['color'] as String? ?? group['colorHex'] as String?);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? groupColor.withValues(alpha: isDark ? 0.35 : 0.25)
                  : groupColor.withValues(alpha: isDark ? 0.15 : 0.12),
              border: Border.all(
                color: isSelected ? groupColor : Colors.transparent,
                width: 2.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: groupColor.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.groups_2_rounded,
              size: 26,
              color: groupColor,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              groupName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : groupColor)
                    : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem({
    required Map<String, dynamic> friend,
    required bool isCloseFriend,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    final name = (friend['name'] ?? '').toString().trim();
    final username = (friend['username'] ?? '').toString().trim();
    final avatarUrl = (friend['avatarUrl'] ?? '').toString().trim();
    final displayName = name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    // Initial letter for fallback
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackInitial(initial, isDark),
                        )
                      : _buildFallbackInitial(initial, isDark),
                ),
              ),

              // Close Friend Star Badge indicator
              if (isCloseFriend)
                Positioned(
                  left: -2,
                  top: -2,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E212A) : Colors.white,
                        width: 1.6,
                      ),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Multi-select Check Badge indicator
              if (isSelected)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E212A) : Colors.white,
                        width: 1.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : primaryColor)
                    : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(String initial, bool isDark) {
    // Generate harmonious colors based on letter
    final colors = [
      const Color(0xFF00796B),
      const Color(0xFF1E88E5),
      const Color(0xFF5E35B1),
      const Color(0xFFD81B60),
      const Color(0xFF3949AB),
      const Color(0xFF00897B),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
    ];
    final color = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      width: 46,
      height: 46,
      color: color,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
