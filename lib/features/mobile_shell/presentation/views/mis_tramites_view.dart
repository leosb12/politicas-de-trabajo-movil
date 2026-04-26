import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/models/mis_tramite_item.dart';
import '../viewmodels/mis_tramites_providers.dart';
import '../widgets/mis_tramite_card.dart';
import '../widgets/tramites_search_bar.dart';
import 'tramite_seguimiento_view.dart';

class MisTramitesView extends ConsumerStatefulWidget {
  const MisTramitesView({super.key});

  @override
  ConsumerState<MisTramitesView> createState() => _MisTramitesViewState();
}

class _MisTramitesViewState extends ConsumerState<MisTramitesView> {
  String? _requestedUserId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(misTramitesViewModelProvider);
    final viewModel = ref.read(misTramitesViewModelProvider.notifier);
    final String userId =
        ref.watch(authViewModelProvider).authenticatedUser?.id.trim() ?? '';

    if (userId.isNotEmpty && _requestedUserId != userId && !state.isLoading) {
      _requestedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

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
                onPressed: () {
                  _requestedUserId = userId;
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
                'Todavia no tienes tramites iniciados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _requestedUserId = userId;
                  viewModel.cargarMisTramites(usuarioId: userId);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    final tramitesFiltrados = state.tramites.where((t) {
      final bool matchesSearch = t.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      // MisTramiteItem no incluye si el tramite es de paga o gratis
      // Por lo que el filtro de pago se ignora en la vista "Mis Tramites"
      return matchesSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        _requestedUserId = userId;
        return viewModel.cargarMisTramites(usuarioId: userId);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TramitesSearchBar(
              onQueryChanged: (query) => setState(() => _searchQuery = query),
              showFilters: false,
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: tramitesFiltrados.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Text(
                    'Aqui puedes ver el estado, progreso y flujo de cada tramite iniciado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final MisTramiteItem item = tramitesFiltrados[index - 1];

                return MisTramiteCard(
                  item: item,
                  onVerSeguimiento: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TramiteSeguimientoView(tramite: item, usuarioId: userId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
