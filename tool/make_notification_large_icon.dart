// Builds android/app/src/main/res/drawable-nodpi/ic_notification_large.png —
// the app logo, centred with a little padding on a transparent square. It is
// the full-colour image drawn on the right of every offer notification (the
// "large icon", like Foodi/Daraz); Android draws the small status-bar icon as
// a flat shape, so the real logo can only appear here.
//
// Run from the project root: dart run tool/make_notification_large_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const size = 384;
  const padding = 6;
  final logo = img.decodePng(File('assets/images/logo.png').readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not decode assets/images/logo.png');
    exit(1);
  }

  final scaled = logo.width >= logo.height
      ? img.copyResize(logo, width: size - padding * 2, interpolation: img.Interpolation.cubic)
      : img.copyResize(logo, height: size - padding * 2, interpolation: img.Interpolation.cubic);
  final canvas = img.Image(width: size, height: size, numChannels: 4)..clear(img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    canvas,
    scaled,
    dstX: (size - scaled.width) ~/ 2,
    dstY: (size - scaled.height) ~/ 2,
  );

  const out = 'android/app/src/main/res/drawable-nodpi/ic_notification_large.png';
  Directory('android/app/src/main/res/drawable-nodpi').createSync(recursive: true);
  File(out).writeAsBytesSync(img.encodePng(canvas, level: 9));
  stdout.writeln('Wrote $out (${size}x$size)');
}
