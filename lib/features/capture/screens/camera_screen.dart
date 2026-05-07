import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../controllers/capture_controller.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  ResolutionPreset _currentResolutionPreset = ResolutionPreset.veryHigh;

  bool _isCameraReady = false;
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

  static const Color _cameraBackground = Color(0xFF15171C);
  static const Color _cameraSurface = Color(0xFF232833);
  static const Color _cameraPreviewFallback = Color(0xFF1C1C1F);
  static const Color _shutterAccent = Color(0xFF6DFF8A);

  @override
  void initState() {
    super.initState();
    _setupCameraThenPrepareLocation();
  }

  Future<void> _setupCameraThenPrepareLocation() async {
    await _setupCamera();

    if (!mounted) return;
    await context.read<CaptureController>().prepareLocation();
  }

  void _closeCaptureFlow() {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.mainShell,
          (route) => false,
    );
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraReady = false;
          });
        }
        return;
      }

      await _initController(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('Camera setup error: $e');

      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    final oldController = _controller;

    if (oldController != null) {
      await oldController.dispose();
    }

    if (mounted) {
      setState(() {
        _isCameraReady = false;
      });
    }

    final controller = CameraController(
      camera,
      _currentResolutionPreset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();

      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();

      if (_minZoom < 1.0) _minZoom = 1.0;
      if (_maxZoom > 4.0) _maxZoom = 4.0;

      _zoomLevel = 1.0;
      _baseZoom = 1.0;
      _isFlashOn = false;

      await controller.setZoomLevel(_zoomLevel);
      await controller.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');

      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _switchResolutionPreset(
      ResolutionPreset preset,
      ) async {
    if (_currentResolutionPreset == preset) return;
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;
    if (_cameras.isEmpty) return;

    _currentResolutionPreset = preset;

    await _initController(_cameras[_cameraIndex]);
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
        _isStoppingVideo) {
      return;
    }

    _cameraIndex = _cameraIndex == 0 ? 1 : 0;

    setState(() {
      _isCameraReady = false;
      _isFlashOn = false;
      _zoomLevel = 1.0;
      _baseZoom = 1.0;
    });

    _currentResolutionPreset = ResolutionPreset.veryHigh;
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

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 98,
      );

      if (file == null || !mounted) return;

      final squareFile = await _cropImageToSquare(File(file.path));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageFile: squareFile,
            videoFile: null,
            mediaType: 'image',
            durationMs: null,
          ),
        ),
      );
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

    if (_currentResolutionPreset != ResolutionPreset.veryHigh) {
      await _switchResolutionPreset(ResolutionPreset.veryHigh);
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final file = await _controller!.takePicture();
      final squareFile = await _cropImageToSquare(File(file.path));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageFile: squareFile,
            videoFile: null,
            mediaType: 'image',
            durationMs: null,
          ),
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

    if (_currentResolutionPreset != ResolutionPreset.medium) {
      await _switchResolutionPreset(ResolutionPreset.medium);
    }

    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isRecordingVideo) {
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageFile: null,
            videoFile: File(file.path),
            mediaType: 'video',
            durationMs: durationMs,
          ),
        ),
      ).then((_) async {
        if (!mounted) return;

        if (_currentResolutionPreset != ResolutionPreset.veryHigh) {
          await _switchResolutionPreset(ResolutionPreset.veryHigh);
        }
      });
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
      const Duration(milliseconds: 180),
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

        if (elapsedMs < 250) {
          await Future.delayed(Duration(milliseconds: 250 - elapsedMs));
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

  void _skipToPreview() {
    if (_isCapturing || _isRecordingVideo || _isStoppingVideo) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PreviewScreen(
          imageFile: null,
          videoFile: null,
          mediaType: 'none',
          durationMs: null,
        ),
      ),
    );
  }

  String get _zoomText {
    if ((_zoomLevel - _zoomLevel.roundToDouble()).abs() < 0.05) {
      return '${_zoomLevel.toStringAsFixed(0)}x';
    }

    return '${_zoomLevel.toStringAsFixed(1)}x';
  }

  @override
  void dispose() {
    _holdStartTimer?.cancel();
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Widget _circleGlassButton({
    required Widget child,
    required VoidCallback onTap,
    double size = 58,
    bool square = false,
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
          color: Colors.white.withOpacity(0.06),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
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
                'Đang lấy vị trí...',
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
                  name.isNotEmpty ? name : 'Đã lưu vị trí hiện tại',
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
              'Chưa có vị trí',
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

  Widget _buildSquareCameraPreview(double previewSize) {
    if (!_isCameraReady || _controller == null) {
      return Container(
        width: previewSize,
        height: previewSize,
        decoration: BoxDecoration(
          color: _cameraPreviewFallback,
          borderRadius: BorderRadius.circular(38),
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

    return SizedBox(
      width: previewSize,
      height: previewSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(38),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 260,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: _buildLocationStatus(),
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

  Widget _buildShutterButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleShutterDown(),
      onTapUp: (_) => _handleShutterUp(),
      onTapCancel: _handleShutterCancel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _isStoppingVideo ? 0.7 : 1,
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
                  // Chụp ảnh: vòng ngoài xoay.
                  // Quay video: vòng ngoài chạy theo tiến trình.
                  // Bình thường: không hiện tiến trình.
                  value: _isCapturing
                      ? null
                      : _isRecordingVideo
                      ? _recordProgress
                      : 0,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.20),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isRecordingVideo
                        ? Colors.redAccent
                        : _isCapturing
                        ? _shutterAccent
                        : _shutterAccent,
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
                  color: _isRecordingVideo ? Colors.redAccent : Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    if (_isCapturing || _isRecordingVideo)
                      BoxShadow(
                        color: (_isRecordingVideo
                            ? Colors.redAccent
                            : _shutterAccent)
                            .withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
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
                    color: _cameraBackground,
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
    final previewSize = MediaQuery.of(context).size.width - 28;

    return Scaffold(
      backgroundColor: _cameraBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: _closeCaptureFlow,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusPill,
                        ),
                        color: _cameraSurface.withOpacity(0.55),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Text(
                        'Huỷ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
                    _buildSquareCameraPreview(previewSize),

                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleGlassButton(
                            onTap: _pickFromGallery,
                            square: true,
                            size: 62,
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          _buildShutterButton(),

                          _circleGlassButton(
                            onTap: _switchCamera,
                            size: 62,
                            child: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                              size: 30,
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
                          'Bỏ qua ảnh',
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
    );
  }
}