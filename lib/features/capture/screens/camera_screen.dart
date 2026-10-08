import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:light_compressor_v2/light_compressor_v2.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/camera_theme.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/capture_controller.dart';
import 'preview_screen.dart';
import 'square_crop_screen.dart';

enum CameraCaptureMode { photo, video }

class RoundedRectProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final Color strokeColor;
  final double outerRadius;

  RoundedRectProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.strokeColor,
    required this.outerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final halfStroke = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final innerR = (outerRadius - halfStroke).clamp(0.0, rect.shortestSide / 2);

    final fullPath = Path();
    // Start at top center: (x = size.width / 2, y = halfStroke)
    final topCenter = Offset(rect.center.dx, rect.top);
    fullPath.moveTo(topCenter.dx, topCenter.dy);

    // Top edge (to top-right)
    fullPath.lineTo(rect.right - innerR, rect.top);
    fullPath.arcToPoint(
      Offset(rect.right, rect.top + innerR),
      radius: Radius.circular(innerR),
      clockwise: true,
    );
    // Right edge (to bottom-right)
    fullPath.lineTo(rect.right, rect.bottom - innerR);
    fullPath.arcToPoint(
      Offset(rect.right - innerR, rect.bottom),
      radius: Radius.circular(innerR),
      clockwise: true,
    );
    // Bottom edge (to bottom-left)
    fullPath.lineTo(rect.left + innerR, rect.bottom);
    fullPath.arcToPoint(
      Offset(rect.left, rect.bottom - innerR),
      radius: Radius.circular(innerR),
      clockwise: true,
    );
    // Left edge (to top-left)
    fullPath.lineTo(rect.left, rect.top + innerR);
    fullPath.arcToPoint(
      Offset(rect.left + innerR, rect.top),
      radius: Radius.circular(innerR),
      clockwise: true,
    );
    // Back to top center
    fullPath.lineTo(topCenter.dx, topCenter.dy);

    final pathMetrics = fullPath.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final totalLength = pathMetrics.fold<double>(0.0, (sum, m) => sum + m.length);
    final targetLength = totalLength * progress.clamp(0.0, 1.0);

    double currentLength = 0.0;
    final extractedPath = Path();

    for (final metric in pathMetrics) {
      if (currentLength + metric.length <= targetLength) {
        extractedPath.addPath(
          metric.extractPath(0, metric.length),
          Offset.zero,
        );
        currentLength += metric.length;
      } else {
        final remaining = targetLength - currentLength;
        extractedPath.addPath(
          metric.extractPath(0, remaining),
          Offset.zero,
        );
        break;
      }
    }

    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(covariant RoundedRectProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.outerRadius != outerRadius;
  }
}

class CameraScreen extends StatefulWidget {
  final String? initialType;
  final String? initialPrivacy;
  final String? initialGroupId;
  final String? initialGroupName;
  final List<String>? initialGroupMemberIds;
  final bool lockType;
  final bool lockPrivacy;
  final bool isGroupContribution;

  const CameraScreen({
    super.key,
    this.initialType,
    this.initialPrivacy,
    this.initialGroupId,
    this.initialGroupName,
    this.initialGroupMemberIds,
    this.lockType = false,
    this.lockPrivacy = false,
    this.isGroupContribution = false,
  });

  /// Pre-warms the camera controller in the background so that navigating
  /// to CameraScreen opens the camera preview immediately without any grey screen delay.
  static Future<void> warmUp() => _CameraScreenState.warmUp();

  /// Releases the camera hardware when the app goes into the background.
  static Future<void> disposeSharedCamera() => _CameraScreenState.disposeSharedCamera();

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static List<CameraDescription>? _cachedCameras;
  static CameraController? _sharedController;
  static Future<void>? _sharedInitFuture;
  static int _sharedCameraIndex = 0;
  static double _cachedMinZoom = 1.0;
  static double _cachedMaxZoom = 4.0;

  static Future<void> warmUp() async {
    if (_sharedController != null && _sharedController!.value.isInitialized) {
      try {
        await _sharedController!.resumePreview();
      } catch (_) {}
      return;
    }
    if (_sharedInitFuture != null) {
      return _sharedInitFuture;
    }

    _sharedInitFuture = _doWarmUp();
    try {
      await _sharedInitFuture;
    } finally {
      _sharedInitFuture = null;
    }
  }

