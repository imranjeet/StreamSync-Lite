import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Video extends HiveObject {
  @HiveField(0)
  final String videoId;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String thumbnailUrl;
  @HiveField(4)
  final int? durationSeconds;
  @HiveField(5)
  final DateTime? publishedAt;
  @HiveField(6)
  final String? channelId;
  @HiveField(7)
  final String? channelName;

  Video({
    required this.videoId,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    this.durationSeconds,
    this.publishedAt,
    this.channelId,
    this.channelName,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'published_at': publishedAt?.toIso8601String(),
      'channel_id': channelId,
      'channel_name': channelName,
    };
  }

  String get formattedPublishedDate {
    if (publishedAt == null) return 'Unknown date';
    final now = DateTime.now();
    final difference = now.difference(publishedAt!);
    
    if (difference.inDays > 30) {
      return '${publishedAt!.day}/${publishedAt!.month}/${publishedAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDuration {
    if (durationSeconds == null) return 'Unknown';
    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
