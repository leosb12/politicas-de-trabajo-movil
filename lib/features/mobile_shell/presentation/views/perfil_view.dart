import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../viewmodels/perfil_providers.dart';
import '../widgets/perfil_header_card.dart';
import '../widgets/perfil_info_tile.dart';

class PerfilView extends ConsumerWidget {
  const PerfilView({super.key});

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await ref.read(authViewModelProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(perfilViewModelProvider);
    final viewModel = ref.read(perfilViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);
    final String userId = authState.authenticatedUser?.id.trim() ?? '';

    if (userId.isNotEmpty && state.lastLoadedUserId != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.cargarPerfil(usuarioId: userId);
      });
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
                        viewModel.cargarPerfil(usuarioId: userId);
                      },
                child: const Text('Reintentar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmarCerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    if (userId.isEmpty || state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                userId.isEmpty
                    ? 'No se pudo identificar al usuario actual.'
                    : 'No hay datos de perfil disponibles.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: userId.isEmpty
                    ? null
                    : () {
                        viewModel.cargarPerfil(usuarioId: userId);
                      },
                child: const Text('Actualizar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmarCerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final perfil = state.perfil!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        PerfilHeaderCard(perfil: perfil),
        const SizedBox(height: 14),
        PerfilInfoTile(label: 'ID', value: perfil.usuarioId),
        PerfilInfoTile(label: 'Rol', value: perfil.rol),
        if (state.mostrarDepartamento)
          PerfilInfoTile(
            label: 'Departamento',
            value: (perfil.departamento == null ||
                    perfil.departamento!.trim().isEmpty)
                ? 'Sin departamento'
                : perfil.departamento!,
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmarCerrarSesion(context, ref),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}