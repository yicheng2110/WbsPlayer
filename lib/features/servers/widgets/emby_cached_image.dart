import 'package:flutter/material.dart';

import '../services/emby_image_cache.dart';

/// Displays a persistent, externally cached Emby image.
class EmbyCachedImage extends StatelessWidget {
  const EmbyCachedImage({
    super.key,
    required this.uri,
    required this.headers,
    this.fit,
    this.filterQuality = FilterQuality.medium,
    this.frameBuilder,
    this.errorBuilder,
  });

  final Uri uri;
  final Map<String, String> headers;
  final BoxFit? fit;
  final FilterQuality filterQuality;
  final ImageFrameBuilder? frameBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => Image(
    image: _EmbyCachedImageProvider(uri, headers),
    fit: fit,
    filterQuality: filterQuality,
    frameBuilder: frameBuilder,
    errorBuilder: errorBuilder,
  );
}

class _EmbyCachedImageProvider extends ImageProvider<_EmbyCachedImageProvider> {
  const _EmbyCachedImageProvider(this.uri, this.headers);

  final Uri uri;
  final Map<String, String> headers;

  @override
  Future<_EmbyCachedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _EmbyCachedImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(decode));

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    final bytes = await EmbyImageCache.shared.load(uri, headers: headers);
    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image, scale: 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _EmbyCachedImageProvider &&
      other.uri == uri &&
      other.headers.toString() == headers.toString();

  @override
  int get hashCode => Object.hash(uri, headers.toString());
}
