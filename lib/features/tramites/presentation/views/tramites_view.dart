import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/pago_service.dart';
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
  static const Map<String, String> _tipoPoliticaLabels = <String, String>{
    'INTERNA': 'Interna',
    'EXTERNA': 'Externa',
    'AMBAS': 'Ambas',
  };

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _uriSubscription;
  bool _isPagoSheetOpen = false;
  _PagoPendiente? _pagoPendiente;

  @override
  void initState() {
    super.initState();
    _uriSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      unawaited(_handleIncomingUri(uri));
    });
    Future<void>.microtask(_cargarTramites);
  }

  @override
  void dispose() {
    _uriSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarTramites() {
    return ref
        .read(tramitesViewModelProvider.notifier)
        .cargarTramites(actorUserId: widget.actorUserId);
  }

  Future<void> _iniciarTramite(TramiteDisponible tramite) {
    if (_requierePagoValido(tramite)) {
      return _mostrarModalPago(tramite);
    }

    return _iniciarTramiteGratis(tramite);
  }

  Future<void> _iniciarTramiteGratis(TramiteDisponible tramite) {
    return ref
        .read(tramitesViewModelProvider.notifier)
        .iniciarTramite(actorUserId: widget.actorUserId, tramite: tramite);
  }

  Future<void> _mostrarModalPago(TramiteDisponible tramite) async {
    if (!_requierePagoValido(tramite)) {
      _mostrarSnackBar(
        'Precio no configurado para este trámite.',
        isError: true,
      );
      return;
    }

    final PagoService pagoService = PagoService(ref.read(tramitesDioProvider));

    setState(() {
      _isPagoSheetOpen = true;
      _pagoPendiente = _PagoPendiente(tramite: tramite);
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _PagoBottomSheetContent(
          tramite: tramite,
          actorUserId: widget.actorUserId,
          pagoService: pagoService,
          precioTexto: _formatearMonto(tramite),
          descripcionPago: _descripcionPago(tramite),
          onStripeSessionId: (String? sessionId) {
            setState(() {
              _pagoPendiente = _PagoPendiente(
                tramite: tramite,
                sessionId: sessionId,
              );
            });
          },
          onPaypalPagoId: (String? pagoId) {
            setState(() {
              _pagoPendiente = _PagoPendiente(tramite: tramite, pagoId: pagoId);
            });
          },
          onPagoConfirmado: () async {
            if (mounted) {
              Navigator.of(sheetContext).pop();
            }

            await _finalizarPagoYIniciarTramite(tramite);
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPagoSheetOpen = false;
        _pagoPendiente = null;
      });
    }
  }

  Future<void> _finalizarPagoYIniciarTramite(TramiteDisponible tramite) async {
    await _iniciarTramiteGratis(tramite);
    if (mounted) {
      _mostrarSnackBar('Pago confirmado. Trámite iniciado.');
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    final _PagoPendiente? pendiente = _pagoPendiente;
    if (!_isPagoSheetOpen || pendiente == null) {
      return;
    }

    final String? sessionId =
        uri.queryParameters['sessionId'] ?? uri.queryParameters['session_id'];
    if (sessionId == null || sessionId.trim().isEmpty) {
      return;
    }

    final String normalizedSessionId = sessionId.trim();
    if (pendiente.sessionId != null &&
        pendiente.sessionId != normalizedSessionId) {
      return;
    }

    try {
      final PagoService pagoService = PagoService(
        ref.read(tramitesDioProvider),
      );
      final StripeVerificationResult result = await pagoService.verificarStripe(
        sessionId: normalizedSessionId,
      );

      if (!result.confirmado) {
        _mostrarSnackBar('Pago pendiente de confirmación.', isError: true);
        return;
      }

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        _isPagoSheetOpen = false;
        _pagoPendiente = null;
      });

      await _finalizarPagoYIniciarTramite(pendiente.tramite);
    } on ApiFailure catch (failure) {
      _mostrarSnackBar(failure.message, isError: true);
    } catch (_) {
      _mostrarSnackBar(
        'No se pudo verificar el pago de Stripe.',
        isError: true,
      );
    }
  }

  bool _requierePagoValido(TramiteDisponible tramite) {
    if (!tramite.requierePago) {
      return true;
    }

    final double? monto = tramite.montoPago;
    final String? moneda = tramite.monedaPago?.trim();
    return monto != null && monto > 0 && moneda != null && moneda.isNotEmpty;
  }

  String _formatearMonto(TramiteDisponible tramite) {
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

  String _descripcionPago(TramiteDisponible tramite) {
    final String descripcion = tramite.descripcionPago?.trim() ?? '';
    return descripcion.isNotEmpty ? descripcion : 'Pago de trámite';
  }

  void _mostrarSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
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
          final bool requierePago = tramite.requierePago;
          final bool precioValido = _requierePagoValido(tramite);

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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(
                        label: Text(
                          _tipoPoliticaLabels[tramite.tipoPolitica] ??
                              tramite.tipoPolitica,
                        ),
                      ),
                      Chip(label: Text(requierePago ? 'De paga' : 'Gratis')),
                      Chip(
                        label: Text(
                          requierePago
                              ? (precioValido
                                    ? _formatearMonto(tramite)
                                    : 'Precio no configurado')
                              : 'Sin costo',
                        ),
                      ),
                      if (tramite.tipoPolitica == 'INTERNA' &&
                          tramite.departamentoInicioNombre != null &&
                          tramite.departamentoInicioNombre!.trim().isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.apartment_rounded, size: 18),
                          label: Text(
                            'Solo ${tramite.departamentoInicioNombre}',
                          ),
                        ),
                      if (tramite.tipoPolitica == 'INTERNA' &&
                          (tramite.departamentoInicioNombre == null ||
                              tramite.departamentoInicioNombre!.trim().isEmpty))
                        const Chip(
                          avatar: Icon(Icons.groups_rounded, size: 18),
                          label: Text('Todos los departamentos'),
                        ),
                    ],
                  ),
                  if (requierePago) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _descripcionPago(tramite),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          state.isStartingAny || (requierePago && !precioValido)
                          ? null
                          : () => _iniciarTramite(tramite),
                      child: isStartingThis
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              requierePago
                                  ? 'Pagar e iniciar'
                                  : 'Iniciar tramite',
                            ),
                    ),
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

