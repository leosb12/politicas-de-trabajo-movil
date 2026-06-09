import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

/// Tipos de entidades en la cola offline.
class OfflineEntityType {
  const OfflineEntityType._();

  static const String instanciaTramite = 'INSTANCIA_TRAMITE';
  static const String tareaCompletar = 'TAREA_COMPLETAR';
  static const String formDraft = 'FORM_DRAFT';
  static const String documentoMetadata = 'DOCUMENTO_METADATA';
}

/// Estados de un item en la cola.
class OfflineQueueStatus {
  const OfflineQueueStatus._();

  static const String pending = 'PENDING';
  static const String failedPermanent = 'FAILED_PERMANENT';
}

/// Representa una operación pendiente de sincronización.
class OfflineQueueItem {
  const OfflineQueueItem({
    required this.id,
    required this.method,
    required this.endpoint,
    required this.entityType,
    required this.userId,
    this.body,
    this.headers = const <String, String>{},
    this.localId,
    this.localInstanciaId,
    this.status = OfflineQueueStatus.pending,
    required this.createdAt,
  });

  /// UUID único del item en cola.
  final String id;

  /// HTTP method: POST, PUT, PATCH, DELETE.
  final String method;

  /// Endpoint relativo, ej: '/api/instancias'.
  final String endpoint;

  /// Tipo de entidad para resolución de dependencias.
  final String entityType;

  /// userId que genera la operación.
  final String userId;

  /// Cuerpo de la request.
  final Map<String, dynamic>? body;

  /// Headers adicionales (ej: X-User-Id).
  final Map<String, String> headers;

  /// ID local temporal si la entidad fue creada offline.
  final String? localId;

  /// ID de la instancia local, si la tarea depende de una instancia offline.
  final String? localInstanciaId;

  /// Estado: PENDING o FAILED_PERMANENT.
  final String status;

  /// Timestamp de creación (para orden FIFO).
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'method': method,
    'endpoint': endpoint,
    'entityType': entityType,
    'userId': userId,
    'body': body,
    'headers': headers,
    'localId': localId,
    'localInstanciaId': localInstanciaId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'] as String? ?? '',
      method: json['method'] as String? ?? 'POST',
      endpoint: json['endpoint'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      body: json['body'] is Map<String, dynamic>
          ? json['body'] as Map<String, dynamic>
          : null,
      headers: (json['headers'] as Map?)
              ?.map((dynamic k, dynamic v) =>
                  MapEntry<String, String>(k.toString(), v.toString())) ??
          <String, String>{},
      localId: json['localId'] as String?,
      localInstanciaId: json['localInstanciaId'] as String?,
      status: json['status'] as String? ?? OfflineQueueStatus.pending,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }

  OfflineQueueItem copyWith({String? status}) {
    return OfflineQueueItem(
      id: id,
      method: method,
      endpoint: endpoint,
      entityType: entityType,
      userId: userId,
      body: body,
      headers: headers,
      localId: localId,
      localInstanciaId: localInstanciaId,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

/// Cola offline FIFO para operaciones pendientes de sincronización.
class OfflineQueueStore {
  OfflineQueueStore({
    required Box<String> queueBox,
    required Box<String> conflictsBox,
  })  : _queueBox = queueBox,
        _conflictsBox = conflictsBox;

  final Box<String> _queueBox;
  final Box<String> _conflictsBox;

  /// Agrega una operación a la cola.
  Future<void> enqueue(OfflineQueueItem item) async {
    await _queueBox.put(item.id, jsonEncode(item.toJson()));
    developer.log(
      '[QUEUE] Enqueued id=${item.id} type=${item.entityType} endpoint=${item.endpoint}',
      name: 'OfflineQueueStore',
    );
  }

  /// Obtiene todos los items pendientes, ordenados por createdAt (FIFO).
  List<OfflineQueueItem> getAll() {
    final List<OfflineQueueItem> items = <OfflineQueueItem>[];
    for (final String key in _queueBox.keys.cast<String>()) {
      final String? raw = _queueBox.get(key);
      if (raw == null) continue;
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(OfflineQueueItem.fromJson(decoded));
        }
      } catch (_) {}
    }
    items.sort((OfflineQueueItem a, OfflineQueueItem b) =>
        a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Items pendientes de un usuario específico.
  List<OfflineQueueItem> getForUser(String userId) =>
      getAll().where((OfflineQueueItem i) => i.userId == userId).toList();

  /// Cuenta de items pendientes.
  int get pendingCount => _queueBox.length;

  /// Marca un item como sincronizado (lo elimina de la cola).
  Future<void> markSynced(String id) async {
    await _queueBox.delete(id);
    developer.log('[QUEUE] Synced and removed id=$id', name: 'OfflineQueueStore');
  }

  /// Marca un item como fallido permanente (lo mueve a syncConflicts).
  Future<void> markFailed(String id, String error) async {
    final String? raw = _queueBox.get(id);
    if (raw != null) {
      // Guardar en conflictos con el error
      final Map<String, dynamic> conflict = <String, dynamic>{
        'item': jsonDecode(raw),
        'error': error,
        'failedAt': DateTime.now().toIso8601String(),
      };
      await _conflictsBox.put(id, jsonEncode(conflict));
    }
    await _queueBox.delete(id);
    developer.log('[QUEUE] Marked FAILED_PERMANENT id=$id error=$error', name: 'OfflineQueueStore');
  }

  /// Lista los conflictos de sincronización.
  List<Map<String, dynamic>> getConflicts() {
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    for (final String key in _conflictsBox.keys.cast<String>()) {
      final String? raw = _conflictsBox.get(key);
      if (raw == null) continue;
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result.add(decoded);
        }
      } catch (_) {}
    }
    return result;
  }

  int get conflictsCount => _conflictsBox.length;
}
