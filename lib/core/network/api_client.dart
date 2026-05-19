import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 40),
            sendTimeout: const Duration(seconds: 25),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await TokenStorage.readToken();

              if (token != null && token.trim().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
            onError: (error, handler) {
              handler.next(error);
            },
          ),
        );
}
