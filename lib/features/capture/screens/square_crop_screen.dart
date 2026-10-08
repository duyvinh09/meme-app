import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';

enum _DragMode { none, move, topLeft, topRight, bottomLeft, bottomRight, scale }

class SquareCropState {
  final int rotationQuarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;
  final double normCropLeft;
  final double normCropTop;
  final double normCropSize;

  const SquareCropState({
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    required this.normCropLeft,
    required this.normCropTop,
    required this.normCropSize,
  });
}

class SquareCropScreen extends StatefulWidget {
  final File imageFile;
  final String? title;
  final SquareCropState? initialState;
  final ValueChanged<SquareCropState>? onStateSaved;
  final Future<void> Function(BuildContext context, File croppedFile, SquareCropState state)? onConfirmNavigate;

  const SquareCropScreen({
    super.key,
    required this.imageFile,
    this.title,
    this.initialState,
    this.onStateSaved,
    this.onConfirmNavigate,
  });

  @override
  State<SquareCropScreen> createState() => _SquareCropScreenState();
}

class _SquareCropScreenState extends State<SquareCropScreen> {
  bool _isProcessing = false;
  bool _isInteracting = false;
  Timer? _interactionEndTimer;

  double _imagePixelWidth = 0;
  double _imagePixelHeight = 0;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  int _rotationQuarterTurns = 0; // 0: 0°, 1: 90°, 2: 180°, 3: 270°
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  // Normalized crop rect within the photo coordinates [0, 0, 1, 1]
  // left, top, size (since it's a square in aspect ratio terms)
  double _normCropLeft = 0.0;
  double _normCropTop = 0.0;
  double _normCropSize = 1.0; // fraction of smaller dimension

  _DragMode _currentDragMode = _DragMode.none;
  Offset _dragStartFocal = Offset.zero;
  double _startNormLeft = 0.0;
  double _startNormTop = 0.0;
  double _startNormSize = 1.0;

