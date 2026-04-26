import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/pago_service.dart';

class PagoBottomSheet extends StatefulWidget {
  const PagoBottomSheet({
    super.key,
    required this.tramiteNombre,
    required this.actorUserId,
    required this.tramiteId,
    required this.pagoService,
    required this.precioTexto,
    required this.descripcionPago,
    required this.onStripeSessionId,
    this.onStripeCheckoutOpened,
    required this.onPaypalPagoId,
    required this.onPagoConfirmado,
  });

  final String tramiteNombre;
  final String actorUserId;
  final String tramiteId;
  final PagoService pagoService;
  final String precioTexto;
  final String descripcionPago;
  final ValueChanged<String?> onStripeSessionId;
  final VoidCallback? onStripeCheckoutOpened;
  final ValueChanged<String?> onPaypalPagoId;
  final Future<void> Function() onPagoConfirmado;

  @override
  State<PagoBottomSheet> createState() => _PagoBottomSheetState();
}

class _PagoBottomSheetState extends State<PagoBottomSheet> {
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
            politicaId: widget.tramiteId,
          );

      _stripeSessionId =
          result.sessionId ?? _readSessionIdFromUrl(result.checkoutUrl);
      widget.onStripeSessionId(_stripeSessionId);

      await _abrirUrl(result.checkoutUrl);

      widget.onStripeCheckoutOpened?.call();

      if (mounted && widget.onStripeCheckoutOpened == null) {
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
            politicaId: widget.tramiteId,
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
          .verificarStripe(
            actorUserId: widget.actorUserId,
            sessionId: sessionId.trim(),
          );

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
        actorUserId: widget.actorUserId,
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
            widget.tramiteNombre,
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