class _PagoBottomSheetContent extends StatefulWidget {
  const _PagoBottomSheetContent({
    required this.tramite,
    required this.actorUserId,
    required this.pagoService,
    required this.precioTexto,
    required this.descripcionPago,
    required this.onStripeSessionId,
    required this.onPaypalPagoId,
    required this.onPagoConfirmado,
  });

  final TramiteDisponible tramite;
  final String actorUserId;
  final PagoService pagoService;
  final String precioTexto;
  final String descripcionPago;
  final ValueChanged<String?> onStripeSessionId;
  final ValueChanged<String?> onPaypalPagoId;
  final Future<void> Function() onPagoConfirmado;

  @override
  State<_PagoBottomSheetContent> createState() =>
      _PagoBottomSheetContentState();
}

class _PagoBottomSheetContentState extends State<_PagoBottomSheetContent> {
  bool _isStripeLoading = false;
  bool _isPaypalLoading = false;
  bool _awaitingVerification = false;
  String? _message;
  String? _stripeSessionId;
  String? _paypalPagoId;

  Future<void> _abrirUrl(String rawUrl) async {
    final String trimmedUrl = rawUrl.trim();
    Uri? uri = Uri.tryParse(trimmedUrl);

    if (uri == null) {
      uri = Uri.tryParse(Uri.encodeFull(trimmedUrl));
    }

    final bool isHttp = uri?.scheme.toLowerCase() == 'http';
    final bool isHttps = uri?.scheme.toLowerCase() == 'https';
    if (uri == null || (!isHttp && !isHttps)) {
      throw ApiFailure(message: 'La URL de pago es invalida o no es compatible.');
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw ApiFailure(message: 'No se pudo abrir el navegador de pago.');
    }
  }

