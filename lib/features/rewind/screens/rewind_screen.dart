import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/rewind_data.dart';
import '../models/rewind_period.dart';
import '../models/rewind_story.dart';
import '../services/rewind_aggregation_service.dart';
import '../widgets/rewind_biggest_day_story.dart';
import '../widgets/rewind_category_story.dart';
import '../widgets/rewind_comparison_story.dart';
import '../widgets/rewind_empty_story.dart';
import '../widgets/rewind_highlight_story.dart';
import '../widgets/rewind_moments_story.dart';
import '../widgets/rewind_overview_story.dart';
import '../widgets/rewind_period_picker_sheet.dart';
import '../widgets/rewind_progress_bar.dart';
import '../widgets/rewind_streak_story.dart';
import '../widgets/rewind_summary_story.dart';
import '../widgets/rewind_top_spending_story.dart';

class RewindScreen extends StatefulWidget {
  final RewindPeriod? initialPeriod;

  const RewindScreen({
    super.key,
    this.initialPeriod,
  });

  @override
  State<RewindScreen> createState() => _RewindScreenState();
}

class _RewindScreenState extends State<RewindScreen>
    with SingleTickerProviderStateMixin {
  late RewindPeriod _currentPeriod;
  late RewindData _rewindData;
  late List<RewindStory> _stories;

  int _currentIndex = 0;
  late AnimationController _progressController;
  bool _isPaused = false;
  DateTime? _touchDownTime;
  bool _isHolding = false;
  bool _isZoomedIn = false;

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.initialPeriod ?? RewindPeriod.thisWeek();

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener(_onProgressStatusChanged);

    // Initial aggregation from HomeController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForPeriod(_currentPeriod);
    });
  }

  void _loadDataForPeriod(RewindPeriod period) {
    final home = context.read<HomeController>();
    final allTransactions = home.transactions;
    final currentStreak = home.profile?.currentStreak ?? 0;

    final data = RewindAggregationService.aggregate(
      allTransactions: allTransactions,
      period: period,
      currentStreak: currentStreak,
    );

    final stories = RewindAggregationService.buildStories(data);

    setState(() {
      _currentPeriod = period;
      _rewindData = data;
      _stories = stories;
      _currentIndex = 0;
    });

    _startCurrentStory();
  }

  void _startCurrentStory() {
    if (_stories.isEmpty) return;
    _progressController.stop();
    _progressController.duration = _stories[_currentIndex].duration;
    _progressController.reset();
    _progressController.forward();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_currentIndex < _stories.length - 1) {
        _nextStory();
      }
      // If on the last story (Summary), keep progress at 100% so user can inspect and share
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
      });
      _startCurrentStory();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
      });
      _startCurrentStory();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward();
    }
  }

  void _openPeriodPicker() {
    _pause();
    RewindPeriodPickerSheet.show(
      context: context,
      currentPeriod: _currentPeriod,
      onPeriodSelected: (newPeriod) {
        _loadDataForPeriod(newPeriod);
        _resume();
      },
    ).then((_) {
      if (_isPaused) _resume();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final currentStory = _stories[_currentIndex];
    final currency = context.watch<ProfileController>().currency;
    final userName = context.watch<AuthController>().user?.displayName ??
        context.watch<HomeController>().profile?.name ??
        'User';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: (details) {
            if (_isZoomedIn) return;
            _touchDownTime = DateTime.now();
            _isHolding = false;
            _pause();
          },
          onLongPressStart: (_) {
            if (_isZoomedIn) return;
            _isHolding = true;
            _pause();
          },
          onLongPressEnd: (_) {
            if (_isZoomedIn) return;
            _isHolding = true;
            _resume();
          },
          onTapUp: (details) {
            if (_isZoomedIn) return;
            final now = DateTime.now();
            final touchDuration = _touchDownTime != null
                ? now.difference(_touchDownTime!).inMilliseconds
                : 0;

            if (!_isHolding && touchDuration < 280) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapX = details.globalPosition.dx;

              if (tapX < screenWidth * 0.35) {
                _previousStory();
              } else {
                _nextStory();
              }
            } else {
              _resume();
            }
          },
          onTapCancel: () {
            if (_isZoomedIn) return;
            _resume();
          },
          onHorizontalDragEnd: (details) {
            if (_isZoomedIn) return;
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -300) {
              _nextStory();
            } else if (velocity > 300) {
              _previousStory();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentStory.backgroundGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // STORY CONTENT WITH TOP INSET TO AVOID COLLISION WITH HEADER
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 72, bottom: 8),
                      child: _buildStoryContent(
                        story: currentStory,
                        data: _rewindData,
                        currency: currency,
                        userName: userName,
                      ),
                    ),
                  ),

                  // TOP NAVIGATION BAR (Progress + Period Selector + Close)
                  Positioned(
                    top: 8,
                    left: 14,
                    right: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return RewindProgressBar(
                              totalSegments: _stories.length,
                              currentIndex: _currentIndex,
                              currentProgress: _progressController.value,
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Header Controls Row
                        Row(
                          children: [
                            // Period Selector Capsule Button
                            InkWell(
                              onTap: _openPeriodPicker,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPeriod.getTitle(context),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Close Button 'X'
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStoryContent({
    required RewindStory story,
    required RewindData data,
    required String currency,
    required String userName,
  }) {
    switch (story.type) {
      case RewindStoryType.overview:
        return RewindOverviewStory(
          key: ValueKey('overview_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.categories:
        return RewindCategoryStory(
          key: ValueKey('cat_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.streak:
        return RewindStreakStory(
          key: ValueKey('streak_${story.id}_$_currentIndex'),
          data: data,
        );
      case RewindStoryType.topExpenses:
        return RewindTopSpendingStory(
          key: ValueKey('top_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.biggestDay:
        return RewindBiggestDayStory(
          key: ValueKey('big_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.moments:
        return RewindMomentsStory(
          key: ValueKey('moments_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
          onZoomChanged: (isZoomed) {
            setState(() => _isZoomedIn = isZoomed);
            if (isZoomed) {
              _pause();
            } else {
              _resume();
            }
          },
        );
      case RewindStoryType.highlight:
        return RewindHighlightStory(
          key: ValueKey('highlight_${story.id}_$_currentIndex'),
          data: data,
        );
      case RewindStoryType.comparison:
        return RewindComparisonStory(
          key: ValueKey('comparison_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
        );
      case RewindStoryType.summary:
        return RewindSummaryStory(
          key: ValueKey('summary_${story.id}_$_currentIndex'),
          data: data,
          currency: currency,
          userName: userName,
        );
      case RewindStoryType.empty:
        return RewindEmptyStory(
          key: ValueKey('empty_${story.id}_$_currentIndex'),
          period: data.period,
          onPickPeriod: _openPeriodPicker,
        );
    }
  }
}
