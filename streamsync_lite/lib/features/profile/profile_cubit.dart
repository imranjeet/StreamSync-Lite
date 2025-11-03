import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection.dart';
import '../../core/network/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final SharedPreferences _prefs = getIt<SharedPreferences>();
  final ApiClient _apiClient = getIt<ApiClient>();

  ProfileCubit() : super(ProfileState.initial());

  Future<void> initialize() async {
    final themeMode = _prefs.getString('theme_mode');
    final isDark = themeMode == 'dark';
    final userName = _prefs.getString('user_name');
    final userEmail = _prefs.getString('user_email');

    emit(state.copyWith(isDarkMode: isDark, userName: userName, userEmail: userEmail));

    await _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final userId = _prefs.getString('user_id');
        if (userId != null) {
          await _apiClient.dio.post('/users/$userId/fcmToken', data: {
            'token': fcmToken,
            'platform': 'android',
          });
        }
      }
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> toggleTheme() async {
    final newMode = !state.isDarkMode;
    await _prefs.setString('theme_mode', newMode ? 'dark' : 'light');
    emit(state.copyWith(isDarkMode: newMode));
  }

  Future<void> sendTestPush(String title, String body) async {
    emit(state.copyWith(isSending: true, successMessage: null, errorMessage: null));
    try {
      final idempotencyKey = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await _apiClient.dio.post(
        '/notifications/send-test',
        data: {
          'title': title.trim(),
          'body': body.trim(),
          'idempotencyKey': idempotencyKey,
        },
      );

      emit(state.copyWith(
        isSending: false,
        successMessage: response.data['message'] ?? 'Test push sent',
      ));
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }
}


