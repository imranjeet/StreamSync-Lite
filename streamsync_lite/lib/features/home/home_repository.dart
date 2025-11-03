import '../../../core/network/api_client.dart';
import '../../../shared/models/video.dart';
import '../../../core/di/injection.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeRepository {
  final ApiClient _apiClient = getIt<ApiClient>();
  Box<Video>? _cacheBox;

  Future<Box<Video>> _getCacheBox() async {
    _cacheBox ??= await Hive.openBox<Video>('cached_videos');
    return _cacheBox!;
  }

  Future<List<Video>> getLatestVideos() async {
    try {
    final response = await _apiClient.dio.get('/videos/latest');

    if (response.data['status'] == 'success') {
      final List<dynamic> videosJson = response.data['data'];
        final videos = videosJson.map((json) => Video(
        videoId: json['videoId'] ?? json['video_id'],
        title: json['title'],
        description: json['description'],
        thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'],
        durationSeconds: json['durationSeconds'] ?? json['duration_seconds'],
        publishedAt: json['publishedAt'] != null 
            ? DateTime.parse(json['publishedAt']) 
            : (json['published_at'] != null 
                ? DateTime.parse(json['published_at']) 
                : null),
        channelId: json['channelId'] ?? json['channel_id'],
        channelName: json['channelName'] ?? json['channel_name'],
      )).toList();

        final cacheBox = await _getCacheBox();
        for (final video in videos) {
          await cacheBox.put(video.videoId, video);
        }

        return videos;
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch videos');
    } catch (e) {
      final cacheBox = await _getCacheBox();
      final cachedVideos = cacheBox.values.toList();
      if (cachedVideos.isNotEmpty) {
        return cachedVideos;
      }
      throw Exception('Failed to fetch videos: $e');
    }
  }

  Future<void> saveProgress(String videoId, int positionSeconds, {String? updatedAt}) async {
    final payload = {
      'videoId': videoId,
      'positionSeconds': positionSeconds,
    };
    if (updatedAt != null) {
      payload['updatedAt'] = updatedAt;
    }
    await _apiClient.dio.post('/videos/progress', data: payload);
  }
}

