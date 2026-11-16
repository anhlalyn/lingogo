// Produces size/padding derivatives only; the master logo is AI-generated.
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final source = img.decodePng(
    File('assets/branding/lingogo_logo.png').readAsBytesSync(),
  )!;
  final logo = img.copyResize(
    source,
    width: 640,
    height: 640,
    interpolation: img.Interpolation.cubic,
  );
  final splash = img.Image(width: 1152, height: 1152, numChannels: 4);
  img.compositeImage(splash, logo, dstX: 256, dstY: 256);
  File(
    'assets/branding/lingogo_splash.png',
  ).writeAsBytesSync(img.encodePng(splash));
  stdout.writeln('Prepared native splash derivative.');
}
