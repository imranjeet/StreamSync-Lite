import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'downloads/downloads_screen.dart';
import 'profile/profile_screen.dart';
import '../../shared/models/notification.dart';
import '../../core/notifications/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  Box<AppNotification>? _notificationBox;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
    const DownloadsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    _notificationBox = notificationService.notificationBox;
    
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _notificationBox == null
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: 'Notifications',
                ),
                NavigationDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: 'Downloads',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : ValueListenableBuilder(
              valueListenable: _notificationBox!.listenable(),
              builder: (context, box, _) {
                final unreadCount = _notificationBox!.values
                    .where((n) => !n.isRead && !n.isDeleted)
                    .length;

                return NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: unreadCount > 0
                          ? Badge(
                              label: Text('$unreadCount'),
                              child: const Icon(Icons.notifications_outlined),
                            )
                          : const Icon(Icons.notifications_outlined),
                      selectedIcon: unreadCount > 0
                          ? Badge(
                              label: Text('$unreadCount'),
                              child: const Icon(Icons.notifications),
                            )
                          : const Icon(Icons.notifications),
                      label: 'Notifications',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.download_outlined),
                      selectedIcon: Icon(Icons.download),
                      label: 'Downloads',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                );
              },
            ),
    );
  }
}

