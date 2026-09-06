import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final Map<String, int> sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  final icons = {
    'ic_launcher_default': 'assets/icons/memeapp_icon.png',
    'ic_launcher_1': 'assets/icons/memeapp_icon1.png',
    'ic_launcher_2': 'assets/icons/memeapp_icon2.png',
  };

  final resDir = Directory('android/app/src/main/res');

  for (final entry in icons.entries) {
    final iconName = entry.key;
    final sourcePath = entry.value;
    final sourceFile = File(sourcePath);

    if (!sourceFile.existsSync()) {
      print('File not found: $sourcePath');
      continue;
    }

    final bytes = sourceFile.readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) {
      print('Could not decode: $sourcePath');
      continue;
    }

    for (final sizeEntry in sizes.entries) {
      final folderName = sizeEntry.key;
      final size = sizeEntry.value;

      final targetFolder = Directory('${resDir.path}/$folderName');
      if (!targetFolder.existsSync()) {
        targetFolder.createSync(recursive: true);
      }

      final resized = img.copyResize(image, width: size, height: size);
      final targetFile = File('${targetFolder.path}/$iconName.png');
      targetFile.writeAsBytesSync(img.encodePng(resized));
      print('Generated ${targetFile.path} (${size}x$size)');
    }
  }

  print('All mipmaps generated successfully!');
}
