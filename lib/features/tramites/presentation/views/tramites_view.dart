import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/inline_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/tramite_disponible.dart';
import '../viewmodels/tramites_providers.dart';
import '../viewmodels/tramites_state.dart';

class TramitesView extends ConsumerStatefulWidget {
  const TramitesView({super.key, required this.actorUserId});

  final String actorUserId;

  @override
  ConsumerState<TramitesView> createState() => _TramitesViewState();
}

class _TramitesViewState extends ConsumerState<TramitesView> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_cargarTramites);
  }

  Future<void> _cargarTramites() {
    return ref
        .read(tramitesViewModelProvider.notifier)
        .cargarTramites(actorUserId: widget.actorUserId);
  }

  Future<void> _iniciarTramite(TramiteDisponible tramite) {
    return ref
        .read(tramitesViewModelProvider.notifier)
        .iniciarTramite(actorUserId: widget.actorUserId, tramite: tramite);
  }

  @override
  Widget build(BuildContext context) {
    final TramitesState state = ref.watch(tramitesViewModelProvider);

    ref.listen<TramitesState>(tramitesViewModelProvider, (previous, next) {
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return;
      }

      final String? previousError = previous?.errorMessage;
      final String? nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(nextError)));
        ref.read(tramitesViewModelProvider.notifier).clearFeedback();
        return;
      }

      final String? previousSuccess = previous?.successMessage;
      final String? nextSuccess = next.successMessage;
      if (nextSuccess != null && nextSuccess != previousSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextSuccess),
            backgroundColor: Colors.green.shade700,
          ),
        );
        ref.read(tramitesViewModelProvider.notifier).clearFeedback();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar tramite'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Recargar',
            onPressed: state.isLoading ? null : _cargarTramites,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFE9F2F8), Color(0xFFF9FBFD)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tramites disponibles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Selecciona un flujo activo y presiona Iniciar tramite para crear una nueva instancia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                if (state.errorMessage != null &&
                    state.tramites.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  InlineErrorMessage(message: state.errorMessage!),
                ],
                const SizedBox(height: 12),
                Expanded(child: _buildContenido(context, state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(BuildContext context, TramitesState state) {
    if (state.isLoading && state.tramites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.tramites.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.folder_open_rounded, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No hay tramites activos disponibles.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando un administrador active politicas, podras iniciarlas desde aqui.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Recargar',
                    isLoading: state.isLoading,
                    onPressed: _cargarTramites,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTramites,
      child: ListView.separated(
        itemCount: state.tramites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final TramiteDisponible tramite = state.tramites[index];
          final bool isStartingThis = state.startingTramiteId == tramite.id;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    tramite.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tramite.descripcion != null &&
                      tramite.descripcion!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      tramite.descripcion!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Iniciar tramite',
                    isLoading: isStartingThis,
                    onPressed: state.isStartingAny
                        ? null
                        : () => _iniciarTramite(tramite),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
