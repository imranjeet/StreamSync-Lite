import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:streamsync_lite/core/sync/sync_service.dart';
import 'package:streamsync_lite/features/home/home_repository.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/di/injection.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_event.dart';
import 'features/home/home_bloc.dart';
import 'features/theme/theme_bloc.dart';
import 'features/theme/theme_state.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'core/notifications/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/hive_adapter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
  }

  try {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }

    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.saveNotification(message);
  } catch (e) {
    if (kDebugMode) {
      print('Error handling background notification: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final notificationService = NotificationService();
    await notificationService.initialize();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message: ${message.notification?.title}');
      }

      notificationService.saveNotification(message);
    });
    // Core services
    getIt.registerLazySingleton<SyncService>(() => SyncService());

    // Repositories
    getIt.registerLazySingleton<HomeRepository>(() => HomeRepository());
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _splashDelayDone = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _splashDelayDone = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckStatus())),
        BlocProvider(create: (_) => HomeBloc()),
        BlocProvider(create: (_) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          ThemeMode themeMode = ThemeMode.system;
          if (themeState is ThemeLoaded) {
            themeMode = themeState.themeMode;
          } else if (themeState is ThemeInitial) {
            themeMode = themeState.themeMode;
          }

          return MaterialApp(
            title: 'StreamSync Lite',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeMode,
            home: !_splashDelayDone
                ? const SplashScreen()
                : BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading || state is AuthInitial) {
                        return const SplashScreen();
                      } else if (state is AuthAuthenticated) {
                        return const MainNavigation();
                      } else {
                        return const LoginScreen();
                      }
                    },
                  ),
          );
        },
      ),
    );
  }
}