  Future<void> _pagarConStripe() async {
    setState(() {
      _isStripeLoading = true;
      _message = null;
    });

    try {
      final StripeCheckoutResult result = await widget.pagoService
          .crearCheckoutStripe(
            actorUserId: widget.actorUserId,
            politicaId: widget.tramite.id,
          );

      _stripeSessionId =
          result.sessionId ?? _readSessionIdFromUrl(result.checkoutUrl);
      widget.onStripeSessionId(_stripeSessionId);

      await _abrirUrl(result.checkoutUrl);

      if (mounted) {
        setState(() {
          _awaitingVerification = true;
        });
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _message = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudo iniciar el pago con Stripe.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStripeLoading = false;
        });
      }
    }
  }

  Future<void> _pagarConPaypal() async {
    setState(() {
      _isPaypalLoading = true;
      _message = null;
    });

    try {
      final PaypalCheckoutResult result = await widget.pagoService
          .crearLinkPaypal(
            actorUserId: widget.actorUserId,
            politicaId: widget.tramite.id,
          );

      _paypalPagoId = result.pagoId;
      widget.onPaypalPagoId(_paypalPagoId);
      await _abrirUrl(result.paypalUrl);

      if (mounted) {
        setState(() {
          _awaitingVerification = true;
        });
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _message = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudo iniciar el pago con PayPal.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaypalLoading = false;
        });
      }
    }
  }

  Future<void> _confirmarPagoStripe() async {
    final String? sessionId = _stripeSessionId;
    if (sessionId == null || sessionId.trim().isEmpty) {
      setState(() {
        _message = 'No se pudo obtener el sessionId de Stripe.';
      });
      return;
    }

    setState(() {
      _isStripeLoading = true;
      _message = null;
    });

    try {
      final StripeVerificationResult result = await widget.pagoService
          .verificarStripe(sessionId: sessionId.trim());

      if (!result.confirmado) {
        setState(() {
          _message = 'Pago pendiente de confirmación.';
        });
        return;
      }

      await widget.onPagoConfirmado();
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _message = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudo verificar el pago de Stripe.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStripeLoading = false;
        });
      }
    }
  }

  Future<void> _confirmarPagoPaypal() async {
    final String? pagoId = _paypalPagoId;
    if (pagoId == null || pagoId.trim().isEmpty) {
      setState(() {
        _message = 'No se pudo obtener el pago de PayPal.';
      });
      return;
    }

    setState(() {
      _isPaypalLoading = true;
      _message = null;
    });

    try {
      final PagoDetalle pago = await widget.pagoService.obtenerPago(
        pagoId: pagoId.trim(),
      );

      if (!pago.estaAprobado) {
        setState(() {
          _message = pago.estaPendientePaypal
              ? 'Pago pendiente de confirmación'
              : 'El pago todavía no fue aprobado.';
        });
        return;
      }

      await widget.onPagoConfirmado();
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _message = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudo consultar el estado del pago.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaypalLoading = false;
        });
      }
    }
  }

  String? _readSessionIdFromUrl(String rawUrl) {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return null;
    }

    final String? sessionId =
        uri.queryParameters['sessionId'] ?? uri.queryParameters['session_id'];
    if (sessionId == null || sessionId.trim().isEmpty) {
      return null;
    }

    return sessionId.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.tramite.nombre,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Este trámite requiere pago',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _PagoInfoTile(
            precioTexto: widget.precioTexto,
            descripcionPago: widget.descripcionPago,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF),
                foregroundColor: Colors.white,
              ),
              onPressed: _isStripeLoading || _isPaypalLoading
                  ? null
                  : _pagarConStripe,
              child: _isStripeLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pagar con Stripe'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF003087),
                foregroundColor: Colors.white,
              ),
              onPressed: _isStripeLoading || _isPaypalLoading
                  ? null
                  : _pagarConPaypal,
              child: _isPaypalLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pagar con PayPal'),
            ),
          ),
          if (_awaitingVerification) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isStripeLoading || _isPaypalLoading
                    ? null
                    : () async {
                        if (_stripeSessionId != null) {
                          await _confirmarPagoStripe();
                        } else if (_paypalPagoId != null) {
                          await _confirmarPagoPaypal();
                        }
                      },
                child: const Text('Ya realicé el pago'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isStripeLoading || _isPaypalLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
          if (_message != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PagoInfoTile extends StatelessWidget {
  const _PagoInfoTile({
    required this.precioTexto,
    required this.descripcionPago,
  });

  final String precioTexto;
  final String descripcionPago;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E3F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            precioTexto,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(descripcionPago),
        ],
      ),
    );
  }
}

class _PagoPendiente {
  const _PagoPendiente({required this.tramite, this.sessionId, this.pagoId});

  final TramiteDisponible tramite;
  final String? sessionId;
  final String? pagoId;
}
