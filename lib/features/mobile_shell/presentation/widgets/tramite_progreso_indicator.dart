import 'package:flutter/material.dart';

class TramiteProgresoIndicator extends StatelessWidget {
  const TramiteProgresoIndicator({
    super.key,
    required this.progreso,
    required this.estado,
  });

  final double progreso;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int porcentaje = (progreso * 100).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                estado,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$porcentaje%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progreso.clamp(0, 1),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}