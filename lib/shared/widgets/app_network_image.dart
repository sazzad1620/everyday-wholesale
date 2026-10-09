import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'image_fade_in.dart';

/// Image provider for catalog photos (Firebase Storage URLs).
///
/// Android/iOS: [CachedNetworkImageProvider] keeps each photo on disk, so a
/// relaunch shows product and banner images from storage instead of
/// downloading every one again — plain `Image.network` only caches in
/// memory for the current run. Web: the browser's own HTTP cache already
/// does this (uploads are served `immutable` for a year), so it stays on
/// [NetworkImage].
ImageProvider appNetworkImageProvider(String url) => kIsWeb ? NetworkImage(url) : CachedNetworkImageProvider(url);

/// The width, in device pixels, to decode a photo at when it is shown
/// [logicalWidth] logical pixels wide: rounded **up** to a multiple of 64 (so a
/// small window resize reuses the same decode) and capped at 1920. `null` when
/// the width isn't known.
int? decodeWidthFor(BuildContext context, double logicalWidth) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  final pixels = logicalWidth * MediaQuery.devicePixelRatioOf(context);
  return ((pixels / 64).ceil() * 64).clamp(64, 1920);
}

/// `Image` for a catalog photo URL — see [appNetworkImageProvider].
///
/// Photos are decoded at the size they are shown ([decodeWidthFor]) instead of
/// at the size they were uploaded: a 1600 px product photo in a 150 px card
/// otherwise costs ~10 MB of memory and a long decode on a phone (and on the
/// web). A photo smaller than its slot is never enlarged. Pass
/// `resize: false` for an image that is also pre-loaded with
/// [appNetworkImageProvider] (the resized copy would be a different cache
/// entry, so the pre-load would not help).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.frameBuilder,
    this.errorBuilder,
    this.resize = true,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageFrameBuilder? frameBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final bool resize;

  @override
  Widget build(BuildContext context) {
    if (!resize) return _image(appNetworkImageProvider(url));
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = (width != null && width!.isFinite) ? width! : constraints.maxWidth;
        final decodeWidth = decodeWidthFor(context, slot);
        final provider = appNetworkImageProvider(url);
        return _image(decodeWidth == null ? provider : ResizeImage(provider, width: decodeWidth));
      },
    );
  }

  Widget _image(ImageProvider provider) => Image(
    image: provider,
    fit: fit,
    width: width,
    height: height,
    frameBuilder: frameBuilder ?? imageFadeIn,
    errorBuilder: errorBuilder,
  );
}
