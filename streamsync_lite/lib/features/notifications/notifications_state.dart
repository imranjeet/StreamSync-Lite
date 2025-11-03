import 'package:equatable/equatable.dart';
import '../../shared/models/notification.dart';

class NotificationsState extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsState({
    required this.notifications,
    required this.unreadCount,
    required this.isLoading,
    this.errorMessage,
  });

  factory NotificationsState.initial() => const NotificationsState(
        notifications: [],
        unreadCount: 0,
        isLoading: true,
        errorMessage: null,
      );

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, isLoading, errorMessage];
}


