import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/notification.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/sync_service.dart';
import '../../core/di/injection.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationService _notificationService = NotificationService();
  final ApiClient _apiClient = getIt<ApiClient>();
  final SyncService _syncService = SyncService();
  Box<AppNotification>? _box;
  VoidCallback? _listener;

  NotificationsCubit() : super(NotificationsState.initial());

  Future<void> initialize() async {
    await _notificationService.initialize();
    _box = _notificationService.notificationBox;
    await _syncService.initialize();

    _recomputeFromLocal();
    _attachListener();
    _syncFromServer();
    _syncService.syncPendingActions().ignore();
  }

  void _attachListener() {
    _listener = () {
      _recomputeFromLocal();
    };
    _box?.listenable().addListener(_listener!);
  }

  void _recomputeFromLocal() {
    final items = _notificationService.getNotifications();
    final unread = _notificationService.getUnreadCount();
    emit(state.copyWith(
      notifications: items,
      unreadCount: unread,
      isLoading: false,
      errorMessage: null,
    ));
  }

  Future<void> _syncFromServer() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      if (response.data['status'] == 'success') {
        final List<dynamic> jsonList = response.data['data']['notifications'] ?? [];
        for (final j in jsonList) {
          final n = AppNotification.fromJson(j);
          await _box?.put(n.id, n);
        }
      }
    } catch (e) {
      // keep cached
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true));
    await _syncFromServer();
    _recomputeFromLocal();
  }

  Future<void> deleteNotification(String id) async {
    final n = _box?.get(id);
    if (n != null && _box != null) {
      final updated = AppNotification(
        id: n.id,
        userId: n.userId,
        title: n.title,
        body: n.body,
        isRead: n.isRead,
        isDeleted: true,
        linkedContent: n.linkedContent,
        metadata: n.metadata,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      );
      await _box!.put(id, updated);
    }
    try {
      await _apiClient.dio.delete('/notifications/$id');
    } catch (e) {
      await _syncService.queueAction('notification_delete', {'notificationId': id});
    }
  }

  Future<void> markAsRead(String id) async {
    final n = _box?.get(id);
    if (n == null || _box == null) return;
    final updated = AppNotification(
      id: n.id,
      userId: n.userId,
      title: n.title,
      body: n.body,
      isRead: true,
      isDeleted: n.isDeleted,
      linkedContent: n.linkedContent,
      metadata: n.metadata,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
    await _box!.put(id, updated);
    try {
      await _apiClient.dio.post('/notifications/mark-read', data: {'notificationId': id});
    } catch (e) {
      await _syncService.queueAction('notification_mark_read', {'notificationId': id});
    }
  }

  @override
  Future<void> close() {
    if (_listener != null && _box != null) {
      _box!.listenable().removeListener(_listener!);
    }
    return super.close();
  }
}


