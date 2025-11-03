import 'package:equatable/equatable.dart';
import '../../shared/models/video.dart';

class DownloadsState extends Equatable {
  final bool isLoading;
  final bool isInitialized;
  final bool isClearing;
  final List<Video> cachedVideos;
  final String? successMessage;
  final String? errorMessage;

  const DownloadsState({
    required this.isLoading,
    required this.isInitialized,
    required this.isClearing,
    required this.cachedVideos,
    this.successMessage,
    this.errorMessage,
  });

  factory DownloadsState.initial() => const DownloadsState(
        isLoading: false,
        isInitialized: false,
        isClearing: false,
        cachedVideos: [],
        successMessage: null,
        errorMessage: null,
      );

  DownloadsState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isClearing,
    List<Video>? cachedVideos,
    String? successMessage,
    String? errorMessage,
  }) {
    return DownloadsState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isClearing: isClearing ?? this.isClearing,
      cachedVideos: cachedVideos ?? this.cachedVideos,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        isClearing,
        cachedVideos,
        successMessage,
        errorMessage,
      ];
}