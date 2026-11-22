import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/constants/avatar_frames.dart';
import 'package:meme_app/features/profile/widgets/avatar_with_frame.dart';

void main() {
  testWidgets('AvatarWithFrame_TightParent_FitsAndKeepsFullTapArea', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 32,
            child: AvatarWithFrame(
              avatarUrl: '',
              frameId: 'phoenix',
              size: 100,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    final bounds = tester.getRect(find.byType(AvatarWithFrame));
    expect(bounds.size, const Size(32, 32));
    await tester.tapAt(bounds.topLeft + const Offset(1, 1));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AvatarWithFrame_AllFrames_KeepPhotoSizeAndLimitProtrusion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final frame in AvatarFrames.all) {
      for (final size in [24.0, 54.0, 100.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                child: SizedBox.square(
                  dimension: 200,
                  child: Center(
                    child: AvatarWithFrame(
                      avatarUrl: '',
                      frameId: frame.id,
                      size: size,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final avatarBounds = tester.getRect(find.byType(AvatarWithFrame));
        final photoBounds = tester.getRect(find.byType(CircleAvatar));
        expect(photoBounds.width, greaterThanOrEqualTo(size - 12));
        expect(photoBounds.center, avatarBounds.center);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).last,
        );
        final snapshot = (await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        ))!;
        try {
          final pixels = await tester.runAsync(
            () => snapshot.toByteData(format: ui.ImageByteFormat.rawRgba),
          );
          // Allow small ornaments beyond the circle, capped at ten pixels.
          final margin = (size * 0.16).clamp(4.0, 10.0);
          final start = ((200 - size) / 2 - margin).floor();
          final end = ((200 + size) / 2 + margin).ceil();
          var escapedPixels = 0;
          for (var y = 0; y < 200; y++) {
            for (var x = 0; x < 200; x++) {
              if (x >= start && x < end && y >= start && y < end) {
                continue;
              }
              if (pixels!.getUint8((y * 200 + x) * 4 + 3) > 0) {
                escapedPixels++;
              }
            }
          }
          expect(escapedPixels, 0, reason: '${frame.id}, size=$size');
        } finally {
          snapshot.dispose();
        }
      }
    }
  });
}
