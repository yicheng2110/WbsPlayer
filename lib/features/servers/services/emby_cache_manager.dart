import 'package:flutter/painting.dart';

import 'emby_api_response_cache.dart';
import 'emby_cache_storage.dart';
import 'emby_image_cache.dart';

/// Coordinates clearing Emby metadata and image caches.
class EmbyCacheManager {
  EmbyCacheManager._();

  /// Removes persisted API JSON, image bytes, and decoded Flutter images.
  static Future<void> clearAll() async {
    await EmbyApiResponseCache.shared.clear();
    await EmbyImageCache.shared.clear();
    await EmbyCacheStorage.clear();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
}
