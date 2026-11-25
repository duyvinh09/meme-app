import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:meme_app/features/capture/services/photobooth_compositor.dart';

Future<void> main() async {
  final catalog =
      jsonDecode(await File('assets/photobooth/catalog.json').readAsString())
          as Map<String, dynamic>;
  final sheet = img.Image(width: 960, height: 1080, numChannels: 3);
  img.fill(sheet, color: img.ColorRgb8(24, 25, 30));
  final ids = [
    'cmt_siuu',
    'pb_khung2_Polaroid_vintage',
    'pb_khung3_polaroid2',
    'pb_khung4_smile'
  ];
  final colors = [
    [230, 90, 110],
    [75, 155, 240],
    [95, 190, 140],
    [230, 175, 75]
  ];
  for (var row = 0; row < ids.length; row++) {
    final entry = (catalog['frames'] as List<dynamic>)
        .firstWhere((e) => e['id'] == ids[row]);
    final slots = (entry['slots'] as List<dynamic>)
        .map((e) => (e as List<dynamic>).cast<int>())
        .toList();
    final photos = <List<int>>[];
    for (var shot = 0; shot < slots.length; shot++) {
      final photo = img.Image(width: 240, height: 240);
      final color = colors[shot];
      img.fill(photo, color: img.ColorRgb8(color[0], color[1], color[2]));
      img.drawString(photo, '${shot + 1}',
          font: img.arial48,
          x: 100,
          y: 90,
          color: img.ColorRgb8(255, 255, 255));
      photos.add(img.encodePng(photo));
      final composite = composePhotobooth(PhotoboothComposition(
        overlay: await File(entry['asset'] as String).readAsBytes(),
        photos: photos.map((p) => Uint8List.fromList(p)).toList(),
        slots: slots,
        masks: await Future.wait((entry['masks'] as List<dynamic>)
            .map((p) => File(p as String).readAsBytes())),
        outputSize: 240,
      ));
      img.compositeImage(sheet, img.decodeJpg(composite.image)!,
          dstX: shot * 240, dstY: row * 270 + 25);
    }
    img.drawString(sheet, ids[row],
        font: img.arial14,
        x: 8,
        y: row * 270 + 5,
        color: img.ColorRgb8(255, 255, 255));
  }
  await Directory('build/photobooth_previews').create(recursive: true);
  await File('build/photobooth_previews/contact_sheet.jpg')
      .writeAsBytes(img.encodeJpg(sheet, quality: 92));
}
