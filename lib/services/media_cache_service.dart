import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  final Map<String, Future<File?>> _pendingDownloads = {};

  /// Returns a cached File on local storage for any remote URL or local path.
  /// If the URL is already cached, returns the local File immediately.
  Future<File?> getCachedFile(String mediaPath) async {
    if (mediaPath.isEmpty) return null;

    // Local file path handling
    if (!mediaPath.startsWith('http')) {
      final file = File(mediaPath);
      if (await file.exists()) return file;
      return null;
    }

    // Web handling fallback
    if (kIsWeb) return null;

    // Remote HTTP URL Caching
    if (_pendingDownloads.containsKey(mediaPath)) {
      return await _pendingDownloads[mediaPath];
    }

    final completer = Completer<File?>();
    _pendingDownloads[mediaPath] = completer.future;

    try {
      final uri = Uri.parse(mediaPath);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "media_${mediaPath.hashCode}";
      final safeFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
      final cacheFile = File("${Directory.systemTemp.path}/msg_cache_$safeFilename");

      // Check if file already exists in local disk cache
      if (await cacheFile.exists() && (await cacheFile.length()) > 0) {
        completer.complete(cacheFile);
        return cacheFile;
      }

      // Download file to local cache
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await cacheFile.writeAsBytes(bytes);
        completer.complete(cacheFile);
        return cacheFile;
      } else {
        completer.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('MediaCache error for $mediaPath: $e');
      completer.complete(null);
      return null;
    } finally {
      _pendingDownloads.remove(mediaPath);
    }
  }
}
