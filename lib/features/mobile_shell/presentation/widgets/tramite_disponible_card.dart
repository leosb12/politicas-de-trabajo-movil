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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estaBloqueado ? null : onIniciar,
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
                label: Text(
                  isIniciando
                      ? 'Iniciando...'
                      : (tramite.iniciado ? 'Iniciado' : 'Iniciar trámite'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}