  static Future<void> _doWarmUp() async {
    try {
      if (_cachedCameras == null || _cachedCameras!.isEmpty) {
        _cachedCameras = await availableCameras().timeout(
          const Duration(seconds: 4),
          onTimeout: () => <CameraDescription>[],
        );
      }
      final cameras = _cachedCameras ?? [];
      if (cameras.isEmpty) return;

      if (_sharedCameraIndex >= cameras.length) {
        _sharedCameraIndex = 0;
      }

      final camera = cameras[_sharedCameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      _sharedController = controller;

      try {
        _cachedMinZoom = await controller.getMinZoomLevel();
        _cachedMaxZoom = await controller.getMaxZoomLevel();
      } catch (_) {
        _cachedMinZoom = 1.0;
        _cachedMaxZoom = 4.0;
      }
      if (_cachedMinZoom < 1.0) _cachedMinZoom = 1.0;
      if (_cachedMaxZoom > 4.0) _cachedMaxZoom = 4.0;
    } catch (e) {
      debugPrint('Camera warm-up error: $e');
      try {
        await _sharedController?.dispose();
      } catch (_) {}
      _sharedController = null;
    }
  }

  static Future<void> disposeSharedCamera() async {
    final controller = _sharedController;
    _sharedController = null;
    _sharedInitFuture = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing shared camera: $e');
      }
    }
  }

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  ResolutionPreset _currentResolutionPreset = ResolutionPreset.high;

  CameraCaptureMode _captureMode = CameraCaptureMode.photo;

  bool _isCameraReady = false;
  bool _isInitializingCamera = false;
  bool _isPermissionDenied = false;
  bool _hasNoCamera = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  bool _isRecordingVideo = false;
  bool _isStoppingVideo = false;

  Timer? _recordTimer;

  DateTime? _recordStartedAt;

  double _recordProgress = 0.0;

  double _zoomLevel = 1.0;
  double _maxZoom = 2.0;
  double _minZoom = 1.0;
  double _baseZoom = 1.0;

  static const Duration _maxRecordDuration = Duration(milliseconds: 5000);
  static const Color _cameraPreviewFallback = Color(0xFF1C1C1F);

  DateTime? _lastCameraCheck;
  bool _isDisposed = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Reuse pre-warmed camera controller immediately for instant preview!
    if (_sharedController != null && _sharedController!.value.isInitialized) {
      _controller = _sharedController;
      _cameras = _cachedCameras ?? [];
      _cameraIndex = _sharedCameraIndex;
      _minZoom = _cachedMinZoom;
      _maxZoom = _cachedMaxZoom;
      _isCameraReady = true;
      _isInitializingCamera = false;
      _hasNoCamera = false;
      _isPermissionDenied = false;
      _sharedController!.resumePreview().catchError((e) {
        debugPrint('Error resuming preview: $e');
        if (mounted && !_isDisposed) {
          _setupCamera();
        }
      });
    } else {
      _setupCamera();
    }
    unawaited(context.read<CaptureController>().prepareLocation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isDisposed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _disposeCameraController();
      disposeSharedCamera();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrentRoute) return;

      final now = DateTime.now();
      if (_lastCameraCheck != null &&
          now.difference(_lastCameraCheck!).inMilliseconds < 1500) {
        return;
      }
      if (!_isCameraReady || _isPermissionDenied || _controller == null) {
        _setupCamera(isBackgroundRetry: true);
      }

      final capture = context.read<CaptureController>();
      if (capture.selectedLocation == null && !capture.isLoadingLocation) {
        unawaited(capture.prepareLocation());
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _controller = null;
    try {
      _sharedController?.pausePreview();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _closeCaptureFlow() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    _isClosing = true;
    _controller = null;
    try {
      await _sharedController?.pausePreview();
    } catch (_) {}

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.mainShell,
        (route) => false,
      );
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await LocationService.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  Future<void> _setupCamera({bool isBackgroundRetry = false, bool showSpinner = false}) async {
    if (_isDisposed || !mounted) return;
    if (_controller != null && _controller!.value.isInitialized && _isCameraReady) return;
    if (_isInitializingCamera) return;
    _lastCameraCheck = DateTime.now();

    // If pre-warm is already running, wait for it so we don't start duplicate inits
    if (_sharedInitFuture != null) {
      _isInitializingCamera = true;
      try {
        await _sharedInitFuture;
      } catch (_) {}
      if (_isDisposed || !mounted) return;
      if (_sharedController != null && _sharedController!.value.isInitialized) {
        _controller = _sharedController;
        _cameras = _cachedCameras ?? [];
        _cameraIndex = _sharedCameraIndex;
        _minZoom = _cachedMinZoom;
        _maxZoom = _cachedMaxZoom;
        _hasNoCamera = false;
        _isPermissionDenied = false;
        try {
          await _sharedController!.resumePreview();
        } catch (_) {}
        if (mounted && !_isDisposed) {
          setState(() {
            _isCameraReady = true;
            _isInitializingCamera = false;
          });
        }
        return;
      }
    }

    if (!isBackgroundRetry && !_isPermissionDenied && showSpinner) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitializingCamera = true;
          _hasNoCamera = false;
        });
      }
    } else {
      _isInitializingCamera = true;
    }

    try {
      if (_cachedCameras == null || _cachedCameras!.isEmpty) {
        _cachedCameras = await availableCameras().timeout(
          const Duration(seconds: 4),
          onTimeout: () => <CameraDescription>[],
        );
      }
      _cameras = _cachedCameras ?? [];
      if (_isDisposed || !mounted) return;

      if (_cameras.isEmpty) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isCameraReady = false;
            _isPermissionDenied = false;
            _hasNoCamera = true;
            _isInitializingCamera = false;
          });
        }
        return;
      }

      if (_cameraIndex >= _cameras.length) {
        _cameraIndex = 0;
      }

      _hasNoCamera = false;
      await _initController(_cameras[_cameraIndex], isBackgroundRetry: isBackgroundRetry);
    } on CameraException catch (e) {
      debugPrint('Camera setup CameraException: ${e.code} - ${e.description}');
      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraReady = false;
          _isPermissionDenied = true;
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');

      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraReady = false;
          _isPermissionDenied = true;
          _isInitializingCamera = false;
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitializingCamera = false;
        });
      }
    }
  }

  Future<void> _initController(CameraDescription camera, {bool isBackgroundRetry = false}) async {
    final oldController = _controller;
    _controller = null;

    if (oldController != null) {
      try {
        await oldController.dispose();
      } catch (e) {
        debugPrint('Error disposing old controller: $e');
      }
    }

    if (_isDisposed || !mounted) return;

    // Only update UI when coming from a "ready" state (e.g. camera switch).
    // On first open _isCameraReady is already false, so this setState would
    // trigger a rebuild where _isInitializingCamera=true → shows spinner.
    if (mounted && !isBackgroundRetry && !_isDisposed && _isCameraReady) {
      setState(() {
        _isCameraReady = false;
      });
    }

    CameraController? controller;
    try {
      controller = CameraController(
        camera,
        _currentResolutionPreset,
        enableAudio: true,
      );
      await controller.initialize();
    } catch (e) {
      await controller?.dispose();
      controller = null;
      try {
        controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await controller.initialize();
        _currentResolutionPreset = ResolutionPreset.medium;
      } catch (e2) {
        await controller?.dispose();
        controller = null;
        debugPrint('Camera init error: $e2');
      }
    }

    if (_isDisposed || !mounted) {
      await controller?.dispose();
      return;
    }

    if (controller == null) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraReady = false;
          _isPermissionDenied = true;
          _isInitializingCamera = false;
        });
      }
      return;
    }

    _controller = controller;

    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
    } catch (_) {
      _minZoom = 1.0;
      _maxZoom = 4.0;
    }

    if (_minZoom < 1.0) _minZoom = 1.0;
    if (_maxZoom > 4.0) _maxZoom = 4.0;

    _zoomLevel = 1.0;
    _baseZoom = 1.0;
    _isFlashOn = false;

    try {
      await controller.setZoomLevel(_zoomLevel);
    } catch (_) {}

    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {}

    _sharedController = controller;
    _sharedCameraIndex = _cameraIndex;
    _cachedMinZoom = _minZoom;
    _cachedMaxZoom = _maxZoom;

    if (mounted && !_isDisposed) {
      setState(() {
        _isCameraReady = true;
        _isPermissionDenied = false;
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStoppingVideo) {
      return;
    }

    try {
      _isFlashOn = !_isFlashOn;

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _toggleZoom() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStoppingVideo) {
      return;
    }

    try {
      final current = _zoomLevel;

      if (current < 1.5) {
        _zoomLevel = 2.0;
      } else if (current < 2.5) {
        _zoomLevel = 3.0;
      } else if (current < 3.5) {
        _zoomLevel = 4.0;
      } else {
        _zoomLevel = 1.0;
      }

      _zoomLevel = _zoomLevel.clamp(_minZoom, _maxZoom);
      _baseZoom = _zoomLevel;

      await _controller!.setZoomLevel(_zoomLevel);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Zoom error: $e');
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isStoppingVideo) return;

    _baseZoom = _zoomLevel;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStoppingVideo) {
      return;
    }

    try {
      final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);

      if ((newZoom - _zoomLevel).abs() < 0.02) return;

      _zoomLevel = newZoom;

      await _controller!.setZoomLevel(_zoomLevel);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Pinch zoom error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _isCapturing ||
        _isRecordingVideo ||
        _isStoppingVideo ||
        _isInitializingCamera) {
      return;
    }

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    setState(() {
      _isCameraReady = false;
      _isInitializingCamera = true;
      _isPermissionDenied = false;
    });

    await _initController(_cameras[_cameraIndex]);
  }

  bool get _isFrontCamera {
    if (_cameras.isEmpty || _cameraIndex >= _cameras.length) return false;
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  Future<File> _cropImageToSquare(File file, {bool isFrontCamera = false}) async {
    final bytes = await file.readAsBytes();
    var original = img.decodeImage(bytes);

    if (original == null) return file;

    // 1. Chuẩn hóa hướng EXIF để kích thước pixel chính xác
    original = img.bakeOrientation(original);

    // 2. Nếu chụp bằng camera trước, lật ngang ảnh để ảnh chụp ra khớp với ảnh gương hiển thị trên màn hình
    if (isFrontCamera) {
      original = img.copyFlip(original, direction: img.FlipDirection.horizontal);
    }

    final cropSize =
        original.width < original.height ? original.width : original.height;

    final offsetX = (original.width - cropSize) ~/ 2;
    final offsetY = (original.height - cropSize) ~/ 2;

    final cropped = img.copyCrop(
      original,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    await file.writeAsBytes(
      img.encodeJpg(cropped, quality: 85),
      flush: true,
    );

    return file;
  }

  Future<void> _disposeCameraController() async {
    final controller = _controller;
    _controller = null;
    _sharedController = null;
    _sharedInitFuture = null;

    // Don't flash loading UI when we're closing the screen
    if (mounted && !_isClosing) {
      setState(() {
        _isCameraReady = false;
        _isFlashOn = false;
      });
    }

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
  }

  Widget _buildPreviewScreen({
    File? imageFile,
    File? originalImageFile,
    SquareCropState? initialCropState,
    bool isFromGallery = false,
    File? videoFile,
    required String mediaType,
    int? durationMs,
    bool isFrontCamera = false,
  }) {
    return PreviewScreen(
      imageFile: imageFile,
      originalImageFile: originalImageFile,
      initialCropState: initialCropState,
      isFromGallery: isFromGallery,
      videoFile: videoFile,
      mediaType: mediaType,
      durationMs: durationMs,
      initialType: widget.initialType,
      initialPrivacy: widget.initialPrivacy,
      initialGroupId: widget.initialGroupId,
      initialGroupName: widget.initialGroupName,
      initialGroupMemberIds: widget.initialGroupMemberIds,
      lockType: widget.lockType,
      lockPrivacy: widget.lockPrivacy,
      isGroupContribution: widget.isGroupContribution,
      isFrontCamera: isFrontCamera,
    );
  }

  void _handlePreviewResult(dynamic result) {
    if (!mounted || _isDisposed) return;

    if (result == true || result == 'close') {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, result);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.mainShell,
          (route) => false,
        );
      }
      return;
    }

    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrentRoute) return;

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        _controller!.resumePreview();
      } catch (_) {
        _setupCamera(showSpinner: false);
      }
    } else {
      _setupCamera(showSpinner: false);
    }
  }

  Future<void> _navigateToPreview(Widget previewScreen) async {
    if (!mounted || _isDisposed) return;

    try {
      await _controller?.pausePreview();
    } catch (_) {}

    if (!mounted || _isDisposed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => previewScreen,
      ),
    );

    _handlePreviewResult(result);
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    try {
      await _controller?.pausePreview();
    } catch (_) {}

    if (!mounted || _isDisposed) return;

    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
      );

      if (file == null || !mounted || _isDisposed) {
        try {
          await _controller?.resumePreview();
        } catch (_) {}
        return;
      }

      final originalFile = File(file.path);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (cropContext) => SquareCropScreen(
            imageFile: originalFile,
            onConfirmNavigate: (innerContext, croppedFile, state) async {
              final result = await Navigator.pushReplacement(
                innerContext,
                MaterialPageRoute(
                  builder: (_) => _buildPreviewScreen(
                    imageFile: croppedFile,
                    originalImageFile: originalFile,
                    initialCropState: state,
                    isFromGallery: true,
                    videoFile: null,
                    mediaType: 'image',
                    durationMs: null,
                  ),
                ),
              );
              _handlePreviewResult(result);
            },
          ),
        ),
      );

      // In case user cancelled within SquareCropScreen and popped back to CameraScreen
      if (mounted && !_isDisposed) {
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (isCurrentRoute) {
          if (_controller != null && _controller!.value.isInitialized) {
            try {
              await _controller!.resumePreview();
            } catch (_) {
              _setupCamera(showSpinner: false);
            }
          } else {
            _setupCamera(showSpinner: false);
          }
        }
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing ||
        _isRecordingVideo ||
        _isStoppingVideo) {
      return;
    }

    try {
      HapticFeedback.selectionClick();
      setState(() {
        _isCapturing = true;
      });

      final isFront = _isFrontCamera;
      final file = await _controller!.takePicture();
      final squareFile = await _cropImageToSquare(
        File(file.path),
        isFrontCamera: isFront,
      );

      if (!mounted) return;

      await _navigateToPreview(
        _buildPreviewScreen(
          imageFile: squareFile,
          videoFile: null,
          mediaType: 'image',
          durationMs: null,
        ),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo ||
        _isCapturing ||
        _isStoppingVideo) {
      return;
    }

    try {
      HapticFeedback.heavyImpact();
      // Pre-warm the MediaRecorder so the first video keyframe arrives immediately.
      // Without this, Android buffers audio while waiting for the first keyframe,
      // which can cause the first ~0.5s of video to be silently dropped.
      try {
        await _controller!.prepareForVideoRecording();
      } catch (_) {}
      await _controller!.startVideoRecording();

      // Android's MediaRecorder needs ~300–400ms after start() to emit the
      // first IDR keyframe and begin muxing. Delaying _recordStartedAt syncs
      // the progress timer with the actual video content start so the recorded
      // video and the displayed progress are aligned.
      await Future.delayed(const Duration(milliseconds: 350));
      if (_isDisposed || !mounted) return;

      _recordStartedAt = DateTime.now();

      setState(() {
        _isRecordingVideo = true;
        _recordProgress = 0.0;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(
        const Duration(milliseconds: 30),
        (_) {
          if (!_isRecordingVideo || _recordStartedAt == null) return;

          final elapsed = DateTime.now().difference(_recordStartedAt!);
          final progress =
              elapsed.inMilliseconds / _maxRecordDuration.inMilliseconds;

          if (!mounted) return;

          setState(() {
            _recordProgress = progress.clamp(0.0, 1.0);
          });

          if (elapsed >= _maxRecordDuration) {
            _stopVideoRecording();
          }
        },
      );
    } catch (e) {
      debugPrint('Start video error: $e');

      if (mounted) {
        setState(() {
          _isRecordingVideo = false;
          _isStoppingVideo = false;
          _recordStartedAt = null;
          _recordProgress = 0.0;
        });
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_controller!.value.isRecordingVideo ||
        _isStoppingVideo) {
      return;
    }

    final startedAt = _recordStartedAt;

    try {
      _isStoppingVideo = true;
      _recordTimer?.cancel();

      final isFront = _isFrontCamera;
      final file = await _controller!.stopVideoRecording();

      final durationMs = startedAt == null
          ? null
          : DateTime.now().difference(startedAt).inMilliseconds;

      File finalVideoFile = File(file.path);

      // Check if video file size > 6MB -> Compress using LightCompressor
      if (await finalVideoFile.exists()) {
        final fileSize = await finalVideoFile.length();
        final sizeMb = fileSize / (1024 * 1024);
        if (sizeMb > 6.0) {
          debugPrint('Video size is ${sizeMb.toStringAsFixed(2)}MB (> 6MB), compressing...');
          try {
            final compressor = LightCompressor();
            final result = await compressor.compressVideo(
              path: finalVideoFile.path,
              videoQuality: VideoQuality.medium,
              isMinBitrateCheckEnabled: false,
              video: Video(videoName: 'meme_vid_${DateTime.now().millisecondsSinceEpoch}.mp4'),
              android: AndroidConfig(isSharedStorage: false),
              ios: IOSConfig(saveInGallery: false),
            );

            if (result is OnSuccess) {
              final compressed = File(result.destinationPath);
              if (await compressed.exists()) {
                finalVideoFile = compressed;
                debugPrint('Video compressed successfully to ${(await compressed.length()) / (1024 * 1024)}MB');
              }
            }
          } catch (compErr) {
            debugPrint('Video compression error: $compErr');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _isRecordingVideo = false;
        _isStoppingVideo = false;
        _recordStartedAt = null;
        _recordProgress = 0.0;
      });

      await _navigateToPreview(
        _buildPreviewScreen(
          imageFile: null,
          videoFile: finalVideoFile,
          mediaType: 'video',
          durationMs: durationMs,
          isFrontCamera: isFront,
        ),
      );
    } catch (e) {
      debugPrint('Stop video error: $e');

      if (mounted) {
        setState(() {
          _isRecordingVideo = false;
          _isStoppingVideo = false;
          _recordStartedAt = null;
          _recordProgress = 0.0;
        });
      }
    }
  }

  void _handleShutterDown() {
    if (_isCapturing || _isStoppingVideo) return;

    if (_captureMode == CameraCaptureMode.video) {
      _startVideoRecording();
    }
  }

  Future<void> _handleShutterUp() async {
    if (_captureMode == CameraCaptureMode.video) {
      if (_isRecordingVideo) {
        final startedAt = _recordStartedAt;
        if (startedAt != null) {
          final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
          if (elapsedMs < 300) {
            await Future.delayed(Duration(milliseconds: 300 - elapsedMs));
          }
        }
        await _stopVideoRecording();
      }
      return;
    }

    // Photo mode: Instant capture on tap
    await _capturePhoto();
  }

  Future<void> _handleShutterCancel() async {
    if (_captureMode == CameraCaptureMode.video && _isRecordingVideo) {
      await _stopVideoRecording();
    }
  }

  Future<void> _skipToPreview() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    await _navigateToPreview(
      _buildPreviewScreen(
        imageFile: null,
        videoFile: null,
        mediaType: 'none',
        durationMs: null,
      ),
    );
  }

  String get _zoomText {
    if ((_zoomLevel - _zoomLevel.roundToDouble()).abs() < 0.05) {
      return '${_zoomLevel.toStringAsFixed(0)}x';
    }

    return '${_zoomLevel.toStringAsFixed(1)}x';
  }

  Widget _circleGlassButton({
    required Widget child,
    required VoidCallback onTap,
    double size = 58,
    bool square = false,
    Color? bgColor,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        square ? AppSizes.radiusMedium : AppSizes.radiusPill,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius:
              square ? BorderRadius.circular(AppSizes.radiusMedium) : null,
          color: bgColor ?? Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }

  Widget _buildSquareCameraPreview(double previewSize, CameraThemeData theme) {
    if (!_isCameraReady ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      if (_isPermissionDenied || _hasNoCamera) {
        final message = _hasNoCamera
            ? context.l10n.noCameraAvailable
            : context.l10n.cameraPermissionRequired;

        return Container(
          width: previewSize,
          height: previewSize,
          decoration: BoxDecoration(
            color: _cameraPreviewFallback,
            borderRadius: BorderRadius.circular(38),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFF48484A),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _cameraPreviewFallback,
                              width: 2.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (!_hasNoCamera) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _openAppSettings,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333336),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.openSettings,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      return Container(
        width: previewSize,
        height: previewSize,
        decoration: BoxDecoration(
          color: _cameraPreviewFallback,
          borderRadius: BorderRadius.circular(56),
        ),
        child: Center(
          // Never show a spinner during background init — CaptureController's
          // notifyListeners() (location load) triggers rebuilds while
          // _isInitializingCamera=true, which would flash the spinner.
          // The dark box is shown silently; camera preview appears when ready.
          child: !_isInitializingCamera
              ? IconButton(
                  onPressed: () => _setupCamera(showSpinner: true),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : const SizedBox(),
        ),
      );
    }

    final controller = _controller!;
    final preview = controller.value.previewSize;

    if (preview == null) {
      return Container(
        width: previewSize,
        height: previewSize,
        decoration: BoxDecoration(
          color: _cameraPreviewFallback,
          borderRadius: BorderRadius.circular(38),
        ),
      );
    }

    final hasGradientFrame = theme.frameGradient != null;
    const double frameBorderRadius = 48.0;

    // Wrap in a Stack so the progress CustomPaint renders at full previewSize
    // dimensions (matching the outer border radius), not inside the 2.5px padding.
    return Stack(
      children: [
        Container(
          width: previewSize,
          height: previewSize,
          padding: hasGradientFrame ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(frameBorderRadius),
            gradient: hasGradientFrame ? theme.frameGradient : null,
            border: hasGradientFrame
                ? null
                : Border.all(
                    color: theme.frameBorderColor.withValues(alpha: 0.65),
                    width: 2.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: theme.frameBorderColor.withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(frameBorderRadius - 2.5),
                child: GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: preview.height,
                            height: preview.width,
                            child: CameraPreview(controller),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 12,
                        top: 12,
                        child: _circleGlassButton(
                          onTap: _toggleFlash,
                          size: 44,
                          bgColor: theme.glassButtonBg,
                          borderColor: theme.glassButtonBorder,
                          child: Icon(
                            _isFlashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),

                      Positioned(
                        right: 12,
                        top: 12,
                        child: _circleGlassButton(
                          onTap: _toggleZoom,
                          size: 44,
                          bgColor: theme.glassButtonBg,
                          borderColor: theme.glassButtonBorder,
                          child: Text(
                            _zoomText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      // Pill Mode Switcher INSIDE the camera preview at the bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Center(
                          child: _buildModeSwitcher(theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress CustomPaint is OUTSIDE the padded container so it renders
        // at the full previewSize × previewSize canvas and outerRadius=48 aligns
        // exactly with the outer frame border — no gap at the corner arcs.
        if (_isRecordingVideo && _recordProgress > 0)
          Positioned.fill(
            child: CustomPaint(
              painter: RoundedRectProgressPainter(
                progress: _recordProgress,
                strokeWidth: 4.5,
                strokeColor: theme.shutterAccent,
                outerRadius: frameBorderRadius,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeSwitcher(CameraThemeData theme) {
    final activeColor = theme.shutterAccent;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: theme.glassButtonBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo mode button
          GestureDetector(
            onTap: () {
              if (_isRecordingVideo || _isStoppingVideo) return;
              HapticFeedback.selectionClick();
              setState(() {
                _captureMode = CameraCaptureMode.photo;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _captureMode == CameraCaptureMode.photo
                    ? activeColor
                    : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: _captureMode == CameraCaptureMode.photo
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Video mode button
          GestureDetector(
            onTap: () {
              if (_isRecordingVideo || _isStoppingVideo) return;
              HapticFeedback.selectionClick();
              setState(() {
                _captureMode = CameraCaptureMode.video;
              });
              // Proactively warm up the MediaRecorder when switching to video
              // mode so the codec is ready before the user presses record.
              final ctrl = _controller;
              if (ctrl != null && ctrl.value.isInitialized) {
                ctrl.prepareForVideoRecording().catchError((_) {});
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _captureMode == CameraCaptureMode.video
                    ? activeColor
                    : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  Icons.videocam_rounded,
                  size: 20,
                  color: _captureMode == CameraCaptureMode.video
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton(CameraThemeData theme) {
    final isEnabled = _isCameraReady && !_isCapturing && !_isStoppingVideo;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled ? (_) => _handleShutterDown() : null,
      onTapUp: isEnabled ? (_) => _handleShutterUp() : null,
      onTapCancel: isEnabled ? _handleShutterCancel : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _isStoppingVideo
            ? 0.7
            : _isCameraReady
                ? 1.0
                : 0.55,
        child: SizedBox(
          width: 94,
          height: 94,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isCameraReady
                        ? theme.shutterAccent.withValues(alpha: 0.4)
                        : const Color(0xFF3A4D43).withValues(alpha: 0.4),
                    width: 5,
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: (_isCapturing || _isRecordingVideo) ? 66 : 74,
                height: (_isCapturing || _isRecordingVideo) ? 66 : 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCameraReady
                      ? Colors.white
                      : const Color(0xFF7A8882),
                  border: Border.all(
                    color: _isCameraReady
                        ? Colors.white
                        : const Color(0xFF5A6661),
                    width: 4,
                  ),
                  boxShadow: [
                    if (_isCapturing || _isRecordingVideo)
                      BoxShadow(
                        color: theme.shutterAccent.withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: _isStoppingVideo
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black87,
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final isShort = screenHeight < 720;
    final isSmall = screenWidth < 370;

    final maxPreviewHeight = screenHeight - (isShort ? 230 : 270);
    final previewSize = screenWidth.clamp(220.0, maxPreviewHeight);

    final currentStreak = context.watch<HomeController>().profile?.currentStreak ??
        context.watch<ProfileController>().user?.currentStreak ??
        0;
    final cameraThemeId = context.watch<ProfileController>().cameraTheme;
    final effectiveThemeId = (currentStreak >= 3) ? cameraThemeId : 'classic_dark';
    final theme = CameraThemes.fromId(effectiveThemeId);

    final sideButtonSize = isSmall ? 54.0 : 62.0;
    final sideIconSize = isSmall ? 24.0 : 28.0;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          gradient: theme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, 8, isSmall ? 12 : 16, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _closeCaptureFlow,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 10 : 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.surfaceColor.withValues(alpha: 0.7),
                          border: Border.all(
                            color: theme.glassButtonBorder,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: isSmall ? 20 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSquareCameraPreview(previewSize, theme),

                      SizedBox(height: isShort ? 16 : 24),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 34),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _circleGlassButton(
                              onTap: _pickFromGallery,
                              square: true,
                              size: sideButtonSize,
                              bgColor: theme.glassButtonBg,
                              borderColor: theme.glassButtonBorder,
                              child: Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white,
                                size: sideIconSize,
                              ),
                            ),

                            _buildShutterButton(theme),

                            Opacity(
                              opacity: (_isCameraReady && _cameras.length >= 2)
                                  ? 1.0
                                  : 0.35,
                              child: _circleGlassButton(
                                onTap: (_isCameraReady && _cameras.length >= 2)
                                    ? _switchCamera
                                    : () {},
                                size: sideButtonSize,
                                bgColor: theme.glassButtonBg,
                                borderColor: theme.glassButtonBorder,
                                child: Icon(
                                  Icons.sync_rounded,
                                  color: Colors.white,
                                  size: sideIconSize + 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextButton(
                          onPressed: _skipToPreview,
                          child: Text(
                            context.l10n.skipPhoto,
                            style: AppTextStyles.bodySecondary(context).copyWith(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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