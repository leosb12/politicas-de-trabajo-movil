import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
          ),
        ) {
    // 🔥 LOGS DE CONFIGURACIÓN
    print('=== API CLIENT INIT ===');
    print('BASE URL: ${dio.options.baseUrl}');
    print('CONNECT TIMEOUT: ${dio.options.connectTimeout}');
    print('RECEIVE TIMEOUT: ${dio.options.receiveTimeout}');
    print('HEADERS: ${dio.options.headers}');
    print('=======================');

    // 🔥 INTERCEPTOR PARA VER TODAS LAS REQUESTS
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('=== REQUEST ===');
          print('URL: ${options.baseUrl}${options.path}');
          print('METHOD: ${options.method}');
          print('HEADERS: ${options.headers}');
          print('DATA: ${options.data}');
          print('===============');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('=== RESPONSE ===');
          print('URL: ${response.requestOptions.uri}');
          print('STATUS: ${response.statusCode}');
          print('DATA: ${response.data}');
          print('================');
          handler.next(response);
        },
        onError: (DioException e, handler) {
          print('=== DIO ERROR ===');
          print('TYPE: ${e.type}');
          print('MESSAGE: ${e.message}');
          print('STATUS: ${e.response?.statusCode}');
          print('RESPONSE: ${e.response?.data}');
          print('PATH: ${e.requestOptions.uri}');
          print('=================');
          handler.next(e);
        },
      ),
    );
  }

  final Dio dio;

  void setAuthToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      dio.options.headers.remove('Authorization');
      print('🔓 TOKEN REMOVED');
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔐 TOKEN SET: Bearer $token');
  }
}