import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          // Mobile networks + a remote HTTPS endpoint mean a cold first request
          // (DNS + TLS handshake) can exceed a tight budget and surface as a
          // spurious "network request failed" on login/switch/save. 20s is
          // forgiving enough for those while still bounding genuine hangs.
          // (AI endpoints override receiveTimeout to 60s for slow LLM calls.)
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final Dio dio;

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
      return;
    }
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