  bool _hasAppliedInitialState = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      _rotationQuarterTurns = widget.initialState!.rotationQuarterTurns;
      _flipHorizontal = widget.initialState!.flipHorizontal;
      _flipVertical = widget.initialState!.flipVertical;
      _normCropLeft = widget.initialState!.normCropLeft;
      _normCropTop = widget.initialState!.normCropTop;
      _normCropSize = widget.initialState!.normCropSize;
      _hasAppliedInitialState = true;
    }
    _resolveImageDimensions();
  }

  @override
  void dispose() {
    _interactionEndTimer?.cancel();
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  void _resolveImageDimensions() {
    try {
      _imageStream = FileImage(widget.imageFile).resolve(ImageConfiguration.empty);
      _imageStreamListener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!mounted) return;
          setState(() {
            _imagePixelWidth = info.image.width.toDouble();
            _imagePixelHeight = info.image.height.toDouble();
            if (!_hasAppliedInitialState) {
              _resetCropRect();
            }
          });
        },
        onError: (dynamic error, StackTrace? _) {
          debugPrint('Error resolving image dimensions: $error');
          if (mounted && _imagePixelWidth == 0) {
            setState(() {
              _imagePixelWidth = 1000;
              _imagePixelHeight = 1000;
              if (!_hasAppliedInitialState) {
                _resetCropRect();
              }
            });
          }
        },
      );
      _imageStream!.addListener(_imageStreamListener!);
    } catch (e) {
      debugPrint('Error setting up image stream: $e');
      _imagePixelWidth = 1000;
      _imagePixelHeight = 1000;
      if (!_hasAppliedInitialState) {
        _resetCropRect();
      }
    }
  }

  void _resetCropRect() {
    final isQuarterTurn = (_rotationQuarterTurns % 2 == 1);
    final effW = isQuarterTurn
        ? (_imagePixelHeight > 0 ? _imagePixelHeight : 1000)
        : (_imagePixelWidth > 0 ? _imagePixelWidth : 1000);
    final effH = isQuarterTurn
        ? (_imagePixelWidth > 0 ? _imagePixelWidth : 1000)
        : (_imagePixelHeight > 0 ? _imagePixelHeight : 1000);
    final aspectRatio = effW / effH;

    if (aspectRatio >= 1.0) {
      // Landscape: Height is the smaller dimension (normalized height = 1.0)
      // Normalized width = aspectRatio
      _normCropSize = 1.0;
      _normCropTop = 0.0;
      _normCropLeft = (aspectRatio - 1.0) / 2.0;
    } else {
      // Portrait: Width is the smaller dimension (normalized width = 1.0)
      // Normalized height = 1.0 / aspectRatio
      final normH = 1.0 / aspectRatio;
      _normCropSize = 1.0;
      _normCropLeft = 0.0;
      _normCropTop = (normH - 1.0) / 2.0;
    }
  }

  void _triggerInteraction() {
    _interactionEndTimer?.cancel();
    if (!_isInteracting) {
      setState(() => _isInteracting = true);
    }
  }

  void _endInteraction() {
    _interactionEndTimer?.cancel();
    _interactionEndTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _isInteracting) {
        setState(() => _isInteracting = false);
      }
    });
  }

  void _rotateLeft() {
    HapticFeedback.selectionClick();
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4;
      if (_rotationQuarterTurns < 0) _rotationQuarterTurns += 4;
      _resetCropRect();
    });
  }

  void _rotateRight() {
    HapticFeedback.selectionClick();
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _resetCropRect();
    });
  }

  void _toggleFlipHorizontal() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _toggleFlipVertical() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipVertical = !_flipVertical;
    });
  }

  void _resetAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _hasAppliedInitialState = false;
      _rotationQuarterTurns = 0;
      _flipHorizontal = false;
      _flipVertical = false;
      _resetCropRect();
    });
  }

  Future<void> _handleConfirmCrop() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final isQuarterTurn = (_rotationQuarterTurns % 2 == 1);
      final effW = isQuarterTurn
          ? (_imagePixelHeight > 0 ? _imagePixelHeight : 1000)
          : (_imagePixelWidth > 0 ? _imagePixelWidth : 1000);
      final effH = isQuarterTurn
          ? (_imagePixelWidth > 0 ? _imagePixelWidth : 1000)
          : (_imagePixelHeight > 0 ? _imagePixelHeight : 1000);
      final aspectRatio = effW / effH;

      double totalNormW;
      double totalNormH;
      if (aspectRatio >= 1.0) {
        totalNormW = aspectRatio;
        totalNormH = 1.0;
      } else {
        totalNormW = 1.0;
        totalNormH = 1.0 / aspectRatio;
      }

      final cropXPct = (_normCropLeft / totalNormW).clamp(0.0, 1.0);
      final cropYPct = (_normCropTop / totalNormH).clamp(0.0, 1.0);
      final cropWPct = (_normCropSize / totalNormW).clamp(0.0, 1.0);
      final cropHPct = (_normCropSize / totalNormH).clamp(0.0, 1.0);

      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/square_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final resultPath = await compute(_cropImageIsolate, {
        'inputPath': widget.imageFile.path,
        'outputPath': outputPath,
        'quarterTurns': _rotationQuarterTurns,
        'flipH': _flipHorizontal,
        'flipV': _flipVertical,
        'cropXPercent': cropXPct,
        'cropYPercent': cropYPct,
        'cropWPercent': cropWPct,
        'cropHPercent': cropHPct,
      });

      if (!mounted) return;

      final state = SquareCropState(
        rotationQuarterTurns: _rotationQuarterTurns,
        flipHorizontal: _flipHorizontal,
        flipVertical: _flipVertical,
        normCropLeft: _normCropLeft,
        normCropTop: _normCropTop,
        normCropSize: _normCropSize,
      );

      widget.onStateSaved?.call(state);

      if (widget.onConfirmNavigate != null) {
        await widget.onConfirmNavigate!(context, File(resultPath), state);
        return;
      }

      Navigator.pop(context, File(resultPath));
    } catch (e) {
      debugPrint('Crop processing error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cropFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQuarterTurn = (_rotationQuarterTurns % 2 == 1);
    final effW = isQuarterTurn
        ? (_imagePixelHeight > 0 ? _imagePixelHeight : 1000)
        : (_imagePixelWidth > 0 ? _imagePixelWidth : 1000);
    final effH = isQuarterTurn
        ? (_imagePixelWidth > 0 ? _imagePixelWidth : 1000)
        : (_imagePixelHeight > 0 ? _imagePixelHeight : 1000);
    final aspectRatio = effW / effH;
    final defaultLeft = aspectRatio >= 1.0 ? (aspectRatio - 1.0) / 2.0 : 0.0;
    final defaultTop = aspectRatio < 1.0 ? ((1.0 / aspectRatio) - 1.0) / 2.0 : 0.0;

    final hasChanges = _rotationQuarterTurns != 0 ||
        _flipHorizontal ||
        _flipVertical ||
        _normCropSize < 0.99 ||
        (_normCropLeft - defaultLeft).abs() > 0.01 ||
        (_normCropTop - defaultTop).abs() > 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0E),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
            _buildTopBar(),

            // 2. Interactive Photo & Crop Canvas Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availW = constraints.maxWidth;
                  final availH = constraints.maxHeight;

                  final isQuarterTurn = (_rotationQuarterTurns % 2 == 1);
                  final effW = isQuarterTurn
                      ? (_imagePixelHeight > 0 ? _imagePixelHeight : 1000)
                      : (_imagePixelWidth > 0 ? _imagePixelWidth : 1000);
                  final effH = isQuarterTurn
                      ? (_imagePixelWidth > 0 ? _imagePixelWidth : 1000)
                      : (_imagePixelHeight > 0 ? _imagePixelHeight : 1000);
                  final aspectRatio = effW / effH;

                  // Fit full original photo in available viewport with padding
                  final pad = 16.0;
                  final maxW = availW - pad * 2;
                  final maxH = availH - pad * 2;

                  double photoDisplayW;
                  double photoDisplayH;
                  if (maxW / maxH > aspectRatio) {
                    photoDisplayH = maxH;
                    photoDisplayW = maxH * aspectRatio;
                  } else {
                    photoDisplayW = maxW;
                    photoDisplayH = maxW / aspectRatio;
                  }

                  final photoLeft = (availW - photoDisplayW) / 2;
                  final photoTop = (availH - photoDisplayH) / 2;
                  final photoRect = Rect.fromLTWH(
                    photoLeft,
                    photoTop,
                    photoDisplayW,
                    photoDisplayH,
                  );

                  // Unit length in pixels (the base unit of normalized coordinates)
                  final unitPx = min(photoDisplayW, photoDisplayH);

                  // Current crop rect in screen pixel coordinates
                  final cropLeft = photoLeft + _normCropLeft * unitPx;
                  final cropTop = photoTop + _normCropTop * unitPx;
                  final cropSize = _normCropSize * unitPx;
                  final cropRect =
                      Rect.fromLTWH(cropLeft, cropTop, cropSize, cropSize);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) {
                      _triggerInteraction();
                      _dragStartFocal = details.localFocalPoint;
                      _startNormLeft = _normCropLeft;
                      _startNormTop = _normCropTop;
                      _startNormSize = _normCropSize;

                      final localPos = details.localFocalPoint;
                      const handleRadius = 38.0;

                      if ((localPos - cropRect.topLeft).distance < handleRadius) {
                        _currentDragMode = _DragMode.topLeft;
                      } else if ((localPos - cropRect.topRight).distance <
                          handleRadius) {
                        _currentDragMode = _DragMode.topRight;
                      } else if ((localPos - cropRect.bottomLeft).distance <
                          handleRadius) {
                        _currentDragMode = _DragMode.bottomLeft;
                      } else if ((localPos - cropRect.bottomRight).distance <
                          handleRadius) {
                        _currentDragMode = _DragMode.bottomRight;
                      } else if (cropRect.contains(localPos)) {
                        _currentDragMode = _DragMode.move;
                      } else if (photoRect.contains(localPos)) {
                        // Tapped outside crop box but on photo: move crop box center to tapped point
                        final targetNormCenterX =
                            (localPos.dx - photoLeft) / unitPx;
                        final targetNormCenterY =
                            (localPos.dy - photoTop) / unitPx;

                        final maxNormW = photoDisplayW / unitPx;
                        final maxNormH = photoDisplayH / unitPx;

                        final newLeft = (targetNormCenterX - _normCropSize / 2)
                            .clamp(0.0, maxNormW - _normCropSize);
                        final newTop = (targetNormCenterY - _normCropSize / 2)
                            .clamp(0.0, maxNormH - _normCropSize);

                        setState(() {
                          _normCropLeft = newLeft;
                          _normCropTop = newTop;
                        });
                        _currentDragMode = _DragMode.move;
                        _startNormLeft = newLeft;
                        _startNormTop = newTop;
                      } else {
                        _currentDragMode = _DragMode.scale;
                      }
                    },
                    onScaleUpdate: (details) {
                      if (_currentDragMode == _DragMode.none) return;

                      _triggerInteraction();
                      final delta = details.localFocalPoint - _dragStartFocal;
                      final maxNormW = photoDisplayW / unitPx;
                      final maxNormH = photoDisplayH / unitPx;
                      const minNormSize = 0.25; // minimum crop size

                      if (details.pointerCount > 1) {
                        // Two finger pinch scale
                        final scale = details.scale;
                        final newSize = (_startNormSize * scale).clamp(
                          minNormSize,
                          min(maxNormW, maxNormH),
                        ).toDouble();
                        final centerNormX =
                            _startNormLeft + _startNormSize / 2;
                        final centerNormY =
                            _startNormTop + _startNormSize / 2;

                        final newLeft = (centerNormX - newSize / 2).clamp(
                          0.0,
                          maxNormW - newSize,
                        ).toDouble();
                        final newTop = (centerNormY - newSize / 2).clamp(
                          0.0,
                          maxNormH - newSize,
                        ).toDouble();

                        setState(() {
                          _normCropSize = newSize;
                          _normCropLeft = newLeft;
                          _normCropTop = newTop;
                        });
                        return;
                      }

                      if (_currentDragMode == _DragMode.move) {
                        final dNormX = delta.dx / unitPx;
                        final dNormY = delta.dy / unitPx;

                        final newLeft = (_startNormLeft + dNormX).clamp(
                          0.0,
                          maxNormW - _normCropSize,
                        ).toDouble();
                        final newTop = (_startNormTop + dNormY).clamp(
                          0.0,
                          maxNormH - _normCropSize,
                        ).toDouble();

                        setState(() {
                          _normCropLeft = newLeft;
                          _normCropTop = newTop;
                        });
                      } else if (_currentDragMode == _DragMode.bottomRight) {
                        final dSize = ((delta.dx + delta.dy) / 2) / unitPx;
                        final maxAllowed = min(
                          maxNormW - _startNormLeft,
                          maxNormH - _startNormTop,
                        );
                        final newSize =
                            (_startNormSize + dSize).clamp(minNormSize, maxAllowed).toDouble();

                        setState(() {
                          _normCropSize = newSize;
                        });
                      } else if (_currentDragMode == _DragMode.topLeft) {
                        final dSize = ((-delta.dx - delta.dy) / 2) / unitPx;
                        final maxAllowed = _startNormSize +
                            min(_startNormLeft, _startNormTop);
                        final newSize =
                            (_startNormSize + dSize).clamp(minNormSize, maxAllowed).toDouble();
                        final sizeDiff = newSize - _startNormSize;

                        setState(() {
                          _normCropSize = newSize;
                          _normCropLeft = (_startNormLeft - sizeDiff)
                              .clamp(0.0, maxNormW - newSize).toDouble();
                          _normCropTop = (_startNormTop - sizeDiff)
                              .clamp(0.0, maxNormH - newSize).toDouble();
                        });
                      } else if (_currentDragMode == _DragMode.topRight) {
                        final dSize = ((delta.dx - delta.dy) / 2) / unitPx;
                        final maxAllowed = _startNormSize +
                            min(maxNormW - (_startNormLeft + _startNormSize),
                                _startNormTop);
                        final newSize =
                            (_startNormSize + dSize).clamp(minNormSize, maxAllowed).toDouble();
                        final sizeDiff = newSize - _startNormSize;

                        setState(() {
                          _normCropSize = newSize;
                          _normCropTop = (_startNormTop - sizeDiff)
                              .clamp(0.0, maxNormH - newSize).toDouble();
                        });
                      } else if (_currentDragMode == _DragMode.bottomLeft) {
                        final dSize = ((-delta.dx + delta.dy) / 2) / unitPx;
                        final maxAllowed = _startNormSize +
                            min(_startNormLeft,
                                maxNormH - (_startNormTop + _startNormSize));
                        final newSize =
                            (_startNormSize + dSize).clamp(minNormSize, maxAllowed).toDouble();
                        final sizeDiff = newSize - _startNormSize;

                        setState(() {
                          _normCropSize = newSize;
                          _normCropLeft = (_startNormLeft - sizeDiff)
                              .clamp(0.0, maxNormW - newSize).toDouble();
                        });
                      }
                    },
                    onScaleEnd: (_) {
                      _currentDragMode = _DragMode.none;
                      _endInteraction();
                    },
                    child: Stack(
                      children: [
                        // Layer 1: Full Original Photo (Unstretched, naturally fitted)
                        Positioned(
                          left: photoLeft,
                          top: photoTop,
                          width: photoDisplayW,
                          height: photoDisplayH,
                          child: RotatedBox(
                            quarterTurns: _rotationQuarterTurns,
                            child: Transform.scale(
                              scaleX: _flipHorizontal ? -1.0 : 1.0,
                              scaleY: _flipVertical ? -1.0 : 1.0,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),

                        // Layer 2: Dimmed Mask outside the square crop box
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CropHoleMaskPainter(
                                holeRect: cropRect,
                                photoRect: photoRect,
                                maskColor: Colors.black.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),

                        // Layer 3: Square Crop Frame with 3x3 Grid and Corner Brackets
                        Positioned(
                          left: cropRect.left,
                          top: cropRect.top,
                          width: cropRect.width,
                          height: cropRect.height,
                          child: IgnorePointer(
                            child: _CropBoxOverlay(
                              isInteracting: _isInteracting,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Bottom Toolbar (Rotate 90°, Flip H, Flip V, Reset)
            _buildBottomToolbar(hasChanges),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56,
      child: Row(
        children: [
          // Cancel / Back Button
          GestureDetector(
            onTap: () {
              if (!_isProcessing) Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Center(
              child: Text(
                widget.title ?? context.l10n.cropSquareTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Done Button
          GestureDetector(
            onTap: _isProcessing ? null : _handleConfirmCrop,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.cropDone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(bool hasChanges) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161822).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _toolbarButton(
            icon: Icons.rotate_left_rounded,
            onTap: _rotateLeft,
          ),
          _toolbarButton(
            icon: Icons.rotate_right_rounded,
            onTap: _rotateRight,
          ),
          _toolbarButton(
            icon: Icons.swap_horiz_rounded,
            isActive: _flipHorizontal,
            onTap: _toggleFlipHorizontal,
          ),
          _toolbarButton(
            icon: Icons.swap_vert_rounded,
            isActive: _flipVertical,
            onTap: _toggleFlipVertical,
          ),
          _toolbarButton(
            icon: Icons.restart_alt_rounded,
            isDisabled: !hasChanges,
            onTap: hasChanges ? _resetAll : null,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    final color = isDisabled
        ? Colors.white24
        : (isActive ? AppColors.primaryBlue : Colors.white);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBlue.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? AppColors.primaryBlue
                  : Colors.white.withValues(alpha: 0.10),
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CropHoleMaskPainter extends CustomPainter {
  final Rect holeRect;
  final Rect photoRect;
  final Color maskColor;

  _CropHoleMaskPainter({
    required this.holeRect,
    required this.photoRect,
    required this.maskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Darken full viewport
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRect(holeRect);
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(
      combinedPath,
      Paint()
        ..color = maskColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CropHoleMaskPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.photoRect != photoRect ||
        oldDelegate.maskColor != maskColor;
  }
}

class _CropBoxOverlay extends StatelessWidget {
  final bool isInteracting;

  const _CropBoxOverlay({required this.isInteracting});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Thin white square border
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: isInteracting ? 0.90 : 0.60),
              width: 1.2,
            ),
          ),
        ),

        // 2. 3x3 Rule of Thirds grid lines
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isInteracting ? 0.85 : 0.35,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const Spacer(flex: 1),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(flex: 1),
                    Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const Spacer(flex: 1),
                    Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Four L-shaped Corner Handles
        const Positioned(
          top: -2,
          left: -2,
          child: _CornerHandle(isTop: true, isLeft: true),
        ),
        const Positioned(
          top: -2,
          right: -2,
          child: _CornerHandle(isTop: true, isLeft: false),
        ),
        const Positioned(
          bottom: -2,
          left: -2,
          child: _CornerHandle(isTop: false, isLeft: true),
        ),
        const Positioned(
          bottom: -2,
          right: -2,
          child: _CornerHandle(isTop: false, isLeft: false),
        ),
      ],
    );
  }
}

class _CornerHandle extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerHandle({
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const thickness = 3.2;
    const color = Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          isTop: isTop,
          isLeft: isLeft,
          thickness: thickness,
          color: color,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

// Top-level compute isolate function for background pixel crop & transform
Future<String> _cropImageIsolate(Map<String, dynamic> params) async {
  final inputPath = params['inputPath'] as String;
  final outputPath = params['outputPath'] as String;
  final quarterTurns = params['quarterTurns'] as int;
  final flipH = params['flipH'] as bool;
  final flipV = params['flipV'] as bool;
  final cropXPercent = (params['cropXPercent'] as num).toDouble();
  final cropYPercent = (params['cropYPercent'] as num).toDouble();
  final cropWPercent = (params['cropWPercent'] as num).toDouble();
  final cropHPercent = (params['cropHPercent'] as num).toDouble();

  final bytes = File(inputPath).readAsBytesSync();
  var imgObj = img.decodeImage(bytes);
  if (imgObj == null) {
    throw Exception('Failed to decode image');
  }

  // 1. Bake EXIF orientation
  imgObj = img.bakeOrientation(imgObj);

  // 2. Flip in inner scale order
  if (flipH) {
    imgObj = img.copyFlip(imgObj, direction: img.FlipDirection.horizontal);
  }
  if (flipV) {
    imgObj = img.copyFlip(imgObj, direction: img.FlipDirection.vertical);
  }

  // 3. Rotate in outer RotatedBox order
  if (quarterTurns % 4 == 1) {
    imgObj = img.copyRotate(imgObj, angle: 90);
  } else if (quarterTurns % 4 == 2) {
    imgObj = img.copyRotate(imgObj, angle: 180);
  } else if (quarterTurns % 4 == 3) {
    imgObj = img.copyRotate(imgObj, angle: 270);
  }

  final totalW = imgObj.width;
  final totalH = imgObj.height;

  var x = (cropXPercent * totalW).round().clamp(0, totalW - 1);
  var y = (cropYPercent * totalH).round().clamp(0, totalH - 1);

  var w = (cropWPercent * totalW).round().clamp(1, totalW - x);
  var h = (cropHPercent * totalH).round().clamp(1, totalH - y);

  var size = w < h ? w : h;
  if (x + size > totalW) size = totalW - x;
  if (y + size > totalH) size = totalH - y;

  final cropped = img.copyCrop(
    imgObj,
    x: x,
    y: y,
    width: size,
    height: size,
  );

  var finalImg = cropped;
  if (size > 1440) {
    finalImg = img.copyResize(cropped, width: 1440, height: 1440);
  }

  final jpgBytes = img.encodeJpg(finalImg, quality: 85);
  final outFile = File(outputPath);
  outFile.writeAsBytesSync(jpgBytes, flush: true);

  return outputPath;
}
