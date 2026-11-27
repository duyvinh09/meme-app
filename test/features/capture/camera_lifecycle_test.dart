import 'dart:async';

// Test the native API already supplied by camera, without another dependency.
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:meme_app/core/routes/app_routes.dart';
import 'package:meme_app/features/capture/controllers/capture_controller.dart';
import 'package:meme_app/features/capture/screens/camera_screen.dart';
import 'package:meme_app/features/home/controllers/home_controller.dart';
import 'package:meme_app/features/profile/controllers/profile_controller.dart';
import 'package:meme_app/l10n/generated/app_localizations.dart';

class FakeCapture extends ChangeNotifier implements CaptureController {
  @override
  Future<void> prepareLocation() async {}
  @override
  bool get isLoadingLocation => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHome extends ChangeNotifier implements HomeController {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeProfile extends ChangeNotifier implements ProfileController {
  @override
  String get cameraTheme => 'classic_dark';
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeCamera extends CameraPlatform {
  int created = 0;
  final disposed = <int>[];
  Completer<void>? initializationGate;
  final initialized = StreamController<CameraInitializedEvent>.broadcast();
  final errors = StreamController<CameraErrorEvent>.broadcast();
  @override
  Future<List<CameraDescription>> availableCameras() async => [
        const CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90),
      ];
  @override
  Future<int> createCameraWithSettings(
          CameraDescription camera, MediaSettings settings) async =>
      ++created;
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      errors.stream.where((event) => event.cameraId == cameraId);
  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      initialized.stream.where((event) => event.cameraId == cameraId);
  @override
  Future<void> initializeCamera(int cameraId,
      {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {
    if (initializationGate != null) await initializationGate!.future;
    initialized.add(CameraInitializedEvent(
        cameraId, 480, 640, ExposureMode.auto, true, FocusMode.auto, true));
  }

  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1;
  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 4;
  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {}
  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}
  @override
  Future<void> dispose(int cameraId) async {
    disposed.add(cameraId);
    errors.add(CameraErrorEvent(cameraId, 'disposed'));
  }

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.black);
}

void main() {
  late CameraPlatform original;
  late FakeCamera camera;
  final navigator = GlobalKey<NavigatorState>();
  setUp(() {
    original = CameraPlatform.instance;
    camera = FakeCamera();
    CameraPlatform.instance = camera;
  });
  tearDown(() async {
    CameraPlatform.instance = original;
    await camera.initialized.close();
    await camera.errors.close();
  });
  Future<void> mount(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<CaptureController>(
              create: (_) => FakeCapture()),
          ChangeNotifierProvider<HomeController>(create: (_) => FakeHome()),
          ChangeNotifierProvider<ProfileController>(
              create: (_) => FakeProfile()),
        ],
        child: MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [AppRoutes.routeObserver],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Text('Home')))));
  }

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Camera opens only on capture, releases on preview and home',
      (tester) async {
    await mount(tester);
    expect(camera.created, 0);
    unawaited(navigator.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => const CameraScreen())));
    await flush(tester);
    expect(camera.created, 1);
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Preview')))));
    await flush(tester);
    expect(camera.disposed, [1]);
    navigator.currentState!.pop();
    await flush(tester);
    expect(camera.created, 2);
    navigator.currentState!.pop();
    await flush(tester);
    expect(camera.disposed, [1, 2]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
  });
  testWidgets('Pending initialization is disposed when capture is closed',
      (tester) async {
    camera.initializationGate = Completer<void>();
    await mount(tester);
    unawaited(navigator.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => const CameraScreen())));
    await flush(tester);
    expect(camera.created, 1);
    navigator.currentState!.pop();
    await flush(tester);
    camera.initializationGate!.complete();
    await flush(tester);
    expect(camera.disposed, [1]);
    expect(camera.created, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
  });
  testWidgets('Background releases camera and resume only reopens on capture',
      (tester) async {
    await mount(tester);
    unawaited(navigator.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => const CameraScreen())));
    await flush(tester);
    expect(camera.created, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await flush(tester);
    expect(camera.disposed, [1]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    expect(camera.created, 2);
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Preview')))));
    await flush(tester);
    expect(camera.disposed, [1, 2]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    expect(camera.created, 2);
    navigator.currentState!.pop();
    await flush(tester);
    expect(camera.created, 3);
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
    expect(camera.disposed, [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });
}
