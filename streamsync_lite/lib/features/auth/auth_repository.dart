import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/injection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class AuthRepository {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  Future<void> _registerFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        await _apiClient.dio.post('/users/$userId/fcmToken', data: {
          'token': fcmToken,
          'platform': platform,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String name, String password) async {
    final response = await _apiClient.dio.post('/auth/register', data: {
      'email': email,
      'name': name,
      'password': password,
    });

    if (response.data['status'] == 'success') {
      final data = response.data['data'];
      await _prefs.setString('access_token', data['accessToken']);
      await _prefs.setString('refresh_token', data['refreshToken']);
      await _prefs.setString('user_id', data['user']['id']);
      
      await _registerFcmToken(data['user']['id']);
      
      return data;
    }
    throw Exception(response.data['message'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.data['status'] == 'success') {
      final data = response.data['data'];
      await _prefs.setString('access_token', data['accessToken']);
      await _prefs.setString('refresh_token', data['refreshToken']);
      await _prefs.setString('user_id', data['user']['id']);
      
      await _registerFcmToken(data['user']['id']);
      
      return data;
    }
    throw Exception(response.data['message'] ?? 'Login failed');
  }

  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('user_id');
  }

  bool isLoggedIn() {
    return _prefs.getString('access_token') != null;
  }

  String? getUserId() {
    return _prefs.getString('user_id');
  }
}

