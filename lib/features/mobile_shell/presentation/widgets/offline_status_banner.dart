import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_sync_service.dart';

/// Banner global que muestra el estado de conectividad y sincronización.
/// Se integra en el AppBar o como top-banner del MobileShell.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOnline = ref.watch(isOnlineProvider);
    final SyncState syncState = ref.watch(offlineSyncServiceProvider);
    final int pendingCount = ref.watch(pendingQueueCountProvider);

    // Si está online y no hay nada pendiente → no mostrar nada
    if (isOnline && syncState == SyncState.idle && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final _BannerConfig config = _resolveBannerConfig(
      isOnline: isOnline,
      syncState: syncState,
      pendingCount: pendingCount,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      color: config.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: <Widget>[
            Icon(config.icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                config.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (syncState == SyncState.syncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _BannerConfig _resolveBannerConfig({
    required bool isOnline,
    required SyncState syncState,
    required int pendingCount,
  }) {
    if (!isOnline) {
      if (pendingCount > 0) {
        return _BannerConfig(
          color: const Color(0xFFE65100), // naranja oscuro
          icon: Icons.cloud_off_rounded,
          message: 'Sin conexión — $pendingCount cambio${pendingCount != 1 ? "s" : ""} pendientes de sincronizar',
        );
      }
      return const _BannerConfig(
        color: Color(0xFF616161), // gris
        icon: Icons.cloud_off_rounded,
        message: 'Sin conexión — usando datos guardados',
      );
    }

    if (syncState == SyncState.syncing) {
      return _BannerConfig(
        color: Colors.blue[700]!,
        icon: Icons.sync_rounded,
        message: 'Sincronizando${ pendingCount > 0 ? " ($pendingCount pendientes)" : "..."}',
      );
    }

    if (syncState == SyncState.completed) {
      return const _BannerConfig(
        color: Color(0xFF2E7D32), // verde oscuro
        icon: Icons.check_circle_outline_rounded,
        message: 'Cambios sincronizados',
      );
    }

    if (syncState == SyncState.error) {
      return const _BannerConfig(
        color: Color(0xFFC62828), // rojo oscuro
        icon: Icons.error_outline_rounded,
        message: 'Error al sincronizar — se reintentará al reconectar',
      );
    }

    // Online con pendientes (antes de que arranque sync)
    if (pendingCount > 0) {
      return _BannerConfig(
        color: Colors.amber[800]!,
        icon: Icons.cloud_upload_outlined,
        message: '$pendingCount cambio${pendingCount != 1 ? "s" : ""} pendientes de sincronizar',
      );
    }

    return const _BannerConfig(
      color: Colors.transparent,
      icon: Icons.check,
      message: '',
    );
  }
}

class _BannerConfig {
  const _BannerConfig({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;
}

/// Indicador compacto de última sincronización para mostrar en pantallas.
class OfflineLastSyncChip extends StatelessWidget {
  const OfflineLastSyncChip({super.key, required this.lastSync});

  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    if (lastSync == null) return const SizedBox.shrink();

    final String timeAgo = _formatTimeAgo(lastSync!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.update_rounded,
            size: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            'Última actualización: $timeAgo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}

/// Badge que indica que un elemento fue creado offline y está pendiente de sync.
class OfflinePendingBadge extends StatelessWidget {
  const OfflinePendingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.schedule_rounded, size: 10, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Pendiente de sincronización',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
