import 'package:equatable/equatable.dart';

class VideoPlayerState extends Equatable {
  final bool isLoading;
  final bool isInitialized;
  final double playbackSpeed;
  final int currentPosition;
  final String? successMessage;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const VideoPlayerState({
    required this.isLoading,
    required this.isInitialized,
    required this.playbackSpeed,
    required this.currentPosition,
    this.successMessage,
    this.errorMessage,
    this.lastSyncedAt,
  });

  factory VideoPlayerState.initial() => const VideoPlayerState(
        isLoading: false,
        isInitialized: false,
        playbackSpeed: 1.0,
        currentPosition: 0,
        successMessage: null,
        errorMessage: null,
        lastSyncedAt: null,
      );

  VideoPlayerState copyWith({
    bool? isLoading,
    bool? isInitialized,
    double? playbackSpeed,
    int? currentPosition,
    String? successMessage,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return VideoPlayerState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      currentPosition: currentPosition ?? this.currentPosition,
      successMessage: successMessage,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        playbackSpeed,
        currentPosition,
        successMessage,
        errorMessage,
        lastSyncedAt,
      ];
}