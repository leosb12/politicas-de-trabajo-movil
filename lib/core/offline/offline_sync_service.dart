import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_failure.dart';
import 'health_check_service.dart';
import 'mobile_snapshot_store.dart';
import 'offline_queue_store.dart';

/// Estado del proceso de sincronización.
enum SyncState { idle, syncing, completed, error }

/// Servicio de sincronización automática.
/// Escucha cuando el backend vuelve a estar disponible y procesa la cola FIFO.
class OfflineSyncService extends StateNotifier<SyncState> {
  OfflineSyncService({
    required Dio dio,
    required ConnectivityNotifier connectivity,
    required OfflineQueueStore queue,
    required MobileSnapshotStore snapshotStore,
  })  : _dio = dio,
        _connectivity = connectivity,
        _queue = queue,
        _snapshotStore = snapshotStore,
        super(SyncState.idle) {
    // Escuchar cambios de conectividad via stream de StateNotifier
    _subscription = connectivity.stream.listen((bool isOnline) {
      if (isOnline && !_processing) {
        developer.log(
          '[SYNC] Backend is back online — starting queue processing',
          name: 'OfflineSyncService',
        );
        _processPendingQueue();
      }
    });
    // Si ya estamos online al iniciar, procesar cola
    if (connectivity.isOnline) {
      _processPendingQueue();
    }
  }

  final Dio _dio;
  final ConnectivityNotifier _connectivity;
  final OfflineQueueStore _queue;
  final MobileSnapshotStore _snapshotStore;

  bool _processing = false;
  late final StreamSubscription<bool> _subscription;

  /// Mapa de localId → realId para resolver dependencias durante sync.
  final Map<String, String> _localToRealIdMap = <String, String>{};

  /// Procesa la cola en orden FIFO.
  Future<void> _processPendingQueue() async {
    if (_processing) return;

    final List<OfflineQueueItem> items = _queue.getAll();
    if (items.isEmpty) {
      state = SyncState.idle;
      return;
    }

    developer.log(
      '[SYNC] Processing ${items.length} queued operations',
      name: 'OfflineSyncService',
    );
    _processing = true;
    state = SyncState.syncing;

    int successCount = 0;
    int errorCount = 0;

    for (final OfflineQueueItem item in items) {
      if (!_connectivity.isOnline) {
        developer.log(
          '[SYNC] Lost connection during processing — stopping',
          name: 'OfflineSyncService',
        );
        break;
      }

      try {
        await _processItem(item);
        await _queue.markSynced(item.id);
        successCount++;
      } on ApiFailure catch (failure) {
        developer.log(
          '[SYNC] ApiFailure for item ${item.id}: ${failure.message} status=${failure.statusCode}',
          name: 'OfflineSyncService',
        );
        // 4xx = error de negocio → marcar como fallido permanente
        if ((failure.statusCode ?? 0) >= 400 &&
            (failure.statusCode ?? 0) < 500) {
          await _queue.markFailed(item.id, failure.message);
        }
        // 5xx o red → dejar en cola para retry
        errorCount++;
      } catch (e) {
        developer.log(
          '[SYNC] Unexpected error for item ${item.id}: $e',
          name: 'OfflineSyncService',
        );
        errorCount++;
      }
    }

    _processing = false;

    developer.log(
      '[SYNC] Done: success=$successCount errors=$errorCount remaining=${_queue.pendingCount}',
      name: 'OfflineSyncService',
    );

    if (errorCount == 0 && _queue.pendingCount == 0) {
      state = SyncState.completed;
    } else if (errorCount > 0) {
      state = SyncState.error;
    } else {
      state = SyncState.idle;
    }
  }

  Future<void> _processItem(OfflineQueueItem item) async {
    developer.log(
      '[SYNC] Processing item id=${item.id} type=${item.entityType} endpoint=${item.endpoint}',
      name: 'OfflineSyncService',
    );

    // Resolver localInstanciaId si existe
    Map<String, dynamic>? resolvedBody = item.body != null
        ? Map<String, dynamic>.from(item.body!)
        : null;

    if (item.localInstanciaId != null &&
        _localToRealIdMap.containsKey(item.localInstanciaId)) {
      final String realInstanciaId =
          _localToRealIdMap[item.localInstanciaId]!;
      resolvedBody ??= <String, dynamic>{};
      resolvedBody['instanciaId'] = realInstanciaId;

      developer.log(
        '[SYNC] Resolved localInstanciaId=${item.localInstanciaId} → $realInstanciaId',
        name: 'OfflineSyncService',
      );
    }

    final Map<String, String> headers = Map<String, String>.from(item.headers);

    final Response<dynamic> response = await _executeRequest(
      method: item.method,
      endpoint: item.endpoint,
      body: resolvedBody,
      headers: headers,
    );

    // Si era INSTANCIA_TRAMITE, registrar el id real
    if (item.entityType == OfflineEntityType.instanciaTramite &&
        item.localId != null) {
      final dynamic responseData = response.data;
      final String? realId = _extractId(responseData);
      if (realId != null && realId.isNotEmpty) {
        _localToRealIdMap[item.localId!] = realId;
        developer.log(
          '[SYNC] Registered localId=${item.localId} → realId=$realId',
          name: 'OfflineSyncService',
        );

        // Actualizar snapshot con el id real
        await _snapshotStore.resolveTramiteLocalId(
          userId: item.userId,
          localId: item.localId!,
          realData: responseData is Map<String, dynamic>
              ? responseData
              : <String, dynamic>{'id': realId},
        );
      }
    }
  }

  Future<Response<dynamic>> _executeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final Options options = Options(headers: headers);

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          return await _dio.post<dynamic>(endpoint, data: body, options: options);
        case 'PUT':
          return await _dio.put<dynamic>(endpoint, data: body, options: options);
        case 'PATCH':
          return await _dio.patch<dynamic>(endpoint, data: body, options: options);
        case 'DELETE':
          return await _dio.delete<dynamic>(endpoint, data: body, options: options);
        default:
          return await _dio.post<dynamic>(endpoint, data: body, options: options);
      }
    } on DioException catch (e) {
      throw ApiFailure.fromDioException(e);
    }
  }

  String? _extractId(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['id']?.toString();
    }
    return null;
  }

  /// Fuerza el procesamiento de la cola (para pruebas o reconexión manual).
  Future<void> forceSyncNow() async {
    if (!_connectivity.isOnline) return;
    await _processPendingQueue();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
