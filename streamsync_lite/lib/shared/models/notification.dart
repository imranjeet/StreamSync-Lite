import 'package:hive/hive.dart';

class AppNotification extends HiveObject {
  final String id;
  final String userId;
  final String title;
  final String body;
  bool isRead;
  bool isDeleted;
  final String? linkedContent;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.isDeleted,
    this.linkedContent,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      title: json['title'],
      body: json['body'],
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      isDeleted: json['isDeleted'] ?? json['is_deleted'] ?? false,
      linkedContent: json['linkedContent'] ?? json['linked_content'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'linked_content': linkedContent,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
