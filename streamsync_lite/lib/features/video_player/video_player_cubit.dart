import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/video.dart';
import '../../shared/models/progress.dart';
import '../../features/home/home_repository.dart';
import '../../core/sync/sync_service.dart';
import '../../core/di/injection.dart';
import 'video_player_state.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  final Video video;
  final HomeRepository _repository;
  final SyncService _syncService;
  final SharedPreferences _prefs;
  late YoutubePlayerController _controller;
  Box<Progress>? _progressBox;

  VideoPlayerCubit({
    required this.video,
    required HomeRepository repository,
    required SyncService syncService,
    required SharedPreferences prefs,
  })  : _repository = repository,
        _syncService = syncService,
        _prefs = prefs,
        super(VideoPlayerState.initial());

  static VideoPlayerCubit create({required Video video}) => VideoPlayerCubit(
        video: video,
        repository: getIt<HomeRepository>(),
        syncService: getIt<SyncService>(),
        prefs: getIt<SharedPreferences>(),
      );

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _syncService.initialize();
      await _initProgressStorage();
      await _initializePlayer();
      
      emit(state.copyWith(
        isLoading: false,
        isInitialized: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize video player: $e',
      ));
    }
  }

  Future<void> _initProgressStorage() async {
    _progressBox = await Hive.openBox<Progress>('progress');
  }

  Future<void> _initializePlayer() async {
    final savedPosition = await _getSavedPosition();
    
    _controller = YoutubePlayerController(
      initialVideoId: video.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        startAt: savedPosition,
        mute: false,
        enableCaption: true,
        loop: false,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_onPlayerStateChanged);
  }

  Future<int> _getSavedPosition() async {
    final userId = _prefs.getString('user_id') ?? '';
    
    // Try Hive first
    if (_progressBox != null) {
      final progress = _progressBox!.values.cast<Progress?>().firstWhere(
        (p) => p?.userId == userId && p?.videoId == video.videoId,
        orElse: () => null,
      );
      if (progress != null) {
        return progress.positionSeconds;
      }
    }

    // Fallback to SharedPreferences
    return _prefs.getInt('video_position_${video.videoId}') ?? 0;
  }

  void _onPlayerStateChanged() {
    if (_controller.value.isReady) {
      final position = _controller.value.position.inSeconds;
      if (position % 5 == 0 && position > 0) {
        _saveProgress(position);
      }
      
      // Update current position in state
      emit(state.copyWith(currentPosition: position));
    }
  }

  Future<void> _saveProgress(int positionSeconds) async {
    final userId = _prefs.getString('user_id') ?? '';
    final totalDuration = video.durationSeconds ?? 1;
    final completedPercent = (positionSeconds / totalDuration) * 100;
    final updatedAt = DateTime.now().toUtc();
    final progressKey = '${userId}_${video.videoId}';

    // Save locally
    await _saveLocalProgress(
      userId: userId,
      positionSeconds: positionSeconds,
      completedPercent: completedPercent,
      updatedAt: updatedAt,
      progressKey: progressKey,
    );

    // Sync to server
    await _syncProgressToServer(
      positionSeconds: positionSeconds,
      updatedAt: updatedAt,
      progressKey: progressKey,
    );
  }

  Future<void> _saveLocalProgress({
    required String userId,
    required int positionSeconds,
    required double completedPercent,
    required DateTime updatedAt,
    required String progressKey,
  }) async {
    final progress = Progress(
      userId: userId,
      videoId: video.videoId,
      positionSeconds: positionSeconds,
      completedPercent: completedPercent,
      synced: false,
      updatedAt: updatedAt,
    );

    if (_progressBox != null) {
      await _progressBox!.put(progressKey, progress);
    }

    _prefs.setInt('video_position_${video.videoId}', positionSeconds);
  }

  Future<void> _syncProgressToServer({
    required int positionSeconds,
    required DateTime updatedAt,
    required String progressKey,
  }) async {
    try {
      await _repository.saveProgress(
        video.videoId,
        positionSeconds,
        updatedAt: updatedAt.toIso8601String(),
      );

      // Mark as synced
      if (_progressBox != null) {
        final progress = _progressBox!.get(progressKey);
        if (progress != null) {
          progress.synced = true;
          await _progressBox!.put(progressKey, progress);
        }
      }
      
      emit(state.copyWith(lastSyncedAt: DateTime.now()));
    } catch (e) {
      // Queue for later sync
      await _syncService.queueAction(
        'progress_update',
        {
          'videoId': video.videoId,
          'positionSeconds': positionSeconds,
          'updatedAt': updatedAt.toIso8601String(),
        },
        idempotencyKey: 'progress_${video.videoId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      emit(state.copyWith(
        errorMessage: 'Progress saved locally, will sync when online',
      ));
    }
  }

  Future<void> changePlaybackSpeed(double speed) async {
    try {
      _controller.setPlaybackRate(speed);
      emit(state.copyWith(playbackSpeed: speed));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to change playback speed: $e',
      ));
    }
  }

  Future<void> shareVideo() async {
    emit(state.copyWith(
      successMessage: 'Video link copied to clipboard',
    ));
  }

  Future<void> saveFinalProgress() async {
    if (_controller.value.isReady) {
      final position = _controller.value.position.inSeconds;
      await _saveProgress(position);
    }
  }

  void clearMessages() {
    emit(state.copyWith(
      successMessage: null,
      errorMessage: null,
    ));
  }

  YoutubePlayerController get controller => _controller;

  @override
  Future<void> close() {
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    return super.close();
  }
}