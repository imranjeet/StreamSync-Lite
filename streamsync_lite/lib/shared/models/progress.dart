import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class Progress extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String videoId;

  @HiveField(2)
  final int positionSeconds;

  @HiveField(3)
  final double completedPercent;

  @HiveField(4)
  bool synced; // Marks if synced with backend

  @HiveField(5)
  final DateTime updatedAt;

  Progress({
    required this.userId,
    required this.videoId,
    required this.positionSeconds,
    required this.completedPercent,
    required this.synced,
    required this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      userId: json['userId'] ?? json['user_id'] ?? '',
      videoId: json['videoId'] ?? json['video_id'] ?? '',
      positionSeconds: json['positionSeconds'] ?? json['position_seconds'] ?? 0,
      completedPercent: (json['completedPercent'] ?? json['completed_percent'] ?? 0).toDouble(),
      synced: json['synced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'video_id': videoId,
      'position_seconds': positionSeconds,
      'completed_percent': completedPercent,
      'synced': synced,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}

