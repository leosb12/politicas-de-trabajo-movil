import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl, List<String>? fallbackBaseUrls})
    : this._(
        baseUrls: _buildBaseUrls(
          baseUrl: baseUrl,
          fallbackBaseUrls: fallbackBaseUrls,
        ),
      );

  ApiClient._({required List<String> baseUrls})
    : _baseUrls = baseUrls,
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrls.first,
          connectTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          responseType: ResponseType.json,
          headers: const <String, String>{'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError:
            (DioException exception, ErrorInterceptorHandler handler) async {
              if (!_shouldRetryWithAlternativeBaseUrl(exception)) {
                handler.next(exception);
                return;
              }

              final RequestOptions requestOptions = exception.requestOptions;
              final int currentIndex = _currentBaseUrlIndex(requestOptions);
              final int maxAlternativeBaseUrls = _maxAlternativeBaseUrls(
                requestOptions,
              );
              final int lastRetryIndex = math.min(
                _baseUrls.length - 1,
                currentIndex + maxAlternativeBaseUrls,
              );
              if (currentIndex >= _baseUrls.length - 1) {
                handler.next(exception);
                return;
              }

              for (
                int index = currentIndex + 1;
                index <= lastRetryIndex;
                index++
              ) {
                final String candidateBaseUrl = _baseUrls[index];

                try {
                  final Response<dynamic> response =
                      await _createRetryDio(candidateBaseUrl).fetch<dynamic>(
                        requestOptions.copyWith(
                          baseUrl: candidateBaseUrl,
                          path: _relativePath(requestOptions.path),
                          extra: <String, dynamic>{
                            ...requestOptions.extra,
                            _baseUrlCandidateIndexKey: index,
                          },
                        ),
                      );

                  dio.options.baseUrl = candidateBaseUrl;
                  debugPrint(
                    'ApiClient switched baseUrl to $candidateBaseUrl after '
                    '${exception.type.name} on ${requestOptions.uri}',
                  );
                  handler.resolve(response);
                  return;
                } on DioException catch (retryException) {
                  if (!_shouldRetryWithAlternativeBaseUrl(retryException)) {
                    handler.next(retryException);
                    return;
                  }

                  if (index == _baseUrls.length - 1) {
                    handler.next(retryException);
                    return;
                  }
                }
              }

              handler.next(exception);
            },
      ),
    );
  }

  final Dio dio;
  final List<String> _baseUrls;

  static const String _baseUrlCandidateIndexKey =
      'api_client.base_url_candidate_index';
  static const String maxAlternativeBaseUrlsExtraKey =
      'api_client.max_alternative_base_urls';

  void setAuthToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      dio.options.headers.remove('Authorization');
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static List<String> _buildBaseUrls({
    required String baseUrl,
    List<String>? fallbackBaseUrls,
  }) {
    final List<String> resolved = <String>[];

    void addCandidate(String rawUrl) {
      final String normalized = _normalizeBaseUrl(rawUrl);
      if (normalized.isEmpty || resolved.contains(normalized)) {
        return;
      }

      resolved.add(normalized);
    }

    addCandidate(baseUrl);

    for (final String fallbackBaseUrl in fallbackBaseUrls ?? <String>[]) {
      addCandidate(fallbackBaseUrl);
    }

    if (resolved.isEmpty) {
      throw ArgumentError('ApiClient requires at least one baseUrl.');
    }

    return resolved;
  }

  bool _shouldRetryWithAlternativeBaseUrl(DioException exception) {
    if (exception.response != null) {
      return false;
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return false;
    }
  }

  int _currentBaseUrlIndex(RequestOptions requestOptions) {
    final int? explicitIndex =
        requestOptions.extra[_baseUrlCandidateIndexKey] as int?;
    if (explicitIndex != null && explicitIndex >= 0) {
      return explicitIndex;
    }

    final String normalizedBaseUrl = _normalizeBaseUrl(requestOptions.baseUrl);
    final int discoveredIndex = _baseUrls.indexOf(normalizedBaseUrl);
    return discoveredIndex >= 0 ? discoveredIndex : 0;
  }

  int _maxAlternativeBaseUrls(RequestOptions requestOptions) {
    final dynamic rawValue =
        requestOptions.extra[maxAlternativeBaseUrlsExtraKey];
    if (rawValue is int && rawValue >= 0) {
      return rawValue;
    }

    return _baseUrls.length - 1;
  }

  Dio _createRetryDio(String baseUrl) {
    final BaseOptions retryOptions = dio.options.copyWith(baseUrl: baseUrl);
    final Dio retryDio = Dio(retryOptions);
    return retryDio;
  }

  static String _relativePath(String path) {
    final Uri? uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) {
      return path;
    }

    return uri.path.isEmpty ? '/' : uri.path;
  }

  static String _normalizeBaseUrl(String rawUrl) {
    return rawUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
