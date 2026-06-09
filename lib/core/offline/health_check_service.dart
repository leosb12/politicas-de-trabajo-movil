import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_constants.dart';

/// Resultado del health check.
enum HealthCheckResult { online, offline }

/// Servicio que determina si el backend está disponible.
/// Usa GET /api/health con timeout corto.
/// NO depende de connectivity_plus ni WiFi.
class HealthCheckService {
  HealthCheckService(this._dio);

  final Dio _dio;

  static const Duration _checkTimeout = Duration(seconds: 4);
  static const Duration _checkInterval = Duration(seconds: 15);

  Timer? _timer;
  final StreamController<HealthCheckResult> _controller =
      StreamController<HealthCheckResult>.broadcast();

  Stream<HealthCheckResult> get stream => _controller.stream;

  HealthCheckResult _lastResult = HealthCheckResult.offline;
  HealthCheckResult get lastResult => _lastResult;

  /// Inicia el polling periódico.
  void startPolling() {
    _timer?.cancel();
    // Check inmediato
    _checkNow();
    // Luego cada 15 segundos
    _timer = Timer.periodic(_checkInterval, (_) => _checkNow());
    developer.log('[HEALTH] Polling started interval=${_checkInterval.inSeconds}s', name: 'HealthCheckService');
  }

  /// Detiene el polling.
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    developer.log('[HEALTH] Polling stopped', name: 'HealthCheckService');
  }

  /// Fuerza un check inmediato y retorna el resultado.
  Future<HealthCheckResult> checkNow() async {
    return _checkNow();
  }

  Future<HealthCheckResult> _checkNow() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        NetworkConstants.healthCheckPath,
        options: Options(
          sendTimeout: _checkTimeout,
          receiveTimeout: _checkTimeout,
          extra: const <String, dynamic>{
            // No usar fallback de baseUrls para health check
            'api_client.max_alternative_base_urls': 0,
          },
        ),
      );

      final bool success = (response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 400;

      final HealthCheckResult result =
          success ? HealthCheckResult.online : HealthCheckResult.offline;

      _emit(result);
      return result;
    } on DioException {
      _emit(HealthCheckResult.offline);
      return HealthCheckResult.offline;
    } catch (_) {
      _emit(HealthCheckResult.offline);
      return HealthCheckResult.offline;
    }
  }

  void _emit(HealthCheckResult result) {
    if (result != _lastResult) {
      developer.log(
        '[HEALTH] Status changed: ${_lastResult.name} → ${result.name}',
        name: 'HealthCheckService',
      );
    } else {
      debugPrint('[HEALTH] Status: ${result.name}');
    }
    _lastResult = result;
    _controller.add(result);
  }

  void dispose() {
    stopPolling();
    _controller.close();
  }
}

/// Notifier de conectividad. Expone si el backend está disponible.
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier(this._healthCheck) : super(true) {
    _subscription = _healthCheck.stream.listen((HealthCheckResult result) {
      final bool online = result == HealthCheckResult.online;
      if (state != online) {
        state = online;
        developer.log(
          '[CONNECTIVITY] isOnline changed to $online',
          name: 'ConnectivityNotifier',
        );
      }
    });
    _healthCheck.startPolling();
  }

  final HealthCheckService _healthCheck;
  late final StreamSubscription<HealthCheckResult> _subscription;

  bool get isOnline => state;

  @override
  void dispose() {
    _subscription.cancel();
    _healthCheck.stopPolling();
    super.dispose();
  }
}
