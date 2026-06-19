import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';

class ProfileApi {
  ProfileApi._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    try {
      final response = await _dio.get(
        '/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Gagal mengambil profile.');
      }

      return data;
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
    };

    if (password != null && password.trim().isNotEmpty) {
      payload['current_password'] = currentPassword ?? '';
      payload['password'] = password;
      payload['password_confirmation'] = passwordConfirmation ?? '';
    }

    try {
      /*
       * Backend menyediakan:
       * - PUT /api/user/profile
       * - PATCH /api/user/profile
       * - POST /api/user/profile/update
       *
       * POST dipakai agar aman untuk emulator/mobile/proxy.
       */
      final response = await _dio.post(
        '/user/profile/update',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Gagal memperbarui profile.');
      }

      return data;
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  static String _messageFromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final errors = responseData['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }

        return first.toString();
      }

      final message = responseData['message'];

      if (message != null) {
        return message.toString();
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Sesi login sudah habis. Silakan login ulang.';
    }

    if (error.response?.statusCode == 404) {
      return 'Endpoint profile mobile belum ditemukan. Pastikan route API profile sudah dipasang.';
    }

    return error.message ?? 'Terjadi kesalahan koneksi.';
  }
}
