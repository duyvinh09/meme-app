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

/// Thẻ khối vật lý vuông phẳng (2D Rigid Body Square Box)
class _PhotoCardBody {
  TransactionModel transaction;
  int originalIndex;
  double x; // Tọa độ tâm X
  double y; // Tọa độ tâm Y
  double vx = 0.0; // Vận tốc tuyến tính X
  double vy = 0.0; // Vận tốc tuyến tính Y
  double currentAngle; // Góc xoay thực tế trong không gian 2D (radians, tự do 360°)
  double angularVelocity = 0.0; // Vận tốc góc (rad/s)
  final double halfSize; // Nửa kích thước cạnh vuông
  bool isDragging = false; // Đang được ngón tay kéo / giữ / búng

  // Thuộc tính vật lý khối cứng (Rigid Body Properties)
  static const double mass = 1.0;
  static const double invMass = 1.0;
  // Mô-men quán tính hình vuông: I = (1/6) * m * (2h)^2 = (2/3) * m * h^2
  late final double inertia = (2.0 / 3.0) * mass * halfSize * halfSize;
  late final double invInertia = 1.0 / inertia;

  // Tọa độ 4 đỉnh góc thế giới (World corner vertices)
  final List<double> cornersX = [0, 0, 0, 0];
  final List<double> cornersY = [0, 0, 0, 0];

  // Vector đơn vị của 2 trục tọa độ cục bộ (Local axes)
  double uxx = 1.0, uxy = 0.0;
  double uyx = 0.0, uyy = 1.0;

  _PhotoCardBody({
    required this.transaction,
    required this.originalIndex,
    required this.x,
    required this.y,
    required double baseAngle,
    required this.halfSize,
  }) : currentAngle = baseAngle {
    updateTransform();
  }

  void updateTransform() {
    final c = math.cos(currentAngle);
    final s = math.sin(currentAngle);
    uxx = c;
    uxy = s;
    uyx = -s;
    uyy = c;

    final h = halfSize;
    // 4 góc của khối vuông: (+h, +h), (-h, +h), (-h, -h), (+h, -h)
    cornersX[0] = x + h * c - h * s;
    cornersY[0] = y + h * s + h * c;

    cornersX[1] = x - h * c - h * s;
    cornersY[1] = y - h * s + h * c;

    cornersX[2] = x - h * c + h * s;
    cornersY[2] = y - h * s - h * c;

    cornersX[3] = x + h * c + h * s;
    cornersY[3] = y + h * s - h * c;
  }
}

