import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamsync_lite/features/video_player/video_player_cubit.dart';
import 'package:streamsync_lite/features/video_player/video_player_state.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import '../../shared/models/video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoPlayerCubit.create(video: widget.video)..initialize(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: const [
            _ShareButton(),
          ],
        ),
        body: BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!)),
              );
              context.read<VideoPlayerCubit>().clearMessages();
            }
            
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
              context.read<VideoPlayerCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!state.isInitialized) {
              return const Center(child: Text('Failed to initialize video player'));
            }

            return const Column(
              children: [
                _VideoPlayer(),
                _PlaybackSpeedControl(),
                Expanded(child: _VideoDetails()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<VideoPlayerCubit>().controller;
    final theme = Theme.of(context);

    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: theme.colorScheme.primary,
      progressColors: ProgressBarColors(
        playedColor: theme.colorScheme.primary,
        handleColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _PlaybackSpeedControl extends StatelessWidget {
  const _PlaybackSpeedControl();

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final currentSpeed = context.watch<VideoPlayerCubit>().state.playbackSpeed;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.speed),
          const SizedBox(width: 8),
          const Text('Playback Speed:'),
          const Spacer(),
          DropdownButton<double>(
            value: currentSpeed,
            items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return DropdownMenuItem(
                value: speed,
                child: Text('${speed}x'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<VideoPlayerCubit>().changePlaybackSpeed(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _VideoDetails extends StatelessWidget {
  const _VideoDetails();

  @override
  Widget build(BuildContext context) {
    final video = context.read<VideoPlayerCubit>().video;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (video.channelName != null) ...[
            Row(
              children: [
                const Icon(Icons.account_circle, size: 16),
                const SizedBox(width: 8),
                Text(
                  video.channelName!,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (video.description != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              video.description!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          const _VideoActions(),
        ],
      ),
    );
  }
}

class _VideoActions extends StatelessWidget {
  const _VideoActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.thumb_up_outlined),
          onPressed: () {},
        ),
        const Text('Like'),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.comment_outlined),
          onPressed: () {},
        ),
        const Text('Comments'),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    final video = context.read<VideoPlayerCubit>().video;

    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        Clipboard.setData(
          ClipboardData(
            text: 'https://www.youtube.com/watch?v=${video.videoId}',
          ),
        );
        context.read<VideoPlayerCubit>().shareVideo();
      },
      tooltip: 'Share',
    );
  }
}


// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../../shared/models/video.dart';
// import '../../shared/models/progress.dart';
// import '../../features/home/home_repository.dart';
// import '../../core/sync/sync_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/di/injection.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final Video video;

//   const VideoPlayerScreen({super.key, required this.video});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   final HomeRepository _repository = HomeRepository();
//   final SyncService _syncService = SyncService();
//   final SharedPreferences _prefs = getIt<SharedPreferences>();
//   Box<Progress>? _progressBox;
//   bool _isInitialized = false;
//   double _playbackSpeed = 1.0;

//   @override
//   void initState() {
//     super.initState();
//     _syncService.initialize();
//     _initProgressStorageAndPlayer();
//   }

//   Future<void> _initProgressStorageAndPlayer() async {
//     _progressBox = await Hive.openBox<Progress>('progress');
//     _initializePlayer();
//   }

//   void _initializePlayer() {
//     int savedPosition = 0;
//     if (_progressBox != null) {
//       final userId = _prefs.getString('user_id') ?? '';
//       final progress = _progressBox!.values.cast<Progress?>().firstWhere(
//         (p) => p?.userId == userId && p?.videoId == widget.video.videoId,
//         orElse: () => null,
//       );
//       if (progress != null) {
//         savedPosition = progress.positionSeconds;
//       }
//     }

//     if (savedPosition == 0) {
//       savedPosition =
//           _prefs.getInt('video_position_${widget.video.videoId}') ?? 0;
//     }

//     _controller = YoutubePlayerController(
//       initialVideoId: widget.video.videoId,
//       flags: YoutubePlayerFlags(
//         autoPlay: true,
//         startAt: savedPosition,
//         mute: false,
//         enableCaption: true,
//         loop: false,
//         controlsVisibleAtStart: true,
//       ),
//     );

//     _controller.addListener(() {
//       if (_controller.value.isReady) {
//         final position = _controller.value.position.inSeconds;
//         if (position % 5 == 0 && position > 0) {
//           _saveProgress(position);
//         }
//       }
//     });

//     setState(() {
//       _isInitialized = true;
//     });
//   }

//   Future<void> _saveProgress(int positionSeconds) async {
//     final userId = _prefs.getString('user_id') ?? '';
//     final totalDuration = widget.video.durationSeconds ?? 1;
//     final completedPercent = (positionSeconds / totalDuration) * 100;

//     final updatedAt = DateTime.now().toUtc();
//     final progressKey = '${userId}_${widget.video.videoId}';

//     if (_progressBox != null) {
//       final progress = Progress(
//         userId: userId,
//         videoId: widget.video.videoId,
//         positionSeconds: positionSeconds,
//         completedPercent: completedPercent,
//         synced: false,
//         updatedAt: updatedAt,
//       );
//       await _progressBox!.put(progressKey, progress);
//     }

//     _prefs.setInt('video_position_${widget.video.videoId}', positionSeconds);

//     try {
//       await _repository.saveProgress(
//         widget.video.videoId,
//         positionSeconds,
//         updatedAt: updatedAt.toIso8601String(),
//       );

//       if (_progressBox != null) {
//         final progress = _progressBox!.get(progressKey);
//         if (progress != null) {
//           progress.synced = true;
//           await _progressBox!.put(progressKey, progress);
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Failed to sync progress: $e');
//       }
//       await _syncService.queueAction(
//         'progress_update',
//         {
//           'videoId': widget.video.videoId,
//           'positionSeconds': positionSeconds,
//           'updatedAt': updatedAt.toIso8601String(),
//         },
//         idempotencyKey:
//             'progress_${widget.video.videoId}_${DateTime.now().millisecondsSinceEpoch}',
//       );
//     }
//   }

//   @override
//   void dispose() {
//     // Save final position
//     if (_controller.value.isReady) {
//       final position = _controller.value.position.inSeconds;
//       _saveProgress(position);
//     }
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.video.title,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share),
//             onPressed: () {
//               Clipboard.setData(
//                 ClipboardData(
//                   text:
//                       'https://www.youtube.com/watch?v=${widget.video.videoId}',
//                 ),
//               );
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Video link copied to clipboard')),
//               );
//             },
//             tooltip: 'Share',
//           ),
//         ],
//       ),
//       body: _isInitialized
//           ? Column(
//               children: [
//                 YoutubePlayer(
//                   controller: _controller,
//                   showVideoProgressIndicator: true,
//                   progressIndicatorColor: Theme.of(context).colorScheme.primary,
//                   progressColors: ProgressBarColors(
//                     playedColor: Theme.of(context).colorScheme.primary,
//                     handleColor: Theme.of(context).colorScheme.primary,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.speed),
//                       const SizedBox(width: 8),
//                       const Text('Playback Speed:'),
//                       const Spacer(),
//                       DropdownButton<double>(
//                         value: _playbackSpeed,
//                         items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
//                           return DropdownMenuItem(
//                             value: speed,
//                             child: Text('${speed}x'),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           if (value != null) {
//                             setState(() {
//                               _playbackSpeed = value;
//                             });
//                             _controller.setPlaybackRate(value);
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.video.title,
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                         const SizedBox(height: 8),
//                         if (widget.video.channelName != null) ...[
//                           Row(
//                             children: [
//                               const Icon(Icons.account_circle, size: 16),
//                               const SizedBox(width: 8),
//                               Text(
//                                 widget.video.channelName!,
//                                 style: Theme.of(context).textTheme.titleMedium,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                         ],
//                         if (widget.video.description != null) ...[
//                           const Divider(),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.video.description!,
//                             style: Theme.of(context).textTheme.bodyMedium,
//                           ),
//                         ],
//                         const SizedBox(height: 24),
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.thumb_up_outlined),
//                               onPressed: () {},
//                             ),
//                             const Text('Like'),
//                             const SizedBox(width: 24),
//                             IconButton(
//                               icon: const Icon(Icons.comment_outlined),
//                               onPressed: () {},
//                             ),
//                             const Text('Comments'),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : const Center(child: CircularProgressIndicator()),
//     );
//   }
// }
