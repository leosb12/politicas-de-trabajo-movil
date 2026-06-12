import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_sync_service.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';

class OfflineDataView extends ConsumerStatefulWidget {
  const OfflineDataView({super.key});

  @override
  ConsumerState<OfflineDataView> createState() => _OfflineDataViewState();
}

class _OfflineDataViewState extends ConsumerState<OfflineDataView> {
  bool _isSyncingLocal = false;
  String? _syncMessage;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Nunca';
    final String date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final String time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date a las $time';
  }

  Future<void> _sincronizarAhora(String userId) async {
    setState(() {
      _isSyncingLocal = true;
      _syncMessage = 'Sincronizando catálogo y pendientes...';
    });

    try {
      final syncService = ref.read(offlineInitialSyncServiceProvider);
      // 1. Sincronizar catálogo completo y cards
      final result = await syncService.syncCompleto(userId: userId);
      
      // 2. Procesar solicitudes en cola pendientes si estamos online
      final isOnline = ref.read(isOnlineProvider);
      if (isOnline) {
        setState(() {
          _syncMessage = 'Procesando solicitudes pendientes en la cola...';
        });
        await ref.read(offlineSyncServiceProvider.notifier).forceSyncNow();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? 'Sincronización completada con éxito.'
                : 'Sincronización fallida: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error inesperado al sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingLocal = false;
          _syncMessage = null;
        });
      }
    }
  }

  Future<void> _eliminarDatosOffline(String userId) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar datos offline'),
          content: const Text(
            'Se eliminarán todas las políticas, requisitos y flujos de trabajo guardados. '
            'Los trámites locales creados sin internet se mantendrán en la cola de sincronización. '
            '¿Seguro que quieres continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      final snapshotStore = ref.read(snapshotStoreProvider);
      await snapshotStore.clearOfflineData(userId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos offline eliminados correctamente.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(offlineSyncServiceProvider);
    final pendingCount = ref.watch(pendingQueueCountProvider);
    
    final userId = authState.authenticatedUser?.id.trim() ?? '';
    final snapshotStore = ref.watch(snapshotStoreProvider);
    
    // Obtener catálogo para estadísticas
    final catalogo = snapshotStore.getCatalogoPoliticas(userId) ?? [];
    final lastSync = snapshotStore.getLastSync(userId);

    // Cálculos de contadores
    final int totalPoliticas = catalogo.length;
    int totalRequisitos = 0;
    int totalFlujos = 0;

    for (final dynamic item in catalogo) {
      if (item is Map) {
        final List? reqs = item['requisitosIniciales'] as List?;
        if (reqs != null) {
          totalRequisitos += reqs.length;
        }

        final List? nodos = item['nodos'] as List?;
        if (nodos != null && nodos.isNotEmpty) {
          totalFlujos++;
        }
      }
    }

    final bool isBusy = _isSyncingLocal || syncState == SyncState.syncing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Offline y Datos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Banner de Estado
            Card(
              elevation: 0,
              color: isOnline 
                  ? Colors.green.withOpacity(0.15) 
                  : Colors.red.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isOnline ? Colors.green : Colors.red,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: isOnline ? Colors.green[800] : Colors.red[800],
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'Conexión activa' : 'Sin conexión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        Text(
                          isOnline ? 'Puedes sincronizar los datos ahora.' : 'Trabajando en modo local.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isOnline ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Descripción del módulo
            Text(
              'Gestión de datos locales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestiona los datos descargados en este dispositivo para trabajar sin conexión a internet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Estadísticas en Grid/Lista
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.assignment_outlined,
                      label: 'Políticas guardadas',
                      value: '$totalPoliticas',
                    ),
                    const Divider(),
                    _buildStatRow(
                      icon: Icons.list_alt_rounded,
                      label: 'Requisitos guardados',
                      value: '$totalRequisitos',
                    ),
                    const Divider(),
                    _buildStatRow(
                      icon: Icons.schema_outlined,
                      label: 'Flujos guardados',
                      value: '$totalFlujos',
                    ),
                    const Divider(),
                    _buildStatRow(
                      icon: Icons.sync_problem_rounded,
                      label: 'Trámites pendientes de sincronizar',
                      value: '$pendingCount',
                      valueColor: pendingCount > 0 ? Colors.orange[800] : null,
                    ),
                    const Divider(),
                    _buildStatRow(
                      icon: Icons.access_time_rounded,
                      label: 'Última sincronización',
                      value: _formatDateTime(lastSync),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mensajes de progreso
            if (isBusy && _syncMessage != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _syncMessage!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botones de acción
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: isOnline && !isBusy ? () => _sincronizarAhora(userId) : null,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sincronizar ahora'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: !isBusy && (totalPoliticas > 0 || lastSync != null)
                      ? () => _eliminarDatosOffline(userId)
                      : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar datos offline'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.red,
                    side: BorderSide(
                      color: (totalPoliticas > 0 || lastSync != null) ? Colors.red : Colors.grey[300]!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
