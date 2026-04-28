import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../models/change_password_request_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/reset_password_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);

  Future<void> register(RegisterRequestModel request);

  Future<void> changePassword(ChangePasswordRequestModel request);

  Future<void> forgotPassword(ForgotPasswordRequestModel request);

  Future<void> resetPassword(ResetPasswordRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;
  static const Duration _authConnectTimeout = Duration(seconds: 4);
  static const Duration _authSendTimeout = Duration(minutes: 2);
  static const Duration _authReceiveTimeout = Duration(minutes: 2);
  static const int _authMaxAlternativeBaseUrls = 0;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final Uri resolvedUri = Uri.parse(
      _dio.options.baseUrl,
    ).resolve(NetworkConstants.mobileLoginPath);
    developer.log(
      '[AUTH][REMOTE] login request uri=$resolvedUri correo=${request.correo}',
      name: 'AuthRemoteDataSource',
    );
    print(
      '[AUTH][REMOTE] login request uri=$resolvedUri correo=${request.correo}',
    );
    try {
      final Response<dynamic> response = await _dio.post(
        NetworkConstants.mobileLoginPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );

      developer.log(
        '[AUTH][REMOTE] login response status=${response.statusCode} uri=$resolvedUri',
        name: 'AuthRemoteDataSource',
      );
      print(
        '[AUTH][REMOTE] login response status=${response.statusCode} uri=$resolvedUri',
      );

      return _parseLoginResponse(response.data);
    } on DioException catch (exception) {
      developer.log(
        '[AUTH][REMOTE] login dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
        name: 'AuthRemoteDataSource',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      print(
        '[AUTH][REMOTE] login dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
      );
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    final Uri resolvedUri = Uri.parse(
      _dio.options.baseUrl,
    ).resolve(NetworkConstants.mobileRegisterPath);
    developer.log(
      '[AUTH][REMOTE] register request uri=$resolvedUri correo=${request.correo}',
      name: 'AuthRemoteDataSource',
    );
    print(
      '[AUTH][REMOTE] register request uri=$resolvedUri correo=${request.correo}',
    );
    try {
      await _dio.post(
        NetworkConstants.mobileRegisterPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );
      developer.log(
        '[AUTH][REMOTE] register response uri=$resolvedUri',
        name: 'AuthRemoteDataSource',
      );
      print('[AUTH][REMOTE] register response uri=$resolvedUri');
    } on DioException catch (exception) {
      developer.log(
        '[AUTH][REMOTE] register dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
        name: 'AuthRemoteDataSource',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      print(
        '[AUTH][REMOTE] register dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
      );
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> changePassword(ChangePasswordRequestModel request) async {
    final Uri resolvedUri = Uri.parse(
      _dio.options.baseUrl,
    ).resolve(NetworkConstants.changePasswordPath);
    developer.log(
      '[AUTH][REMOTE] changePassword request uri=$resolvedUri correo=${request.correo}',
      name: 'AuthRemoteDataSource',
    );
    print(
      '[AUTH][REMOTE] changePassword request uri=$resolvedUri correo=${request.correo}',
    );
    try {
      await _dio.post(
        NetworkConstants.changePasswordPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );
      developer.log(
        '[AUTH][REMOTE] changePassword response uri=$resolvedUri',
        name: 'AuthRemoteDataSource',
      );
      print('[AUTH][REMOTE] changePassword response uri=$resolvedUri');
    } on DioException catch (exception) {
      developer.log(
        '[AUTH][REMOTE] changePassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
        name: 'AuthRemoteDataSource',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      print(
        '[AUTH][REMOTE] changePassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
      );
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequestModel request) async {
    final Uri resolvedUri = Uri.parse(
      _dio.options.baseUrl,
    ).resolve(NetworkConstants.forgotPasswordPath);
    developer.log(
      '[AUTH][REMOTE] forgotPassword request uri=$resolvedUri email=${request.email}',
      name: 'AuthRemoteDataSource',
    );
    print(
      '[AUTH][REMOTE] forgotPassword request uri=$resolvedUri email=${request.email}',
    );
    try {
      await _dio.post(
        NetworkConstants.forgotPasswordPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );
      developer.log(
        '[AUTH][REMOTE] forgotPassword response uri=$resolvedUri',
        name: 'AuthRemoteDataSource',
      );
      print('[AUTH][REMOTE] forgotPassword response uri=$resolvedUri');
    } on DioException catch (exception) {
      developer.log(
        '[AUTH][REMOTE] forgotPassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
        name: 'AuthRemoteDataSource',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      print(
        '[AUTH][REMOTE] forgotPassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
      );
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(ResetPasswordRequestModel request) async {
    final Uri resolvedUri = Uri.parse(
      _dio.options.baseUrl,
    ).resolve(NetworkConstants.resetPasswordPath);
    developer.log(
      '[AUTH][REMOTE] resetPassword request uri=$resolvedUri',
      name: 'AuthRemoteDataSource',
    );
    print('[AUTH][REMOTE] resetPassword request uri=$resolvedUri');
    try {
      await _dio.post(
        NetworkConstants.resetPasswordPath,
        data: jsonEncode(request.toJson()),
        options: _authRequestOptions(),
      );
      developer.log(
        '[AUTH][REMOTE] resetPassword response uri=$resolvedUri',
        name: 'AuthRemoteDataSource',
      );
      print('[AUTH][REMOTE] resetPassword response uri=$resolvedUri');
    } on DioException catch (exception) {
      developer.log(
        '[AUTH][REMOTE] resetPassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
        name: 'AuthRemoteDataSource',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      print(
        '[AUTH][REMOTE] resetPassword dio error type=${exception.type.name} '
        'status=${exception.response?.statusCode} '
        'message=${exception.message} '
        'uri=${exception.requestOptions.uri}',
      );
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
        ApiClient.maxAlternativeBaseUrlsExtraKey: _authMaxAlternativeBaseUrls,
      },
    );
  }
}
