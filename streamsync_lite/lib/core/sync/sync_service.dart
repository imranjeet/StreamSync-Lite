import 'package:hive_flutter/hive_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/di/injection.dart';
import '../../shared/models/pending_action.dart';

class SyncService {
  final ApiClient _apiClient = getIt<ApiClient>();
  Box<PendingAction>? _pendingActionsBox;

  Future<void> initialize() async {
    if (_pendingActionsBox == null) {
      _pendingActionsBox = await Hive.openBox<PendingAction>('pending_actions');
    }
  }

  Future<void> queueAction(
    String actionType,
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    await initialize();

    // Check for duplicate idempotency key
    if (idempotencyKey != null) {
      final existing = _pendingActionsBox!.values.cast<PendingAction?>().firstWhere(
        (action) => action?.idempotencyKey == idempotencyKey,
        orElse: () => null,
      );
      if (existing != null) {
        return; // Already queued
      }
    }

    final action = PendingAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      actionType: actionType,
      payload: payload,
      idempotencyKey: idempotencyKey,
      updatedAt: DateTime.now().toUtc(),
    );

    await _pendingActionsBox!.put(action.id, action);
  }

  Future<void> syncPendingActions() async {
    await initialize();

    final pendingActions = _pendingActionsBox!.values.toList();
    
    if (pendingActions.isEmpty) {
      return;
    }

    // Batch actions by type for efficient syncing
    final progressActions = <PendingAction>[];
    final favoriteActions = <PendingAction>[];
    final notificationActions = <PendingAction>[];

    for (final action in pendingActions) {
      switch (action.actionType) {
        case 'progress_update':
          progressActions.add(action);
          break;
        case 'favorite_toggle':
          favoriteActions.add(action);
          break;
        case 'notification_delete':
          notificationActions.add(action);
          break;
      }
    }

    // Sync progress updates (batch)
    for (final action in progressActions) {
      try {
        await _syncAction(action);
        await _pendingActionsBox!.delete(action.id);
      } catch (e) {
        print('Failed to sync progress action ${action.id}: $e');
        // Keep in queue for retry
      }
    }

    // Sync favorite toggles (batch)
    for (final action in favoriteActions) {
      try {
        await _syncAction(action);
        await _pendingActionsBox!.delete(action.id);
      } catch (e) {
        print('Failed to sync favorite action ${action.id}: $e');
        // Keep in queue for retry
      }
    }

    // Sync notification deletes (batch)
    for (final action in notificationActions) {
      try {
        await _syncAction(action);
        await _pendingActionsBox!.delete(action.id);
      } catch (e) {
        print('Failed to sync notification delete ${action.id}: $e');
        // Keep in queue for retry
      }
    }
  }

  Future<void> _syncAction(PendingAction action) async {
    switch (action.actionType) {
      case 'progress_update':
        await _apiClient.dio.post('/videos/progress', data: {
          ...action.payload,
          'updatedAt': action.updatedAt.toUtc().toIso8601String(),
        });
        break;
      case 'favorite_toggle':
        await _apiClient.dio.post('/favorites/toggle', data: action.payload);
        break;
      case 'notification_delete':
        await _apiClient.dio.delete('/notifications/${action.payload['notificationId']}');
        break;
      default:
        throw Exception('Unknown action type: ${action.actionType}');
    }
  }
}

