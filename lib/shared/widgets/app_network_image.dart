import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Image provider for catalog photos (Firebase Storage URLs).
///
/// Android/iOS: [CachedNetworkImageProvider] keeps each photo on disk, so a
/// relaunch shows product and banner images from storage instead of
/// downloading every one again — plain `Image.network` only caches in
/// memory for the current run. Web: the browser's own HTTP cache already
/// does this (uploads are served `immutable` for a year), so it stays on
/// [NetworkImage].
ImageProvider appNetworkImageProvider(String url) => kIsWeb ? NetworkImage(url) : CachedNetworkImageProvider(url);

/// `Image` for a catalog photo URL — see [appNetworkImageProvider].
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.frameBuilder,
    this.errorBuilder,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageFrameBuilder? frameBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: appNetworkImageProvider(url),
      fit: fit,
      width: width,
      height: height,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
