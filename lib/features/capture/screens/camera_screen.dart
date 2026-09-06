import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  ResolutionPreset _currentResolutionPreset = ResolutionPreset.high;

  bool _isCameraReady = false;
  bool _isInitializingCamera = false;
  bool _isPermissionDenied = false;
  bool _hasNoCamera = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  bool _isRecordingVideo = false;
  bool _isStoppingVideo = false;

  Timer? _recordTimer;
  Timer? _holdStartTimer;

  DateTime? _recordStartedAt;

  double _recordProgress = 0.0;

  bool _didStartRecordingFromHold = false;

  double _zoomLevel = 1.0;
  double _maxZoom = 2.0;
  double _minZoom = 1.0;
  double _baseZoom = 1.0;

  static const Duration _maxRecordDuration = Duration(seconds: 5);
  static const Color _cameraPreviewFallback = Color(0xFF1C1C1F);

  DateTime? _lastCameraCheck;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
    context.read<CaptureController>().prepareLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isDisposed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _disposeCameraController();
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
        capture.prepareLocation();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _holdStartTimer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _closeCaptureFlow() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    await _disposeCameraController();
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

  Future<void> _handleLocationBadgeTap() async {
    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showEnableGpsDialog();
      return;
    }

    final hasPermission = await LocationService.hasLocationPermission();
    if (!hasPermission) {
      final loc = await LocationService.getCurrentLocation(
        requestPermissionIfNeeded: true,
      );
      if (loc == null && !hasPermission) {
        if (!mounted) return;
        _showEnableLocationPermissionDialog();
        return;
      }
    }

    if (mounted) {
      await context.read<CaptureController>().prepareLocation();
    }
  }

  void _showEnableGpsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          backgroundColor: AppColors.card(context),
          title: Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Bật định vị (GPS)',
                style: AppTextStyles.cardTitle(context),
              ),
            ],
          ),
          content: Text(
            'Dịch vụ định vị (GPS) trên điện thoại đang tắt. Vui lòng bật GPS để ứng dụng tự động gắn vị trí vào ảnh chụp.',
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Để sau',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                LocationService.openLocationSettings();
              },
              child: const Text('Mở Cài đặt GPS'),
            ),
          ],
        );
      },
    );
  }

  void _showEnableLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          backgroundColor: AppColors.card(context),
          title: Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Quyền vị trí',
                style: AppTextStyles.cardTitle(context),
              ),
            ],
          ),
          content: Text(
            'Ứng dụng cần quyền vị trí để tự động gắn địa điểm vào giao dịch. Vui lòng cấp quyền trong Cài đặt ứng dụng.',
            style: AppTextStyles.body(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Để sau',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                LocationService.openAppSettings();
              },
              child: const Text('Mở Cài đặt ứng dụng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppSettings() async {
    try {
      await LocationService.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  Future<void> _setupCamera({bool isBackgroundRetry = false}) async {
    if (_isDisposed || !mounted) return;
    if (_isInitializingCamera) return;
    _lastCameraCheck = DateTime.now();

    if (!isBackgroundRetry && !_isPermissionDenied) {
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
      _cameras = await availableCameras();
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

    if (mounted && !isBackgroundRetry && !_isDisposed) {
      setState(() {
        _isCameraReady = false;
      });
    }

    CameraController? controller;
    try {
      controller = CameraController(
        camera,
        _currentResolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
    } catch (e) {
      await controller?.dispose();
      controller = null;
      try {
        controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
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
        _isRecordingVideo ||
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
        _isRecordingVideo ||
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
    if (_isRecordingVideo || _isStoppingVideo) return;

    _baseZoom = _zoomLevel;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecordingVideo ||
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

  Future<File> _cropImageToSquare(File file) async {
    final bytes = await file.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) return file;

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
      img.encodeJpg(cropped, quality: 98),
      flush: true,
    );

    return file;
  }

  Future<void> _disposeCameraController() async {
    final controller = _controller;
    _controller = null;

    if (mounted) {
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

  Future<void> _navigateToPreview(Widget previewScreen) async {
    await _disposeCameraController();
    if (!mounted || _isDisposed) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => previewScreen,
      ),
    );

    if (!mounted || _isDisposed) return;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrentRoute) return;

    _setupCamera();
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    try {
      await _disposeCameraController();
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
      );

      if (file == null || !mounted || _isDisposed) {
        if (mounted && !_isDisposed && (ModalRoute.of(context)?.isCurrent ?? false)) {
          _setupCamera();
        }
        return;
      }

      final squareFile = await _cropImageToSquare(File(file.path));

      if (!mounted || _isDisposed) return;

      await _navigateToPreview(
        PreviewScreen(
          imageFile: squareFile,
          videoFile: null,
          mediaType: 'image',
          durationMs: null,
        ),
      );
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      if (mounted) {
        _setupCamera();
      }
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
      setState(() {
        _isCapturing = true;
      });

      final file = await _controller!.takePicture();
      final squareFile = await _cropImageToSquare(File(file.path));

      if (!mounted) return;

      await _navigateToPreview(
        PreviewScreen(
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
      await _controller!.startVideoRecording();

      _recordStartedAt = DateTime.now();

      setState(() {
        _isRecordingVideo = true;
        _recordProgress = 0.0;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(
        const Duration(milliseconds: 40),
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

      final file = await _controller!.stopVideoRecording();

      final durationMs = startedAt == null
          ? null
          : DateTime.now().difference(startedAt).inMilliseconds;

      if (!mounted) return;

      setState(() {
        _isRecordingVideo = false;
        _isStoppingVideo = false;
        _recordStartedAt = null;
        _recordProgress = 0.0;
      });

      await _navigateToPreview(
        PreviewScreen(
          imageFile: null,
          videoFile: File(file.path),
          mediaType: 'video',
          durationMs: durationMs,
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
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    _didStartRecordingFromHold = false;
    _holdStartTimer?.cancel();

    _holdStartTimer = Timer(
      const Duration(milliseconds: 200),
          () async {
        if (!mounted) return;
        if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

        _didStartRecordingFromHold = true;
        await _startVideoRecording();
      },
    );
  }

  Future<void> _handleShutterUp() async {
    _holdStartTimer?.cancel();

    if (_isRecordingVideo) {
      final startedAt = _recordStartedAt;

      if (startedAt != null) {
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;

        if (elapsedMs < 300) {
          await Future.delayed(Duration(milliseconds: 300 - elapsedMs));
        }
      }

      await _stopVideoRecording();
      return;
    }

    if (_didStartRecordingFromHold) return;

    await _capturePhoto();
  }

  Future<void> _handleShutterCancel() async {
    _holdStartTimer?.cancel();
  }

  Future<void> _skipToPreview() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    await _navigateToPreview(
      const PreviewScreen(
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

  Widget _buildLocationStatus() {
    return Consumer<CaptureController>(
      builder: (context, capture, _) {
        if (capture.isLoadingLocation) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.gettingLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        if (capture.selectedLocation != null) {
          final name = capture.selectedLocation!.locationName.trim();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.white.withOpacity(0.74),
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name.isNotEmpty ? name : context.l10n.currentLocationSaved,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              color: Colors.white.withOpacity(0.45),
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              context.l10n.noLocation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
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
                          color: Colors.white.withOpacity(0.12),
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
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
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

    return Container(
      width: previewSize,
      height: previewSize,
      padding: hasGradientFrame ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(56),
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
            borderRadius: BorderRadius.circular(53.5),
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

                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Center(
                      child: GestureDetector(
                        onTap: _handleLocationBadgeTap,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 260,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill,
                              ),
                              border: Border.all(
                                color: theme.glassButtonBorder,
                              ),
                            ),
                            child: _buildLocationStatus(),
                          ),
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
              SizedBox(
                width: 94,
                height: 94,
                child: CircularProgressIndicator(
                  value: _isCapturing
                      ? null
                      : _isRecordingVideo
                          ? _recordProgress
                          : 0,
                  strokeWidth: 6,
                  backgroundColor: _isCameraReady
                      ? Colors.white.withValues(alpha: 0.20)
                      : const Color(0xFF3A4D43).withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isRecordingVideo
                        ? Colors.redAccent
                        : theme.shutterAccent,
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: _isRecordingVideo ? 62 : 74,
                height: _isRecordingVideo ? 62 : 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecordingVideo
                      ? Colors.redAccent
                      : _isCameraReady
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
                        color: (_isRecordingVideo
                                ? Colors.redAccent
                                : theme.shutterAccent)
                            .withValues(alpha: 0.45),
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
                            color: Colors.white,
                          ),
                        )
                      : _isRecordingVideo
                          ? const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 32,
                            )
                          : _isCapturing
                              ? Icon(
                                  Icons.camera_alt_rounded,
                                  color: theme.backgroundColor,
                                  size: 28,
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

                      SizedBox(height: isShort ? 12 : 18),

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
                                  Icons.cameraswitch_rounded,
                                  color: Colors.white,
                                  size: sideIconSize + 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.only(top: 30),
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