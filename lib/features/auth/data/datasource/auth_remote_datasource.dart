import 'dart:convert';

import 'package:dio/dio.dart';

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

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final List<String> candidateBaseUrls = NetworkConstants.candidateBaseUrls(
      currentBaseUrl: _dio.options.baseUrl,
    );

    final List<Future<_LoginAttemptResult>> attempts = candidateBaseUrls
        .map((baseUrl) => _attemptLogin(baseUrl: baseUrl, request: request))
        .toList(growable: false);

    final List<_LoginAttemptResult> results = await Future.wait(attempts);

    for (final _LoginAttemptResult result in results) {
      final LoginResponseModel? model = result.model;
      if (model == null) {
        continue;
      }

      _dio.options.baseUrl = result.baseUrl;
      return model;
    }

    final ApiFailure? firstFatalFailure = results
        .map((result) => result.fatalFailure)
        .whereType<ApiFailure>()
        .cast<ApiFailure?>()
        .firstWhere((failure) => failure != null, orElse: () => null);

    if (firstFatalFailure != null) {
      throw firstFatalFailure;
    }

    final DioException? lastRetryableException = results
        .map((result) => result.retryableException)
        .whereType<DioException>()
        .cast<DioException?>()
        .lastWhere((exception) => exception != null, orElse: () => null);

    if (lastRetryableException != null) {
      throw ApiFailure.fromDioException(lastRetryableException);
    }

    throw ApiFailure(
      message: 'No se encontro una URL base valida para el backend.',
    );
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    final List<String> candidateBaseUrls = NetworkConstants.candidateBaseUrls(
      currentBaseUrl: _dio.options.baseUrl,
    );

    final List<Future<_RegisterAttemptResult>> attempts = candidateBaseUrls
        .map((baseUrl) => _attemptRegister(baseUrl: baseUrl, request: request))
        .toList(growable: false);

    final List<_RegisterAttemptResult> results = await Future.wait(attempts);

    for (final _RegisterAttemptResult result in results) {
      if (!result.success) {
        continue;
      }

      _dio.options.baseUrl = result.baseUrl;
      return;
    }

    final ApiFailure? firstFatalFailure = results
        .map((result) => result.fatalFailure)
        .whereType<ApiFailure>()
        .cast<ApiFailure?>()
        .firstWhere((failure) => failure != null, orElse: () => null);

    if (firstFatalFailure != null) {
      throw firstFatalFailure;
    }

    final DioException? lastRetryableException = results
        .map((result) => result.retryableException)
        .whereType<DioException>()
        .cast<DioException?>()
        .lastWhere((exception) => exception != null, orElse: () => null);

    if (lastRetryableException != null) {
      throw ApiFailure.fromDioException(lastRetryableException);
    }

    throw ApiFailure(
      message: 'No se encontro una URL base valida para el backend.',
    );
  }

  Future<_LoginAttemptResult> _attemptLogin({
    required String baseUrl,
    required LoginRequestModel request,
  }) async {
    final Dio dio = _buildDioFor(baseUrl: baseUrl);

    try {
      final Response<dynamic> response = await dio.post(
        NetworkConstants.mobileLoginPath,
        data: jsonEncode(request.toJson()),
        options: Options(contentType: Headers.jsonContentType),
      );

      return _LoginAttemptResult.success(
        baseUrl: baseUrl,
        model: _parseLoginResponse(response.data),
      );
    } on DioException catch (exception) {
      if (_isRetryableNetworkError(exception)) {
        return _LoginAttemptResult.retryable(
          baseUrl: baseUrl,
          exception: exception,
        );
      }

      return _LoginAttemptResult.fatal(
        baseUrl: baseUrl,
        failure: ApiFailure.fromDioException(exception),
      );
    } on ApiFailure catch (failure) {
      return _LoginAttemptResult.fatal(baseUrl: baseUrl, failure: failure);
    }
  }

  Future<_RegisterAttemptResult> _attemptRegister({
    required String baseUrl,
    required RegisterRequestModel request,
  }) async {
    final Dio dio = _buildDioFor(baseUrl: baseUrl);

    try {
      await dio.post(
        NetworkConstants.mobileRegisterPath,
        data: jsonEncode(request.toJson()),
        options: Options(contentType: Headers.jsonContentType),
      );

      return _RegisterAttemptResult.success(baseUrl: baseUrl);
    } on DioException catch (exception) {
      if (_isRetryableNetworkError(exception)) {
        return _RegisterAttemptResult.retryable(
          baseUrl: baseUrl,
          exception: exception,
        );
      }

      return _RegisterAttemptResult.fatal(
        baseUrl: baseUrl,
        failure: ApiFailure.fromDioException(exception),
      );
    } on ApiFailure catch (failure) {
      return _RegisterAttemptResult.fatal(baseUrl: baseUrl, failure: failure);
    }
  }

  Dio _buildDioFor({required String baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
        headers: Map<String, dynamic>.from(_dio.options.headers),
      ),
    );
  }

  LoginResponseModel _parseLoginResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return LoginResponseModel.fromJson(data);
  }

  bool _isRetryableNetworkError(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return false;
    }
  }
}

class _LoginAttemptResult {
  const _LoginAttemptResult._({
    required this.baseUrl,
    this.model,
    this.retryableException,
    this.fatalFailure,
  });

  final String baseUrl;
  final LoginResponseModel? model;
  final DioException? retryableException;
  final ApiFailure? fatalFailure;

  factory _LoginAttemptResult.success({
    required String baseUrl,
    required LoginResponseModel model,
  }) {
    return _LoginAttemptResult._(baseUrl: baseUrl, model: model);
  }

  factory _LoginAttemptResult.retryable({
    required String baseUrl,
    required DioException exception,
  }) {
    return _LoginAttemptResult._(
      baseUrl: baseUrl,
      retryableException: exception,
    );
  }

  factory _LoginAttemptResult.fatal({
    required String baseUrl,
    required ApiFailure failure,
  }) {
    return _LoginAttemptResult._(baseUrl: baseUrl, fatalFailure: failure);
  }
}

class _RegisterAttemptResult {
  const _RegisterAttemptResult._({
    required this.baseUrl,
    required this.success,
    this.retryableException,
    this.fatalFailure,
  });

  final String baseUrl;
  final bool success;
  final DioException? retryableException;
  final ApiFailure? fatalFailure;

  factory _RegisterAttemptResult.success({required String baseUrl}) {
    return _RegisterAttemptResult._(baseUrl: baseUrl, success: true);
  }

  factory _RegisterAttemptResult.retryable({
    required String baseUrl,
    required DioException exception,
  }) {
    return _RegisterAttemptResult._(
      baseUrl: baseUrl,
      success: false,
      retryableException: exception,
    );
  }

  factory _RegisterAttemptResult.fatal({
    required String baseUrl,
    required ApiFailure failure,
  }) {
    return _RegisterAttemptResult._(
      baseUrl: baseUrl,
      success: false,
      fatalFailure: failure,
    );
  }
}
