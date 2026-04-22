import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../viewmodels/mis_tramites_providers.dart';
import '../widgets/mis_tramite_card.dart';

class MisTramitesView extends ConsumerWidget {
  const MisTramitesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(misTramitesViewModelProvider);
    final viewModel = ref.read(misTramitesViewModelProvider.notifier);
    final String userId =
        ref.watch(authViewModelProvider).authenticatedUser?.id.trim() ?? '';

    if (userId.isNotEmpty &&
        !state.isLoading &&
        state.lastLoadedUserId != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.cargarMisTramites(usuarioId: userId);
      });
    }

    if (userId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.inbox_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No se pudo identificar el usuario actual.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: userId.isEmpty
                    ? null
                    : () {
                        viewModel.cargarMisTramites(usuarioId: userId);
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
                'Todavía no tienes trámites iniciados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  viewModel.cargarMisTramites(usuarioId: userId);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.cargarMisTramites(usuarioId: userId),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.tramites.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Text(
              'Aquí puedes ver el estado y progreso de cada trámite iniciado.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          return MisTramiteCard(item: state.tramites[index - 1]);
        },
      ),
    );
  }
}
