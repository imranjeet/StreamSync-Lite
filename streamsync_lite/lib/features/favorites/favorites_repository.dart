import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/di/injection.dart';

class FavoritesRepository {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SyncService _syncService = SyncService();

  Future<void> toggleFavorite(String videoId) async {
    try {
      await _apiClient.dio.post('/favorites/toggle', data: {
        'videoId': videoId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      await _syncService.queueAction(
        'favorite_toggle',
        {'videoId': videoId},
        idempotencyKey: 'fav_${videoId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      rethrow;
    }
  }

  Future<List<String>> getFavorites() async {
    try {
    final response = await _apiClient.dio.get('/favorites');
    if (response.data['status'] == 'success') {
      final List<dynamic> favorites = response.data['data'];
        return favorites.map<String>((f) => f['videoId'] ?? f['video_id']).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorites: $e');
      }
    }
    return <String>[];
  }
}

