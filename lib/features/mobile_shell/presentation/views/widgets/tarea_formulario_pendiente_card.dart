import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tarea_formulario_pendiente_view.dart';

/// Card que muestra cuando hay una tarea pendiente para el usuario.
/// Permite abrir la vista movil para completarla directamente.
class TareaFormularioPendienteCard extends ConsumerStatefulWidget {
  const TareaFormularioPendienteCard({
    super.key,
    required this.usuarioId,
    required this.tareaId,
    required this.instanciaId,
    required this.nombreActividad,
    this.onCompleted,
  });

  final String usuarioId;
  final String tareaId;
  final String instanciaId;
  final String nombreActividad;
  final Future<void> Function()? onCompleted;

  @override
  ConsumerState<TareaFormularioPendienteCard> createState() =>
      _TareaFormularioPendienteCardState();
}

class _TareaFormularioPendienteCardState
    extends ConsumerState<TareaFormularioPendienteCard> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.assignment_rounded,
                      color: Colors.orange.shade700,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tarea pendiente',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.nombreActividad,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Abre esta tarea desde tu celular para continuar.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _abrirFormulario(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Abrir tarea',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? completada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TareaFormularioPendienteView(
          usuarioId: widget.usuarioId,
          tareaId: widget.tareaId,
          instanciaId: widget.instanciaId,
          nombreActividad: widget.nombreActividad,
        ),
      ),
    );

    if (!mounted || completada != true) {
      return;
    }

    if (widget.onCompleted != null) {
      await widget.onCompleted!.call();
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('La tarea se completo correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
