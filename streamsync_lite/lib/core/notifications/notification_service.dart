import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Box<AppNotification>? _notificationBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _notificationBox = await Hive.openBox<AppNotification>('notifications');
      _isInitialized = true;
    }
  }

  Box<AppNotification>? get notificationBox => _notificationBox;

  Future<void> saveNotification(RemoteMessage message) async {
    if (_notificationBox == null) {
      await initialize();
    }

    try {
      final notification = AppNotification(
        id: message.data['notificationId'] ?? 
            message.data['id'] ?? 
            message.messageId ?? 
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: message.data['userId'] ?? message.data['user_id'] ?? '',
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        isRead: false,
        isDeleted: false,
        linkedContent: message.data['linkedContent'] ?? message.data['linked_content'],
        metadata: message.data,
        createdAt: message.sentTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _notificationBox!.put(notification.id, notification);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  int getUnreadCount() {
    if (_notificationBox == null) return 0;
    return _notificationBox!.values
        .where((n) => !n.isRead && !n.isDeleted)
        .length;
  }

  List<AppNotification> getNotifications() {
    if (_notificationBox == null) return [];
    return _notificationBox!.values
        .where((n) => !n.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

