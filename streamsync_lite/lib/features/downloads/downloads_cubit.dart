import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/video.dart';
import 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  Box<Video>? _cacheBox;

  DownloadsCubit() : super(DownloadsState.initial());

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));

    try {
      await _initHive();
      final cachedVideos = _cacheBox?.values.toList() ?? [];

      emit(
        state.copyWith(
          isLoading: false,
          isInitialized: true,
          cachedVideos: cachedVideos,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to initialize downloads: $e',
        ),
      );
    }
  }

  Future<void> _initHive() async {
    _cacheBox = await Hive.openBox<Video>('cached_videos');
  }

  Future<void> clearCache() async {
    emit(state.copyWith(isClearing: true));

    try {
      await _cacheBox?.clear();
      final cachedVideos = _cacheBox?.values.toList() ?? [];

      emit(
        state.copyWith(
          isClearing: false,
          cachedVideos: cachedVideos,
          successMessage: 'Cache cleared successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isClearing: false,
          errorMessage: 'Failed to clear cache: $e',
        ),
      );
    }
  }

  void removeVideo(Video video) async {
    try {
      // Get all keys and find the one that matches our video
      final allKeys = _cacheBox?.keys.toList() ?? [];
      dynamic keyToRemove;

      for (var key in allKeys) {
        final cachedVideo = _cacheBox?.get(key);
        if (cachedVideo?.videoId == video.videoId) {
          keyToRemove = key;
          break;
        }
      }

      if (keyToRemove != null) {
        await _cacheBox?.delete(keyToRemove);
        final cachedVideos = _cacheBox?.values.toList() ?? [];

        emit(
          state.copyWith(
            cachedVideos: cachedVideos,
            successMessage: 'Video removed from cache',
          ),
        );
      } else {
        emit(state.copyWith(errorMessage: 'Video not found in cache'));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to remove video: $e'));
    }
  }

  void refreshCache() async {
    try {
      final cachedVideos = _cacheBox?.values.toList() ?? [];
      emit(state.copyWith(cachedVideos: cachedVideos));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to refresh cache: $e'));
    }
  }

  void clearMessages() {
    emit(state.copyWith(successMessage: null, errorMessage: null));
  }
}
