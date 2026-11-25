import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;

// Convert imported templates to compact WebP, retaining full-quality alpha.
Future<void> main() async {
  final manifest = File('assets/photobooth/catalog.json');
  final data =
      jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
  final frames = (data['frames'] as List<dynamic>).cast<Map<String, dynamic>>();
  final obsolete = frames
      .expand((entry) =>
          [File(entry['asset'] as String), File(entry['thumbnail'] as String)])
      .where((f) => f.path.endsWith('.png'))
      .toList();
  var index = 0;
  for (var offset = 0; offset < frames.length; offset += 4) {
    final batch = frames.skip(offset).take(4).toList();
    final prepared = await Future.wait(
        batch.map((entry) => Isolate.run(() => prepareFrame(entry))));
    for (var i = 0; i < prepared.length; i++) {
      frames[offset + i] = prepared[i];
    }
    index += prepared.length;
    stdout.writeln('Compressed $index/${frames.length} templates');
  }
  data['frames'] = frames;
  await manifest
      .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  for (final file in obsolete) {
    if (await file.exists()) await file.delete();
  }
  stdout.writeln('Compressed $index templates');
}

Future<Map<String, dynamic>> prepareFrame(Map<String, dynamic> entry) async {
  final file = File(entry['asset'] as String);
  final decoded = img.decodeImage(await file.readAsBytes());
  if (decoded == null) throw FormatException('Invalid frame: ${file.path}');
  final frame = img.copyResize(decoded,
      width: 1080, height: 1080, interpolation: img.Interpolation.average);
  final asset = file.path.replaceAll(RegExp(r'\.(png|webp)$'), '.webp');
  final thumbPath = (entry['thumbnail'] as String)
      .replaceAll(RegExp(r'\.(png|webp)$'), '.webp');
  var ready = false;
  if (await File(asset).exists() && await File(thumbPath).exists()) {
    try {
      ready = img.decodeWebP(await File(asset).readAsBytes())?.width == 1080 &&
          img.decodeWebP(await File(thumbPath).readAsBytes())?.width == 180;
    } catch (_) {
      ready = false;
    }
  }
  if (!ready) {
    await File(asset).writeAsBytes(img.encodeWebP(frame,
        lossless: false,
        quality: 90,
        method: 0,
        alphaQuality: 100,
        exact: false));
    final thumb = img.copyResize(frame,
        width: 180, height: 180, interpolation: img.Interpolation.average);
    await File(thumbPath).writeAsBytes(img.encodeWebP(thumb,
        lossless: false,
        quality: 85,
        method: 0,
        alphaQuality: 100,
        exact: false));
  }
  entry['asset'] = asset.replaceAll('\\', '/');
  entry['thumbnail'] = thumbPath.replaceAll('\\', '/');
  return entry;
}
