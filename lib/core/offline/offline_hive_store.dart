import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

/// Nombres de cajas Hive usadas en modo offline.
class HiveBoxNames {
  const HiveBoxNames._();

  static const String offlineAuthProfiles = 'offlineAuthProfiles';
  static const String mobileSnapshot = 'mobileSnapshot';
  static const String offlineQueue = 'offlineQueue';
  static const String syncConflicts = 'syncConflicts';
}

/// Inicializa Hive y abre todas las cajas necesarias.
/// Debe llamarse en main() antes de runApp().
class OfflineHiveStore {
  OfflineHiveStore._();

  static Box<String>? _authProfilesBox;
  static Box<String>? _snapshotBox;
  static Box<String>? _queueBox;
  static Box<String>? _conflictsBox;

  static bool _initialized = false;

  static Box<String> get authProfilesBox => _assertOpen(_authProfilesBox, HiveBoxNames.offlineAuthProfiles);
  static Box<String> get snapshotBox => _assertOpen(_snapshotBox, HiveBoxNames.mobileSnapshot);
  static Box<String> get queueBox => _assertOpen(_queueBox, HiveBoxNames.offlineQueue);
  static Box<String> get conflictsBox => _assertOpen(_conflictsBox, HiveBoxNames.syncConflicts);

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;

    developer.log('[HIVE] Initializing Hive for offline storage', name: 'OfflineHiveStore');

    await Hive.initFlutter();

    _authProfilesBox = await Hive.openBox<String>(HiveBoxNames.offlineAuthProfiles);
    _snapshotBox = await Hive.openBox<String>(HiveBoxNames.mobileSnapshot);
    _queueBox = await Hive.openBox<String>(HiveBoxNames.offlineQueue);
    _conflictsBox = await Hive.openBox<String>(HiveBoxNames.syncConflicts);

    _initialized = true;

    developer.log(
      '[HIVE] Initialized — profiles=${_authProfilesBox!.length} '
      'snapshots=${_snapshotBox!.length} '
      'queue=${_queueBox!.length}',
      name: 'OfflineHiveStore',
    );
  }

  static Box<String> _assertOpen(Box<String>? box, String name) {
    if (box == null || !box.isOpen) {
      throw StateError('Hive box "$name" is not open. Call OfflineHiveStore.init() first.');
    }
    return box;
  }

  /// Serializa un objeto a JSON y lo guarda en una caja.
  static Future<void> putJson(Box<String> box, String key, dynamic value) async {
    await box.put(key, jsonEncode(value));
  }

  /// Lee un objeto JSON de una caja. Retorna null si no existe o falla el parse.
  static dynamic getJson(Box<String> box, String key) {
    final String? raw = box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
