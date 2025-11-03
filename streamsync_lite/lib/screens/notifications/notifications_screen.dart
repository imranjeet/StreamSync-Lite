import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/notifications/notifications_cubit.dart';
import '../../features/notifications/notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..initialize(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final notifications = state.notifications;
          final unreadCount = state.unreadCount;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Notifications'),
              actions: [
                if (unreadCount > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Badge(
                        label: Text('$unreadCount'),
                        child: const Icon(Icons.notifications),
                      ),
                    ),
                  ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? const Center(child: Text('No notifications'))
                    : RefreshIndicator(
                        onRefresh: () => context.read<NotificationsCubit>().refresh(),
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return Dismissible(
                              key: Key(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16.0),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => context.read<NotificationsCubit>().deleteNotification(notification.id),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getNotificationColor(notification.metadata),
                                  child: Icon(
                                    _getNotificationIcon(notification.metadata),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: notification.isRead
                                    ? null
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                onTap: () {
                                  if (!notification.isRead) {
                                    context.read<NotificationsCubit>().markAsRead(notification.id);
                                  }
                                  if (notification.linkedContent != null) {
                                    _openLinkedContent(notification.linkedContent!);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getNotificationIcon(Map<String, dynamic>? metadata) {
    if (metadata == null) return Icons.notifications;
    final type = metadata['type'];
    switch (type) {
      case 'test':
        return Icons.send;
      case 'video':
        return Icons.video_library;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(Map<String, dynamic>? metadata) {
    if (metadata == null) return Colors.blue;
    final type = metadata['type'];
    switch (type) {
      case 'test':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'system':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<void> _openLinkedContent(String linkedContent) async {
    final uri = Uri.tryParse(linkedContent);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      }
    }
  }
}


