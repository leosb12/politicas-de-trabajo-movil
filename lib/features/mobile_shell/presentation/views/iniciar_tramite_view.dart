import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/pago_service.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/models/tramite_disponible_item.dart';
import '../../../pagos/presentation/widgets/pago_bottom_sheet.dart';
import '../viewmodels/iniciar_tramite_providers.dart';
import '../viewmodels/mis_tramites_providers.dart';
import '../viewmodels/mobile_shell_providers.dart';
import '../widgets/tramite_disponible_card.dart';
import '../widgets/tramites_search_bar.dart';

class IniciarTramiteView extends ConsumerStatefulWidget {
  const IniciarTramiteView({super.key});

  @override
  ConsumerState<IniciarTramiteView> createState() => _IniciarTramiteViewState();
}

class _IniciarTramiteViewState extends ConsumerState<IniciarTramiteView> {
  String? _requestedUserId;
  String _searchQuery = '';
  TramiteFilter _currentFilter = TramiteFilter.todos;

  bool _requierePagoValido(TramiteDisponibleItem tramite) {
    if (!tramite.requierePago) {
      return true;
    }

    final double? monto = tramite.montoPago;
    final String? moneda = tramite.monedaPago?.trim();
    return monto != null && monto > 0 && moneda != null && moneda.isNotEmpty;
  }

  String _formatearMonto(TramiteDisponibleItem tramite) {
    final double value = tramite.montoPago ?? 0;
    final String formattedAmount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final String currency = tramite.monedaPago?.trim() ?? '';

    if (currency.isEmpty) {
      return formattedAmount;
    }

    return '$formattedAmount $currency';
  }

  String _descripcionPago(TramiteDisponibleItem tramite) {
    final String descripcion = tramite.descripcionPago?.trim() ?? '';
    return descripcion.isNotEmpty ? descripcion : 'Pago de trámite';
  }

  Future<void> _mostrarPagoModal({
    required TramiteDisponibleItem tramite,
    required String actorUserId,
  }) async {
    if (!_requierePagoValido(tramite)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Precio no configurado para este trámite.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final PagoService pagoService = PagoService(
      ref.read(iniciarTramiteDioProvider),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return PagoBottomSheet(
          tramiteNombre: tramite.nombre,
          actorUserId: actorUserId,
          tramiteId: tramite.id,
          pagoService: pagoService,
          precioTexto: _formatearMonto(tramite),
          descripcionPago: _descripcionPago(tramite),
          onStripeSessionId: (_) {},
          onStripeCheckoutOpened: () {
            if (!mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
          },
          onPaypalPagoId: (_) {},
          onPagoConfirmado: () async {
            if (mounted) {
              Navigator.of(sheetContext).pop();
            }

            final String? error = await ref
                .read(iniciarTramiteViewModelProvider.notifier)
                .iniciarTramite(
                  actorUserId: actorUserId,
                  tramiteId: tramite.id,
                );

            if (!context.mounted) {
              return;
            }

            final String message = error ?? 'Tramite iniciado correctamente.';
            final Color backgroundColor = error == null
                ? Colors.green.shade600
                : Colors.red.shade700;

            if (error == null) {
              await ref
                  .read(misTramitesViewModelProvider.notifier)
                  .cargarMisTramites(usuarioId: actorUserId);

              if (!context.mounted) {
                return;
              }

              ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iniciarTramiteViewModelProvider);
    final viewModel = ref.read(iniciarTramiteViewModelProvider.notifier);
    final String actorUserId =
        ref.watch(authViewModelProvider).authenticatedUser?.id.trim() ?? '';

    if (actorUserId.isNotEmpty &&
        _requestedUserId != actorUserId &&
        !state.isLoading) {
      _requestedUserId = actorUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

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
                'No se pudo identificar al usuario actual para consultar tramites.',
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
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _requestedUserId = actorUserId;
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
                'No hay tramites activos disponibles en este momento.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _requestedUserId = actorUserId;
                  viewModel.cargarTramites(actorUserId: actorUserId);
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
      final bool matchesFilter = _currentFilter == TramiteFilter.todos ||
          (_currentFilter == TramiteFilter.paga && t.requierePago) ||
          (_currentFilter == TramiteFilter.gratis && !t.requierePago);
      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        _requestedUserId = actorUserId;
        return viewModel.cargarTramites(actorUserId: actorUserId);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TramitesSearchBar(
              onQueryChanged: (query) => setState(() => _searchQuery = query),
              onFilterChanged: (filter) => setState(() => _currentFilter = filter),
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
                    'Selecciona un tramite activo para iniciar una nueva instancia.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final tramite = tramitesFiltrados[index - 1];
                final bool isIniciando = state.isIniciando(tramite.id);

                return TramiteDisponibleCard(
                  tramite: tramite,
                  isIniciando: isIniciando,
                  onIniciar: () async {
                    if (tramite.requierePago && _requierePagoValido(tramite)) {
                      await _mostrarPagoModal(
                        tramite: tramite,
                        actorUserId: actorUserId,
                      );
                      return;
                    }

                    final String? error = await viewModel.iniciarTramite(
                      actorUserId: actorUserId,
                      tramiteId: tramite.id,
                    );

                    if (!context.mounted) {
                      return;
                    }

                    final String message = error ?? 'Tramite iniciado correctamente.';
                    final Color backgroundColor = error == null
                        ? Colors.green.shade600
                        : Colors.red.shade700;

                    if (error == null) {
                      await ref
                          .read(misTramitesViewModelProvider.notifier)
                          .cargarMisTramites(usuarioId: actorUserId);

                      if (!context.mounted) {
                        return;
                      }

                      ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
                    }

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
          ),
        ],
      ),
    );
  }
}
