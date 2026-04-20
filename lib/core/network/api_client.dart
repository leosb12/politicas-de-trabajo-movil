import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio dio;

  void setAuthToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      dio.options.headers.remove('Authorization');
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
