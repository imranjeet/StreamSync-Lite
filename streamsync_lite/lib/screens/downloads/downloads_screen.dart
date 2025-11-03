import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/models/video.dart';
import '../video_player/video_player_screen.dart';
import 'package:streamsync_lite/features/downloads/downloads_cubit.dart';
import 'package:streamsync_lite/features/downloads/downloads_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadsCubit()..initialize(),
      child: Scaffold(
        appBar: const _DownloadsAppBar(),
        body: BlocConsumer<DownloadsCubit, DownloadsState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
              context.read<DownloadsCubit>().clearMessages();
            }

            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              context.read<DownloadsCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!state.isInitialized) {
              return const Center(
                child: Text('Failed to initialize downloads'),
              );
            }

            if (state.cachedVideos.isEmpty) {
              return const _EmptyState();
            }

            return _DownloadsList(cachedVideos: state.cachedVideos);
          },
        ),
      ),
    );
  }
}

class _DownloadsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DownloadsAppBar();

  @override
  Widget build(BuildContext context) {
    final hasVideos = context
        .watch<DownloadsCubit>()
        .state
        .cachedVideos
        .isNotEmpty;
    final isClearing = context.watch<DownloadsCubit>().state.isClearing;

    return AppBar(
      title: const Text('Downloads / Cache'),
      actions: [
        if (hasVideos && !isClearing)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<DownloadsCubit>().clearCache(),
            tooltip: 'Clear Cache',
          ),
        if (isClearing)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No cached videos',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Videos you download will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsList extends StatelessWidget {
  final List<Video> cachedVideos;

  const _DownloadsList({required this.cachedVideos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: cachedVideos.length,
      itemBuilder: (context, index) {
        final video = cachedVideos[index];
        return _DownloadItem(video: video);
      },
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final Video video;

  const _DownloadItem({required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            video.thumbnailUrl,
            width: 80,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 60,
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.video_library,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        title: Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: ${video.formattedDuration}',
              style: theme.textTheme.bodySmall,
            ),
            if (video.channelName != null)
              Text(
                video.channelName!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(context, video),
              tooltip: 'Remove from cache',
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Video video) {
    // Store the cubit reference BEFORE showing the dialog
    final cubit = context.read<DownloadsCubit>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Video'),
        content: const Text(
          'Are you sure you want to remove this video from cache?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Use the stored cubit reference
              cubit.removeVideo(video);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
