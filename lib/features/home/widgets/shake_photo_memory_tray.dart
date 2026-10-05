import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../screens/moment_viewer_screen.dart';

/// Thẻ vật lý phẳng trượt trong khay (Flat Photo/Category Card Body)
class _PhotoCardBody {
  TransactionModel transaction;
  int originalIndex;
  double x; // Tọa độ tâm X
  double y; // Tọa độ tâm Y
  double vx = 0.0; // Vận tốc trượt X
  double vy = 0.0; // Vận tốc trượt Y
  double currentAngle; // Góc nghiêng hiển thị bị lật xiên theo va chạm
  double angularVelocity = 0.0; // Vận tốc chuyển góc
  final double halfSize; // Nửa kích thước để tính biên va chạm
  bool isDragging = false; // Đang được ngón tay giữ / búng ném

  _PhotoCardBody({
    required this.transaction,
    required this.originalIndex,
    required this.x,
    required this.y,
    required double baseAngle,
    required this.halfSize,
  }) : currentAngle = baseAngle;
}

/// Khay kỷ niệm với hiệu ứng các tấm ảnh / category vật lý phẳng trượt và rơi theo góc nghiêng điện thoại
class ShakePhotoMemoryTray extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ShakePhotoMemoryTray({
    super.key,
    required this.transactions,
  });

  @override
  State<ShakePhotoMemoryTray> createState() => _ShakePhotoMemoryTrayState();
}

