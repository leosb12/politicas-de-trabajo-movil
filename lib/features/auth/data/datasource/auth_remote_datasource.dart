import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);

  Future<void> register(RegisterRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;
  static const Duration _authConnectTimeout = Duration(seconds: 4);
  static const Duration _authSendTimeout = Duration(minutes: 2);
  static const Duration _authReceiveTimeout = Duration(minutes: 2);
  static const int _authMaxAlternativeBaseUrls = 1;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.mobileLoginPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );

      return _parseLoginResponse(response.data);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    try {
      await _dio.post(
        NetworkConstants.mobileRegisterPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  LoginResponseModel _parseLoginResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return LoginResponseModel.fromJson(data);
  }

  Options _authRequestOptions() {
    return Options(
      contentType: Headers.jsonContentType,
      connectTimeout: _authConnectTimeout,
      sendTimeout: _authSendTimeout,
      receiveTimeout: _authReceiveTimeout,
      extra: const <String, dynamic>{
        ApiClient.maxAlternativeBaseUrlsExtraKey:
            _authMaxAlternativeBaseUrls,
      },
    );
  }
}
