import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../viewmodels/iniciar_tramite_providers.dart';
import '../widgets/tramite_disponible_card.dart';

class IniciarTramiteView extends ConsumerWidget {
  const IniciarTramiteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(iniciarTramiteViewModelProvider);
    final viewModel = ref.read(iniciarTramiteViewModelProvider.notifier);
    final String actorUserId =
        ref.watch(authViewModelProvider).authenticatedUser?.id.trim() ?? '';

    if (actorUserId.isNotEmpty &&
        !state.isLoading &&
        state.lastLoadedUserId != actorUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.cargarTramites(actorUserId: actorUserId);
      });
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (actorUserId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No se pudo identificar al usuario actual para consultar trámites.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  viewModel.cargarTramites(actorUserId: actorUserId);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.inbox_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No hay trámites activos disponibles en este momento.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  viewModel.cargarTramites(actorUserId: actorUserId);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.cargarTramites(actorUserId: actorUserId),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.tramites.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Text(
              'Selecciona un trámite activo para iniciar una nueva instancia.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          final tramite = state.tramites[index - 1];
          final bool isIniciando = state.isIniciando(tramite.id);

          return TramiteDisponibleCard(
            tramite: tramite,
            isIniciando: isIniciando,
            onIniciar: () async {
              final String? error = await viewModel.iniciarTramite(
                actorUserId: actorUserId,
                tramiteId: tramite.id,
              );

              if (!context.mounted) {
                return;
              }

              final String message = error ?? 'Trámite iniciado correctamente.';
              final Color backgroundColor = error == null
                  ? Colors.green.shade600
                  : Colors.red.shade700;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: backgroundColor,
                ),
              );
            },
          );
        },
      ),
    );
  }
}