class _ShakePhotoMemoryTrayState extends State<ShakePhotoMemoryTray> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _physicsTimer;

  final List<_PhotoCardBody> _cards = [];
  double _trayWidth = 340.0;
  static const double _trayHeight = 220.0;
  static const double _cardSize = 65.0;
  static const double _cardHalfSize = _cardSize / 2;

  double _accelX = 0.0;
  double _accelY = 9.8;

  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;

  DateTime _lastShakeTime = DateTime.now().subtract(const Duration(seconds: 5));
  bool _initialized = false;
  bool _showFloatingPhotos = true;

  @override
  void initState() {
    super.initState();
    _startSensorAndPhysics();
  }

  void _startSensorAndPhysics() {
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (AccelerometerEvent event) {
          _accelX = event.x;
          _accelY = event.y;

          // Phát hiện rung lắc mạnh để tạo lực xóc nảy các thẻ tung loạn xạ
          final delta = (event.x - _lastX).abs() +
              (event.y - _lastY).abs() +
              (event.z - _lastZ).abs();

          _lastX = event.x;
          _lastY = event.y;
          _lastZ = event.z;

          if (delta > 3.0) {
            final now = DateTime.now();
            if (now.difference(_lastShakeTime).inMilliseconds > 250) {
              _lastShakeTime = now;
              _applyShakeImpulse(delta);
            }
          }
        },
        onError: (e) {},
        cancelOnError: false,
      );

      // Vòng lặp vật lý trượt phẳng (Flat Sliding Physics Loop)
      _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted || _cards.isEmpty) return;
        _stepPhysics(0.016);
      });
    } catch (_) {}
  }

  void _applyShakeImpulse(double intensity) {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    final force = (intensity * 130.0).clamp(400.0, 1400.0);

    for (final card in _cards) {
      if (card.isDragging) continue;
      // Bắn tung tóe theo các hướng và làm lệch góc nghiêng tự nhiên
      final angle = random.nextDouble() * 2 * math.pi;
      card.vx += math.cos(angle) * force;
      card.vy += -math.sin(angle).abs() * force * 1.1;
      card.angularVelocity += (random.nextDouble() - 0.5) * 5.0;
    }
  }

  /// Tính toán mô phỏng vật lý các tấm ảnh / category phẳng rơi tự do, va chạm và trượt theo góc nghiêng
  void _stepPhysics(double dt) {
    // Trọng lực theo cảm biến chuyển động Accelerometer
    // - Nghiêng trái (_accelX > 0) -> gx âm (kéo về trái)
    // - Nghiêng phải (_accelX < 0) -> gx dương (kéo về phải)
    // - Dựng máy (_accelY > 0) -> gy dương (kéo xuống đáy)
    // - Lộn ngược máy (_accelY < 0) -> gy âm (kéo dồn ngược lên đỉnh)
    // - Đặt phẳng trên bàn -> mặc định trọng lực kéo xuống sàn khay
    final isFlatOnTable = _accelX.abs() < 0.9 && _accelY.abs() < 0.9;
    final gx = -_accelX * 720.0;
    final gy = isFlatOnTable ? 420.0 : (_accelY * 720.0);

    // 1. Áp dụng trọng lực và ma sát trượt
    for (final card in _cards) {
      if (card.isDragging) continue;

      card.vx += gx * dt;
      card.vy += gy * dt;

      // Giảm dần vận tốc (ma sát bề mặt và không khí)
      card.vx *= 0.980;
      card.vy *= 0.980;

      // Ma sát góc cao để xoay nghiêng rồi dừng ổn định theo va chạm
      card.angularVelocity *= 0.88;

      card.x += card.vx * dt;
      card.y += card.vy * dt;

      // Cập nhật góc lật nghiêng tự nhiên và giới hạn góc nghiêng (-45° đến +45°)
      card.currentAngle += card.angularVelocity * dt;
      card.currentAngle = card.currentAngle.clamp(-0.78, 0.78);
    }

    // 2. Xử lý va chạm các vật thể với nhau (Elastic Collision & Torque tiếp tuyến)
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < _cards.length; i++) {
        for (int j = i + 1; j < _cards.length; j++) {
          final c1 = _cards[i];
          final c2 = _cards[j];

          final dx = c2.x - c1.x;
          final dy = c2.y - c1.y;
          final distSq = dx * dx + dy * dy;
          final minDist = c1.halfSize + c2.halfSize + 2.0;

          if (distSq < minDist * minDist && distSq > 0.0001) {
            final dist = math.sqrt(distSq);
            final nx = dx / dist;
            final ny = dy / dist;

            // Đẩy dạt ra không cho lún vào nhau
            final overlap = (minDist - dist) * 0.5;
            if (!c1.isDragging && !c2.isDragging) {
              c1.x -= nx * overlap;
              c1.y -= ny * overlap;
              c2.x += nx * overlap;
              c2.y += ny * overlap;
            } else if (c1.isDragging && !c2.isDragging) {
              c2.x += nx * (overlap * 2);
              c2.y += ny * (overlap * 2);
            } else if (!c1.isDragging && c2.isDragging) {
              c1.x -= nx * (overlap * 2);
              c1.y -= ny * (overlap * 2);
            }

            // Phản lực đàn hồi nảy qua lại lẫn nhau
            final rvx = c2.vx - c1.vx;
            final rvy = c2.vy - c1.vy;
            final velAlongNormal = rvx * nx + rvy * ny;

            if (velAlongNormal < 0) {
              const restitution = 0.72; // Độ nảy đàn hồi cao
              final impulse = -(1.0 + restitution) * velAlongNormal * 0.5;

              if (!c1.isDragging) {
                c1.vx -= impulse * nx;
                c1.vy -= impulse * ny;
                // Va đập tạo mô-men làm lật xiên góc tùy điểm tiếp xúc
                final torque = (c1.vx * ny - c1.vy * nx) * 0.002;
                c1.angularVelocity += torque.clamp(-3.5, 3.5);
              }
              if (!c2.isDragging) {
                c2.vx += impulse * nx;
                c2.vy += impulse * ny;
                final torque = (c2.vx * ny - c2.vy * nx) * 0.002;
                c2.angularVelocity += torque.clamp(-3.5, 3.5);
              }
            }
          }
        }
      }
    }

    // 3. Giới hạn và nảy vào 4 cạnh tường của khay (kèm độ lật góc khi va cạnh tường)
    for (final card in _cards) {
      if (card.isDragging) continue;

      const wallRestitution = 0.70;

      // Cạnh trái
      if (card.x < card.halfSize + 4) {
        card.x = card.halfSize + 4;
        card.vx = -card.vx * wallRestitution;
        card.angularVelocity += (card.vy * 0.005).clamp(-2.5, 2.5);
      }
      // Cạnh phải
      else if (card.x > _trayWidth - card.halfSize - 4) {
        card.x = _trayWidth - card.halfSize - 4;
        card.vx = -card.vx * wallRestitution;
        card.angularVelocity -= (card.vy * 0.005).clamp(-2.5, 2.5);
      }

      // Cạnh trên (khi lộn ngược máy)
      if (card.y < card.halfSize + 4) {
        card.y = card.halfSize + 4;
        card.vy = -card.vy * wallRestitution;
        card.angularVelocity -= (card.vx * 0.005).clamp(-2.5, 2.5);
      }
      // Cạnh đáy
      else if (card.y > _trayHeight - card.halfSize - 4) {
        card.y = _trayHeight - card.halfSize - 4;
        card.vy = -card.vy * wallRestitution;
        card.angularVelocity += (card.vx * 0.005).clamp(-2.5, 2.5);
      }
    }

    setState(() {});
  }

  void _syncCardsWithItems(List<TransactionModel> items, double width) {
    if (items.isEmpty) {
      if (_cards.isNotEmpty) {
        _cards.clear();
      }
      return;
    }

    _trayWidth = width;

    // Check if current cards match items by ID exactly in order
    final bool idsMatch = _initialized &&
        _cards.length == items.length &&
        List.generate(
          items.length,
          (i) => _cards[i].transaction.id == items[i].id,
        ).every((matched) => matched);

    if (idsMatch) {
      // Refresh transaction instances and indices so media/photos are immediately updated
      for (int i = 0; i < items.length; i++) {
        _cards[i].transaction = items[i];
        _cards[i].originalIndex = i;
      }
      return;
    }

    // Reconcile existing cards by ID to preserve physics position while syncing new data
    final Map<String, _PhotoCardBody> existingMap = {
      for (final card in _cards) card.transaction.id: card,
    };

    final List<_PhotoCardBody> updatedCards = [];
    const baseAngles = [-0.18, 0.14, -0.22, 0.16, -0.12, 0.20, -0.15];
    final count = items.length;
    final random = math.Random();
    final step = (width - _cardSize - 20) / (count > 1 ? (count - 1) : 1);

    for (int i = 0; i < count; i++) {
      final tx = items[i];
      if (existingMap.containsKey(tx.id)) {
        final existingCard = existingMap[tx.id]!;
        existingCard.transaction = tx;
        existingCard.originalIndex = i;
        updatedCards.add(existingCard);
      } else {
        final startX =
            _cardHalfSize + 10.0 + (i * step) + (random.nextDouble() * 6 - 3);
        final startY =
            -_cardHalfSize - (i * 32.0) - (random.nextDouble() * 12.0);

        final body = _PhotoCardBody(
          transaction: tx,
          originalIndex: i,
          x: startX.clamp(_cardHalfSize + 4, width - _cardHalfSize - 4),
          y: startY,
          baseAngle: baseAngles[i % baseAngles.length],
          halfSize: _cardHalfSize,
        );
        body.vy = 100.0 + random.nextDouble() * 140.0;
        body.vx = (random.nextDouble() - 0.5) * 50.0;
        updatedCards.add(body);
      }
    }

    _cards.clear();
    _cards.addAll(updatedCards);
    _initialized = true;
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _physicsTimer?.cancel();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Lấy danh sách giao dịch hôm nay (cả có ảnh lẫn không có ảnh để lấy category)
  List<TransactionModel> _resolveItemsToDisplay() {
    final now = DateTime.now();

    // 1. Ưu tiên toàn bộ bài đăng / giao dịch của ngày hôm nay
    final todayList = widget.transactions
        .where((tx) => _sameDay(tx.createdAt, now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (todayList.isNotEmpty) {
      return todayList;
    }

    // 2. Nếu hôm nay chưa có, lấy ngày gần nhất có giao dịch để người dùng trải nghiệm ngay
    final allList = List<TransactionModel>.from(widget.transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allList.isNotEmpty) {
      final latestDate = allList.first.createdAt;
      return allList.where((tx) => _sameDay(tx.createdAt, latestDate)).toList();
    }

    return [];
  }

  DateTime _resolveActiveDate(List<TransactionModel> items) {
    if (items.isNotEmpty) {
      return items.first.createdAt;
    }
    return DateTime.now();
  }

  String _formatDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString().toLowerCase();
    final isVi = locale.startsWith('vi');

    if (_sameDay(date, now)) {
      return isVi ? 'Ngày hôm nay' : 'Today';
    }

    if (isVi) {
      return 'Kỷ niệm gần nhất';
    } else {
      return 'Recent Moments';
    }
  }

  String _formatDateSubtitle(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString().toLowerCase();
    final isVi = locale.startsWith('vi');

    if (isVi) {
      return 'ngày ${date.day} tháng ${date.month}, ${date.year}';
    } else {
      return DateFormat('MMMM d, yyyy', 'en_US').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final locale = Localizations.localeOf(context).toString().toLowerCase();
    final isVi = locale.startsWith('vi');

    final items = _resolveItemsToDisplay();
    final hasItems = items.isNotEmpty;
    final activeDate = _resolveActiveDate(items);

    final titleText = _formatDateHeader(context, activeDate);
    final subtitleText = _formatDateSubtitle(context, activeDate);

    final trayBgColor = isDark
        ? const Color(0xFF182233)
        : const Color(0xFFE8F1FC);

    final trayBorderColor = isDark
        ? const Color(0xFF28364F)
        : const Color(0xFFD3E4F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Ngày hôm nay" + "Nghiêng hoặc lắc"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tiêu đề
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Nút Ẩn/Hiện ảnh để người dùng xem rõ Timeline
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showFloatingPhotos = !_showFloatingPhotos;
                  });
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFloatingPhotos
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showFloatingPhotos
                            ? (isVi ? 'Ẩn ảnh' : 'Hide photos')
                            : (isVi ? 'Hiện ảnh' : 'Show photos'),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Khay chứa các tấm ảnh / category phẳng (Flat Photo & Category Tray)
        Container(
          height: _trayHeight,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: trayBgColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: trayBorderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              _syncCardsWithItems(items, boxWidth);

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. Background Timeline các giao dịch hôm nay (Chronological Vertical Timeline)
                  if (hasItems)
                    _TrayBackgroundTimeline(
                      transactions: items,
                    ),

                  // 2. Trạng thái khi không có bài đăng / giao dịch nào
                  if (!hasItems)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 22,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isVi
                                  ? 'Chưa có kỷ niệm hoặc chi tiêu nào'
                                  : 'No moments or expenses yet',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.addTransaction,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusPill),
                                ),
                                child: Text(
                                  isVi ? '+ Thêm chi tiêu / ảnh' : '+ Add expense',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. Render các tấm ảnh / category phẳng trượt tự do (có thể Ẩn/Hiện bằng nút)
                  if (hasItems)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _showFloatingPhotos ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !_showFloatingPhotos,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: _cards.map((card) {
                              return Positioned(
                                left: card.x - card.halfSize,
                                top: card.y - card.halfSize,
                                child: Transform.rotate(
                                  angle: card.currentAngle,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (details) {
                                      card.isDragging = true;
                                      card.vx = 0.0;
                                      card.vy = 0.0;
                                      card.angularVelocity = 0.0;
                                      HapticFeedback.selectionClick();
                                    },
                                    onPanUpdate: (details) {
                                      setState(() {
                                        card.x = (card.x + details.delta.dx)
                                            .clamp(
                                          card.halfSize + 4,
                                          boxWidth - card.halfSize - 4,
                                        );
                                        card.y = (card.y + details.delta.dy)
                                            .clamp(
                                          card.halfSize + 4,
                                          _trayHeight - card.halfSize - 4,
                                        );
                                        card.currentAngle =
                                            (card.currentAngle +
                                                    (details.delta.dx * 0.005))
                                                .clamp(-0.78, 0.78);
                                      });
                                    },
                                    onPanEnd: (details) {
                                      card.isDragging = false;
                                      final velocity =
                                          details.velocity.pixelsPerSecond;
                                      if (velocity.distance > 40.0) {
                                        // Búng / ném thẻ bay nảy quanh khay và lật góc tự nhiên
                                        card.vx = velocity.dx
                                            .clamp(-2400.0, 2400.0);
                                        card.vy = velocity.dy
                                            .clamp(-2400.0, 2400.0);
                                        card.angularVelocity =
                                            (velocity.dx * 0.003)
                                                .clamp(-3.0, 3.0);
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MomentViewerScreen(
                                            transactions: items,
                                            initialIndex: card.originalIndex,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _FlatPhotoCard(
                                      key: ValueKey('${card.transaction.id}_${card.transaction.displayImageUrl}'),
                                      transaction: card.transaction,
                                      size: _cardSize,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dòng thời gian nền các giao dịch hôm nay (Vertical Background Timeline - Manual Scroll Only)
class _TrayBackgroundTimeline extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _TrayBackgroundTimeline({
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currency = context.watch<ProfileController>().currency;

    // Sắp xếp theo trình tự thời gian tăng dần trong ngày (Chronological order)
    final sortedTx = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (sortedTx.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: sortedTx.length,
          itemBuilder: (context, index) {
            final tx = sortedTx[index];
            final isLast = index == sortedTx.length - 1;
            final isIncome = tx.type == 'income';
            final formattedTime = DateFormat('HH:mm').format(tx.createdAt);
            final categoryName =
                BudgetNameLocalizer.display(context, tx.category);
            final title = (tx.caption.trim().isNotEmpty)
                ? tx.caption.trim()
                : categoryName;
            final amountFormatted = AppCurrencyFormatter.formatFromVnd(
              amountVnd: tx.amount,
              currency: currency,
            );

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TimelineOppositeContent: Giờ giao dịch
                  SizedBox(
                    width: 38,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        formattedTime,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : const Color(0xFF64748B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Timeline Axis: TimelineDot + TimelineConnector
                  SizedBox(
                    width: 14,
                    child: Column(
                      children: [
                        // TimelineDot: Solid dot cho sự kiện đã qua, glowing ring cho sự kiện mới nhất
                        Container(
                          width: isLast ? 10 : 8,
                          height: isLast ? 10 : 8,
                          margin: EdgeInsets.only(top: isLast ? 2 : 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLast
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF94A3B8)),
                            border: isLast
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primaryBlueDark,
                                    width: 1.5,
                                  )
                                : null,
                            boxShadow: isLast
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        // TimelineConnector: Nối tiếp đến điểm tiếp theo và dừng ở điểm cuối cùng
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. TimelineContent: Tiêu đề và số tiền
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 4 : 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.90)
                                        : const Color(0xFF1E293B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (tx.caption.trim().isNotEmpty &&
                                    title != categoryName)
                                  Text(
                                    categoryName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.50)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isIncome ? '+' : '-'}$amountFormatted',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isIncome
                                  ? AppColors.income
                                  : (isDark
                                      ? const Color(0xFFFF8B8B)
                                      : AppColors.expenseDark),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Thẻ kỷ niệm phẳng: Hiển thị Ảnh/Video (nếu có) hoặc Category Sticker có vòng tròn bao quanh icon (nếu không có ảnh)
class _FlatPhotoCard extends StatelessWidget {
  final TransactionModel transaction;
  final double size;

  const _FlatPhotoCard({
    super.key,
    required this.transaction,
    required this.size,
  });

  static const Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
  };

  Color _resolveCategoryColor() {
    if (transaction.categoryColorHex != null &&
        transaction.categoryColorHex!.trim().isNotEmpty) {
      var hex = transaction.categoryColorHex!.trim().replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) {
        try {
          return Color(int.parse(hex, radix: 16));
        } catch (_) {}
      }
    }
    return _defaultCategoryMeta[transaction.category]?['color'] as Color? ??
        const Color(0xFF388AF6);
  }

  IconData _resolveCategoryIcon() {
    if (transaction.categoryIconCodePoint != null &&
        transaction.categoryIconCodePoint! > 0) {
      return AppIconRegistry.fromCodePoint(transaction.categoryIconCodePoint!);
    }
    return _defaultCategoryMeta[transaction.category]?['icon'] as IconData? ??
        Icons.account_balance_wallet_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasMedia = transaction.displayImageUrl.trim().isNotEmpty;

    final categoryColor = _resolveCategoryColor();
    final categoryIcon = _resolveCategoryIcon();
    final categoryLabel =
        BudgetNameLocalizer.display(context, transaction.category);

    return Hero(
      tag: 'shake_photo_${transaction.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: hasMedia
              ? (isDark ? const Color(0xFF222B3D) : Colors.white)
              : categoryColor,
          border: Border.all(
            color: isDark ? const Color(0xFF3B4861) : Colors.white,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.14),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Trường hợp có Ảnh/Video
              if (hasMedia)
                TransactionMomentImage(
                  imageUrl: transaction.displayImageUrl,
                  category: transaction.category,
                  categoryIconCodePoint: transaction.categoryIconCodePoint,
                  categoryColorHex: transaction.categoryColorHex,
                  isVideo: transaction.isVideo,
                  showVideoBadge: true,
                  fit: BoxFit.cover,
                )
              // 2. Trường hợp không có ảnh: Hiển thị Thẻ Category với Vòng tròn bao quanh Icon giống trang chi tiết
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withValues(alpha: 0.95),
                        categoryColor.withValues(alpha: 0.72),
                        const Color(0xFF1B2230),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vòng tròn bao quanh icon đại diện cho category
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              categoryIcon,
                              color: Colors.white,
                              size: 15.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Lớp viền phản quang nhẹ như chất liệu giấy thẻ thật
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                    width: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

