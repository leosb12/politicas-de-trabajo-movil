import 'package:flutter/material.dart';

import '../../domain/models/mis_tramite_item.dart';
import 'tramite_progreso_indicator.dart';

class MisTramiteCard extends StatelessWidget {
  const MisTramiteCard({super.key, required this.item});

  final MisTramiteItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.nombre,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Última actualización: ${_formatDate(item.actualizadoEn)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TramiteProgresoIndicator(progreso: item.progreso, estado: item.estado),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}