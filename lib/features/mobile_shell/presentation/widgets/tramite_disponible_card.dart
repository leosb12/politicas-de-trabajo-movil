import 'package:flutter/material.dart';

import '../../domain/models/tramite_disponible_item.dart';

class TramiteDisponibleCard extends StatelessWidget {
  const TramiteDisponibleCard({
    super.key,
    required this.tramite,
    required this.isIniciando,
    required this.onIniciar,
  });

  final TramiteDisponibleItem tramite;
  final bool isIniciando;
  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool estaBloqueado = isIniciando || tramite.iniciado;
    final bool requierePago = tramite.requierePago;
    final bool precioValido =
        !requierePago ||
        ((tramite.montoPago ?? 0) > 0 &&
            (tramite.monedaPago?.trim().isNotEmpty ?? false));
    final String etiquetaEstado = requierePago ? 'De paga' : 'Gratis';
    final String precioTexto = precioValido
        ? _formatPrice(tramite.montoPago, tramite.monedaPago)
        : 'Precio no configurado';
    final String detallePago =
        (tramite.descripcionPago?.trim().isNotEmpty ?? false)
        ? tramite.descripcionPago!.trim()
        : 'Pago de trámite';
    final String botonTexto = isIniciando
        ? 'Iniciando...'
        : tramite.iniciado
        ? 'Iniciado'
        : requierePago
        ? 'Pagar e iniciar'
        : 'Iniciar trámite';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    tramite.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Chip(label: Text(tramite.categoria)),
              ],
            ),
            const SizedBox(height: 8),
            Text(tramite.descripcion, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(etiquetaEstado)),
                if (requierePago)
                  Chip(label: Text(precioTexto))
                else
                  const Chip(label: Text('Sin costo')),
              ],
            ),
            if (requierePago) ...<Widget>[
              const SizedBox(height: 8),
              Text(detallePago, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estaBloqueado || (requierePago && !precioValido)
                    ? null
                    : onIniciar,
                icon: isIniciando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        tramite.iniciado
                            ? Icons.check_circle_rounded
                            : Icons.play_arrow_rounded,
                      ),
                label: Text(isIniciando ? 'Iniciando...' : botonTexto),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double? amount, String? currency) {
    final double value = amount ?? 0;
    final String formattedAmount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final String normalizedCurrency = currency?.trim() ?? '';

    if (normalizedCurrency.isEmpty) {
      return formattedAmount;
    }

    return '$formattedAmount $normalizedCurrency';
  }
}
