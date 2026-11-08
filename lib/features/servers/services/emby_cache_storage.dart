import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves app-scoped external cache directories used for Emby data.
class EmbyCacheStorage {
  EmbyCacheStorage._();

  static const directoryName = 'wbs_emby_cache';
  static Future<Directory>? _rootDirectoryFuture;
  static Future<Directory>? _apiDirectoryFuture;
  static Future<Directory>? _imageDirectoryFuture;

  /// Returns the app's Emby cache root, preferring Android external cache.
  static Future<Directory> rootDirectory() =>
      _rootDirectoryFuture ??= _createRootDirectory();

  /// Returns the persistent JSON response cache directory.
  static Future<Directory> apiDirectory() =>
      _apiDirectoryFuture ??= _createChildDirectory('api');

  /// Returns the persistent image cache directory.
  static Future<Directory> imageDirectory() =>
      _imageDirectoryFuture ??= _createChildDirectory('images');

  /// Deletes all persisted Emby JSON and image cache files.
  static Future<void> clear() async {
    final root = await rootDirectory();
    if (await root.exists()) await root.delete(recursive: true);
    _rootDirectoryFuture = null;
    _apiDirectoryFuture = null;
    _imageDirectoryFuture = null;
  }

  static Future<Directory> _createRootDirectory() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        final directories = await getExternalCacheDirectories();
        if (directories case [final externalDirectory, ...]) {
          directory = externalDirectory;
        }
      }
    } on UnsupportedError {
      // Fall back to the platform cache directory.
    } on MissingPlatformDirectoryException {
      // Fall back to the platform cache directory.
    }
    directory ??= await getTemporaryDirectory();
    final cacheDirectory = Directory(p.join(directory.path, directoryName));
    await cacheDirectory.create(recursive: true);
    return cacheDirectory;
  }

  static Future<Directory> _createChildDirectory(String name) async {
    final directory = Directory(p.join((await rootDirectory()).path, name));
    await directory.create(recursive: true);
    return directory;
  }
}