/// Khay kỷ niệm với hiệu ứng các khối vuông hóa đơn/ảnh vật lý trượt, xoay và dồn đè lên nhau theo trọng lực
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

  double _smoothAccelX = 0.0;
  double _smoothAccelY = 9.8;

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
          if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;

          // Lọc thông thấp mượt mà để chống rung vi mô tay nhưng phản hồi tức thì khi nghiêng/lật máy
          _smoothAccelX = _smoothAccelX * 0.70 + event.x * 0.30;
          _smoothAccelY = _smoothAccelY * 0.70 + event.y * 0.30;

          // Phát hiện xóc / lắc mạnh để hất tung các khối thẻ
          final delta = (event.x - _lastX).abs() +
              (event.y - _lastY).abs() +
              (event.z - _lastZ).abs();

          _lastX = event.x;
          _lastY = event.y;
          _lastZ = event.z;

          if (delta > 3.2) {
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

      // Vòng lặp vật lý mô phỏng khối vuông cứng 60fps (Rigid Body Physics Simulation)
      _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted || _cards.isEmpty) return;
        _stepPhysics(0.016);
      });
    } catch (_) {}
  }

  void _applyShakeImpulse(double intensity) {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    final force = (intensity * 160.0).clamp(500.0, 1800.0);

    for (final card in _cards) {
      if (card.isDragging) continue;
      final angle = random.nextDouble() * 2 * math.pi;
      card.vx += math.cos(angle) * force;
      card.vy += -math.sin(angle).abs() * force * 1.2;
      card.angularVelocity += (random.nextDouble() - 0.5) * 16.0;
    }
  }

  /// Xử lý va chạm giữa 2 khối vuông cứng (OBB vs OBB SAT Collision)
  bool _solveBoxCollision(_PhotoCardBody a, _PhotoCardBody b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final distSq = dx * dx + dy * dy;
    final maxRadius = (a.halfSize + b.halfSize) * 1.415;
    if (distSq > maxRadius * maxRadius) return false;

    // 4 trục kiểm tra phân tách (2 trục của A, 2 trục của B)
    final axesX = [a.uxx, a.uyx, b.uxx, b.uyx];
    final axesY = [a.uxy, a.uyy, b.uxy, b.uyy];

    double minOverlap = double.infinity;
    double bestNx = 0.0;
    double bestNy = 0.0;

    for (int i = 0; i < 4; i++) {
      final nx = axesX[i];
      final ny = axesY[i];

      // Chiếu 4 góc của hộp A lên trục
      double minA = a.cornersX[0] * nx + a.cornersY[0] * ny;
      double maxA = minA;
      for (int k = 1; k < 4; k++) {
        final p = a.cornersX[k] * nx + a.cornersY[k] * ny;
        if (p < minA) minA = p;
        if (p > maxA) maxA = p;
      }

      // Chiếu 4 góc của hộp B lên trục
      double minB = b.cornersX[0] * nx + b.cornersY[0] * ny;
      double maxB = minB;
      for (int k = 1; k < 4; k++) {
        final p = b.cornersX[k] * nx + b.cornersY[k] * ny;
        if (p < minB) minB = p;
        if (p > maxB) maxB = p;
      }

      final overlap = math.min(maxA, maxB) - math.max(minA, minB);
      if (overlap <= 0.0) {
        return false; // Tồn tại trục phân tách -> Không va chạm
      }

      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestNx = nx;
        bestNy = ny;
      }
    }

    // Đảm bảo vector pháp tuyến hướng từ A sang B
    if (dx * bestNx + dy * bestNy < 0) {
      bestNx = -bestNx;
      bestNy = -bestNy;
    }

    // Tách chống lấn hình học dứt khoát - Tuyệt đối không để thẻ chìm/gộp vào nhau
    final double pushA;
    final double pushB;
    if (a.isDragging && !b.isDragging) {
      pushA = 0.0;
      pushB = 1.0;
    } else if (!a.isDragging && b.isDragging) {
      pushA = 1.0;
      pushB = 0.0;
    } else {
      pushA = 0.5;
      pushB = 0.5;
    }

    final double correction = minOverlap + 0.3;
    if (!a.isDragging) {
      a.x -= bestNx * correction * pushA;
      a.y -= bestNy * correction * pushA;
      a.updateTransform();
    }
    if (!b.isDragging) {
      b.x += bestNx * correction * pushB;
      b.y += bestNy * correction * pushB;
      b.updateTransform();
    }

    // Khi đang kéo thẻ bằng tay, đẩy dạt thẻ khác mượt mà (không tích tụ xung lực nảy nổ tung)
    if (a.isDragging || b.isDragging) {
      final dragged = a.isDragging ? a : b;
      final other = a.isDragging ? b : a;
      final sign = a.isDragging ? 1.0 : -1.0;

      other.vx = (dragged.vx * 0.35 + bestNx * sign * 140.0).clamp(-1000.0, 1000.0);
      other.vy = (dragged.vy * 0.35 + bestNy * sign * 140.0).clamp(-1000.0, 1000.0);
      other.angularVelocity = (other.angularVelocity * 0.8 + (bestNx * bestNy) * 2.5).clamp(-6.0, 6.0);
      return true;
    }

    // Thu thập các điểm tiếp xúc (Contact Manifold Points)
    final contactPointsX = <double>[];
    final contactPointsY = <double>[];

    // Đỉnh của B lún sâu nhất vào A
    double minProjB = double.infinity;
    for (int k = 0; k < 4; k++) {
      final proj = b.cornersX[k] * bestNx + b.cornersY[k] * bestNy;
      if (proj < minProjB) minProjB = proj;
    }
    for (int k = 0; k < 4; k++) {
      final proj = b.cornersX[k] * bestNx + b.cornersY[k] * bestNy;
      if (proj <= minProjB + 3.0) {
        contactPointsX.add(b.cornersX[k]);
        contactPointsY.add(b.cornersY[k]);
      }
    }

    // Đỉnh của A lún sâu nhất vào B
    double maxProjA = -double.infinity;
    for (int k = 0; k < 4; k++) {
      final proj = a.cornersX[k] * bestNx + a.cornersY[k] * bestNy;
      if (proj > maxProjA) maxProjA = proj;
    }
    for (int k = 0; k < 4; k++) {
      final proj = a.cornersX[k] * bestNx + a.cornersY[k] * bestNy;
      if (proj >= maxProjA - 3.0) {
        contactPointsX.add(a.cornersX[k]);
        contactPointsY.add(a.cornersY[k]);
      }
    }

    if (contactPointsX.isEmpty) {
      contactPointsX.add((a.x + b.x) * 0.5);
      contactPointsY.add((a.y + b.y) * 0.5);
    }

    // Xung lực va chạm khối nặng đầm tay (Low Restitution, Solid Friction)
    const restitution = 0.10; // Giảm độ nảy tối đa để tạo cảm giác khối vuông nặng trịch
    const friction = 0.60;    // Ma sát bám mặt cao
    final numContacts = contactPointsX.length;

    for (int i = 0; i < numContacts; i++) {
      final cpx = contactPointsX[i];
      final cpy = contactPointsY[i];

      final raX = cpx - a.x;
      final raY = cpy - a.y;
      final rbX = cpx - b.x;
      final rbY = cpy - b.y;

      final vpAx = a.vx - a.angularVelocity * raY;
      final vpAy = a.vy + a.angularVelocity * raX;

      final vpBx = b.vx - b.angularVelocity * rbY;
      final vpBy = b.vy + b.angularVelocity * rbX;

      final relVx = vpBx - vpAx;
      final relVy = vpBy - vpAy;

      final vn = relVx * bestNx + relVy * bestNy;

      if (vn < 0) {
        final rnA = raX * bestNy - raY * bestNx;
        final rnB = rbX * bestNy - rbY * bestNx;

        final kn = _PhotoCardBody.invMass + _PhotoCardBody.invMass +
            (rnA * rnA * a.invInertia) +
            (rnB * rnB * b.invInertia);

        if (kn > 0.0001) {
          // Khống chế xung lực tối đa chống bắn nảy bất thường
          double jn = -(1.0 + restitution) * vn / (kn * numContacts);
          jn = jn.clamp(0.0, 750.0);

          a.vx -= jn * bestNx * _PhotoCardBody.invMass;
          a.vy -= jn * bestNy * _PhotoCardBody.invMass;
          a.angularVelocity -= rnA * jn * a.invInertia;

          b.vx += jn * bestNx * _PhotoCardBody.invMass;
          b.vy += jn * bestNy * _PhotoCardBody.invMass;
          b.angularVelocity += rnB * jn * b.invInertia;

          // Ma sát tiếp tuyến tạo xoay tự nhiên
          final tx = -bestNy;
          final ty = bestNx;
          final vt = relVx * tx + relVy * ty;
          final rtA = raX * ty - raY * tx;
          final rtB = rbX * ty - rbY * tx;

          final kt = _PhotoCardBody.invMass + _PhotoCardBody.invMass +
              (rtA * rtA * a.invInertia) +
              (rtB * rtB * b.invInertia);

          if (kt > 0.0001) {
            double jt = -vt / (kt * numContacts);
            final maxJt = friction * jn;
            jt = jt.clamp(-maxJt, maxJt);

            a.vx -= jt * tx * _PhotoCardBody.invMass;
            a.vy -= jt * ty * _PhotoCardBody.invMass;
            a.angularVelocity -= rtA * jt * a.invInertia;

            b.vx += jt * tx * _PhotoCardBody.invMass;
            b.vy += jt * ty * _PhotoCardBody.invMass;
            b.angularVelocity += rtB * jt * b.invInertia;
          }
        }
      }
    }

    return true;
  }

  /// Xử lý va chạm 4 góc của khối vuông với 4 cạnh viền khay (Box vs Wall)
  void _solveWallCollision(_PhotoCardBody body, double width, double height) {
    if (body.isDragging) return;

    const double padding = 2.0;
    const double wallRestitution = 0.10; // Đập vào sàn chắc nịch, không nảy tưng tưng
    const double wallFriction = 0.65;    // Ma sát sàn bám chắc

    for (int i = 0; i < 4; i++) {
      final cx = body.cornersX[i];
      final cy = body.cornersY[i];

      // 1. Sàn đáy (Bottom Floor)
      if (cy > height - padding) {
        final pen = cy - (height - padding);
        body.y -= pen * 0.85;
        body.updateTransform();

        final rx = cx - body.x;
        final ry = cy - body.y;

        final vpx = body.vx - body.angularVelocity * ry;
        final vpy = body.vy + body.angularVelocity * rx;

        if (vpy > 0) {
          final kn = _PhotoCardBody.invMass + (rx * rx * body.invInertia);
          final jn = (1.0 + wallRestitution) * vpy / kn;

          body.vy -= jn * _PhotoCardBody.invMass;
          body.angularVelocity -= rx * jn * body.invInertia;

          final kt = _PhotoCardBody.invMass + (ry * ry * body.invInertia);
          double jt = -vpx / kt;
          final maxJt = wallFriction * jn;
          jt = jt.clamp(-maxJt, maxJt);

          body.vx += jt * _PhotoCardBody.invMass;
          body.angularVelocity += ry * jt * body.invInertia;
        }
      }

      // 2. Trần đỉnh (Top Ceiling - khi lộn ngược máy)
      if (cy < padding) {
        final pen = padding - cy;
        body.y += pen * 0.85;
        body.updateTransform();

        final rx = cx - body.x;
        final ry = cy - body.y;

        final vpx = body.vx - body.angularVelocity * ry;
        final vpy = body.vy + body.angularVelocity * rx;

        if (vpy < 0) {
          final kn = _PhotoCardBody.invMass + (rx * rx * body.invInertia);
          final jn = -(1.0 + wallRestitution) * vpy / kn;

          body.vy += jn * _PhotoCardBody.invMass;
          body.angularVelocity += rx * jn * body.invInertia;

          final kt = _PhotoCardBody.invMass + (ry * ry * body.invInertia);
          double jt = -vpx / kt;
          final maxJt = wallFriction * jn;
          jt = jt.clamp(-maxJt, maxJt);

          body.vx += jt * _PhotoCardBody.invMass;
          body.angularVelocity += ry * jt * body.invInertia;
        }
      }

      // 3. Cạnh trái (Left Wall)
      if (cx < padding) {
        final pen = padding - cx;
        body.x += pen * 0.85;
        body.updateTransform();

        final rx = cx - body.x;
        final ry = cy - body.y;

        final vpx = body.vx - body.angularVelocity * ry;
        final vpy = body.vy + body.angularVelocity * rx;

        if (vpx < 0) {
          final kn = _PhotoCardBody.invMass + (ry * ry * body.invInertia);
          final jn = -(1.0 + wallRestitution) * vpx / kn;

          body.vx += jn * _PhotoCardBody.invMass;
          body.angularVelocity -= ry * jn * body.invInertia;

          final kt = _PhotoCardBody.invMass + (rx * rx * body.invInertia);
          double jt = -vpy / kt;
          final maxJt = wallFriction * jn;
          jt = jt.clamp(-maxJt, maxJt);

          body.vy += jt * _PhotoCardBody.invMass;
          body.angularVelocity -= rx * jt * body.invInertia;
        }
      }

      // 4. Cạnh phải (Right Wall)
      if (cx > width - padding) {
        final pen = cx - (width - padding);
        body.x -= pen * 0.85;
        body.updateTransform();

        final rx = cx - body.x;
        final ry = cy - body.y;

        final vpx = body.vx - body.angularVelocity * ry;
        final vpy = body.vy + body.angularVelocity * rx;

        if (vpx > 0) {
          final kn = _PhotoCardBody.invMass + (ry * ry * body.invInertia);
          final jn = (1.0 + wallRestitution) * vpx / kn;

          body.vx -= jn * _PhotoCardBody.invMass;
          body.angularVelocity += ry * jn * body.invInertia;

          final kt = _PhotoCardBody.invMass + (rx * rx * body.invInertia);
          double jt = -vpy / kt;
          final maxJt = wallFriction * jn;
          jt = jt.clamp(-maxJt, maxJt);

          body.vy += jt * _PhotoCardBody.invMass;
          body.angularVelocity -= rx * jt * body.invInertia;
        }
      }
    }

    // Bảo vệ giới hạn tâm không bị bật ra ngoài
    final minSafeX = body.halfSize + padding;
    final maxSafeX = width - body.halfSize - padding;
    final minSafeY = body.halfSize + padding;
    final maxSafeY = height - body.halfSize - padding;

    body.x = body.x.clamp(minSafeX, maxSafeX);
    body.y = body.y.clamp(minSafeY, maxSafeY);
    body.updateTransform();
  }

  /// Tính toán mô phỏng vật lý các khối vuông giao dịch theo gia tốc trọng trường và góc nghiêng điện thoại
  void _stepPhysics(double dt) {
    // 1. Gia tốc trọng trường với vùng chết (Deadzone chống trôi vi mô) & Trọng lượng nặng
    final double rawX = -_smoothAccelX;
    final double effectiveGx;
    if (rawX.abs() > 0.65) {
      // Chỉ khi nghiêng điện thoại rõ ràng mới tạo lực trôi ngang
      effectiveGx = (rawX - 0.65 * rawX.sign) * 1200.0;
    } else {
      effectiveGx = 0.0; // Triệt tiêu hoàn toàn trôi vi mô khi cầm đứng máy
    }

    final bool isFlatOnTable =
        _smoothAccelX.abs() < 0.8 && _smoothAccelY.abs() < 0.8;
    final double effectiveGy;
    if (isFlatOnTable) {
      effectiveGy = 900.0; // Đặt trên bàn -> trọng lượng kéo chắc xuống đáy
    } else {
      effectiveGy = _smoothAccelY * 1350.0; // Rơi nặng và dứt khoát
    }

    const int subSteps = 2;
    final double subDt = dt / subSteps;

    for (int step = 0; step < subSteps; step++) {
      // 1. Áp dụng trọng lực, ma sát hãm và sleep threshold
      for (final card in _cards) {
        if (card.isDragging) continue;

        card.vx += effectiveGx * subDt;
        card.vy += effectiveGy * subDt;

        // Ma sát hãm cao tạo cảm giác khối vuông nặng đầm tay (Heavy Grounded Damping)
        card.vx *= 0.965;
        card.vy *= 0.965;
        card.angularVelocity *= 0.90;

        // Vùng dừng ổn định (Static Friction / Sleep) - triệt tiêu trượt vi mô
        final double speedSq = card.vx * card.vx + card.vy * card.vy;
        if (speedSq < 15.0 &&
            card.angularVelocity.abs() < 0.08 &&
            effectiveGx.abs() < 100.0) {
          card.vx = 0.0;
          card.vy = 0.0;
          card.angularVelocity = 0.0;
        }

        card.vx = card.vx.clamp(-2200.0, 2200.0);
        card.vy = card.vy.clamp(-2200.0, 2200.0);
        card.angularVelocity = card.angularVelocity.clamp(-15.0, 15.0);

        card.x += card.vx * subDt;
        card.y += card.vy * subDt;
        card.currentAngle += card.angularVelocity * subDt;

        card.updateTransform();
      }

      // 2. Vòng lặp giải va chạm đa tầng
      for (int iter = 0; iter < 4; iter++) {
        // Va chạm giữa các khối vuông với nhau
        for (int i = 0; i < _cards.length; i++) {
          for (int j = i + 1; j < _cards.length; j++) {
            _solveBoxCollision(_cards[i], _cards[j]);
          }
        }

        // Va chạm giữa khối vuông với 4 cạnh viền
        for (final card in _cards) {
          _solveWallCollision(card, _trayWidth, _trayHeight);
        }
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
              if (boxWidth > 50) {
                _syncCardsWithItems(items, boxWidth);
              }

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. Background Timeline các giao dịch hôm nay (Chronological Vertical Timeline)
                  if (hasItems)
                    _TrayBackgroundTimeline(
                      transactions: items,
                      isScrollable: !_showFloatingPhotos,
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
                                      // Vector delta chuẩn trong không gian khay (không bị xoay theo thẻ)
                                      card.vx = details.delta.dx / 0.016;
                                      card.vy = details.delta.dy / 0.016;

                                      card.x = (card.x + details.delta.dx)
                                          .clamp(
                                        card.halfSize + 2,
                                        boxWidth - card.halfSize - 2,
                                      );
                                      card.y = (card.y + details.delta.dy)
                                          .clamp(
                                        card.halfSize + 2,
                                        _trayHeight - card.halfSize - 2,
                                      );

                                      // Nghiêng nhẹ tự nhiên khi kéo
                                      card.angularVelocity =
                                          (details.delta.dx * 0.03)
                                              .clamp(-5.0, 5.0);
                                      card.currentAngle +=
                                          card.angularVelocity * 0.016;
                                      card.updateTransform();

                                      // Đẩy dạt các thẻ khác ngay trong thời gian thực khi ngón tay di chuyển
                                      for (final other in _cards) {
                                        if (other != card) {
                                          _solveBoxCollision(card, other);
                                          _solveWallCollision(
                                            other,
                                            boxWidth,
                                            _trayHeight,
                                          );
                                        }
                                      }
                                    });
                                  },
                                  onPanEnd: (details) {
                                    card.isDragging = false;
                                    final velocity =
                                        details.velocity.pixelsPerSecond;
                                    if (velocity.distance > 40.0) {
                                      // Ném thẻ với cảm giác khối nặng đầm tay
                                      card.vx = velocity.dx
                                          .clamp(-1800.0, 1800.0);
                                      card.vy = velocity.dy
                                          .clamp(-1800.0, 1800.0);
                                      final randomSpin =
                                          (math.Random().nextDouble() - 0.5) *
                                              3.0;
                                      card.angularVelocity =
                                          (velocity.dx * 0.005 + randomSpin)
                                              .clamp(-10.0, 10.0);
                                      HapticFeedback.lightImpact();
                                    } else {
                                      card.vx = 0.0;
                                      card.vy = 0.0;
                                      card.angularVelocity = 0.0;
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
                                  child: Transform.rotate(
                                    angle: card.currentAngle,
                                    child: _FlatPhotoCard(
                                      key: ValueKey(
                                          '${card.transaction.id}_${card.transaction.displayImageUrl}'),
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

/// Dòng thời gian nền các giao dịch hôm nay (Vertical Background Timeline)
class _TrayBackgroundTimeline extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isScrollable;

  const _TrayBackgroundTimeline({
    required this.transactions,
    required this.isScrollable,
  });

  @override
  State<_TrayBackgroundTimeline> createState() =>
      _TrayBackgroundTimelineState();
}

class _TrayBackgroundTimelineState extends State<_TrayBackgroundTimeline> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToLatestIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _TrayBackgroundTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isScrollable && oldWidget.isScrollable) {
      _scrollToLatestIfNeeded(animate: true);
    } else if (!widget.isScrollable &&
        oldWidget.transactions.length != widget.transactions.length) {
      _scrollToLatestIfNeeded(animate: true);
    }
  }

  void _scrollToLatestIfNeeded({bool animate = false}) {
    if (widget.isScrollable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currency = context.watch<ProfileController>().currency;

    // Sắp xếp theo trình tự thời gian tăng dần trong ngày (Chronological order)
    final sortedTx = List<TransactionModel>.from(widget.transactions)
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
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          physics: widget.isScrollable
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const NeverScrollableScrollPhysics(),
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

