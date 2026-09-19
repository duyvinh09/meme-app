import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Service quản lý cache và preload video cho Feed & Moment Viewer
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  static VideoCacheService get instance => _instance;

  VideoCacheService._internal();

  /// Dedicated CacheManager cho video với thời gian lưu trữ 7 ngày và tối đa 100 video gần nhất
  late final CacheManager _cacheManager = CacheManager(
    Config(
      'app_video_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'app_video_cache'),
      fileService: HttpFileService(),
    ),
  );

  final Set<String> _preloadingUrls = {};

  /// Lấy file đã cache (nếu có sẵn trên máy)
  Future<File?> getCachedFile(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    try {
      final fileInfo = await _cacheManager.getFileFromCache(cleanUrl);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file;
      }
    } catch (e) {
      debugPrint('VideoCacheService getCachedFile error: $e');
    }
    return null;
  }

  /// Tải trước video ngầm vào đĩa để khi lướt tới là có sẵn file phát ngay lập tức
  Future<void> preloadVideo(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    if (_preloadingUrls.contains(cleanUrl)) return;

    try {
      final isCached = await _cacheManager.getFileFromCache(cleanUrl);
      if (isCached != null && await isCached.file.exists()) {
        return;
      }

      _preloadingUrls.add(cleanUrl);
      await _cacheManager.downloadFile(cleanUrl);
    } catch (e) {
      debugPrint('VideoCacheService preload error: $e ($cleanUrl)');
    } finally {
      _preloadingUrls.remove(cleanUrl);
    }
  }

  /// Tải trước nhiều video cùng lúc (thường là 2-3 video kế tiếp trong feed)
  void preloadBatch(List<String> urls) {
    for (final url in urls) {
      final cleanUrl = url.trim();
      if (cleanUrl.isNotEmpty) {
        preloadVideo(cleanUrl);
      }
    }
  }

  /// Tạo và khởi tạo VideoPlayerController với tốc độ tối ưu (từ file cache nếu có hoặc từ network)
  Future<VideoPlayerController> createOptimizedController(
    String url, {
    bool looping = true,
    double volume = 0,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      throw ArgumentError('Video URL cannot be empty');
    }

    VideoPlayerController controller;

    // 1. Kiểm tra xem đã có file trong cache chưa
    File? cachedFile;
    try {
      final fileInfo = await _cacheManager.getFileFromCache(cleanUrl);
      if (fileInfo != null && await fileInfo.file.exists()) {
        cachedFile = fileInfo.file;
      }
    } catch (_) {}

    if (cachedFile != null) {
      // Khởi tạo trực tiếp từ file trên ổ đĩa -> Tốc độ phản hồi cực nhanh (gần như tức thì)
      controller = VideoPlayerController.file(
        cachedFile,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
    } else {
      // Nếu chưa có file cục bộ, khởi tạo từ Network đồng thời kích hoạt tải ngầm vào cache
      controller = VideoPlayerController.networkUrl(
        Uri.parse(cleanUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      // Tải ngầm lưu cache cho những lần xem sau
      preloadVideo(cleanUrl);
    }

    await controller.setLooping(looping);
    await controller.setVolume(volume);
    await controller.initialize();

    return controller;
  }
}
