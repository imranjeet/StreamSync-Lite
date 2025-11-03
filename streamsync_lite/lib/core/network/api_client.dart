import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiClient {
  late Dio _dio;
  // Use 10.0.2.2 for Android emulator, localhost for iOS
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://streamsync-backend.vercel.app';
    }
    return 'https://streamsync-backend.vercel.app'; // Change for production
  }

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Add retry metadata if not present
        if (options.extra['retryCount'] == null) {
          options.extra['retryCount'] = 0;
        }
        
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 - token refresh
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');
          
          if (refreshToken != null) {
            try {
              final response = await _dio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });
              
              if (response.statusCode == 200) {
                final data = response.data['data'];
                await prefs.setString('access_token', data['accessToken']);
                await prefs.setString('refresh_token', data['refreshToken']);
                
                // Retry original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
                final retryResponse = await _dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                );
                handler.resolve(retryResponse);
                return;
              }
            } catch (e) {
              // Refresh failed, redirect to login
              handler.next(error);
            }
          } else {
            handler.next(error);
        }
          return;
        }
        
        // Exponential backoff retry for network errors and 5xx errors
        final requestOptions = error.requestOptions;
        final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;
        const maxRetries = 3;
        
        // Retry on network errors or 5xx server errors (not 4xx client errors)
        if (retryCount < maxRetries && 
            (error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.connectionError ||
             (error.response?.statusCode != null && error.response!.statusCode! >= 500 && error.response!.statusCode! < 600))) {
          
          // Exponential backoff: 2^retryCount seconds
          final delaySeconds = 1 << retryCount; // 1, 2, 4 seconds
          
          await Future.delayed(Duration(seconds: delaySeconds));
          
          // Retry the request
          requestOptions.extra['retryCount'] = retryCount + 1;
          
          try {
            final retryResponse = await _dio.request(
              requestOptions.path,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
                extra: requestOptions.extra,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );
            handler.resolve(retryResponse);
            return;
          } catch (e) {
            // If retry also fails, continue with error chain
          }
        }
        
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}

