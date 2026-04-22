import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../viewmodels/mis_tramites_providers.dart';
import '../viewmodels/tramite_seguimiento_state.dart';
import '../viewmodels/tramite_seguimiento_view_model.dart';

class TramiteSeguimientoView extends ConsumerStatefulWidget {
  const TramiteSeguimientoView({
    super.key,
    required this.tramite,
    required this.usuarioId,
  });

  final MisTramiteItem tramite;
  final String usuarioId;

  @override
  ConsumerState<TramiteSeguimientoView> createState() =>
      _TramiteSeguimientoViewState();
}

class _TramiteSeguimientoViewState
    extends ConsumerState<TramiteSeguimientoView> {
  late final TramiteSeguimientoArgs _args;

  @override
  void initState() {
    super.initState();
    _args = TramiteSeguimientoArgs(
      usuarioId: widget.usuarioId,
      instanciaId: widget.tramite.id,
    );
    Future<void>.microtask(_cargarSeguimiento);
  }

  Future<void> _cargarSeguimiento() {
    return ref
        .read(tramiteSeguimientoViewModelProvider(_args).notifier)
        .cargarSeguimiento();
  }

  @override
  Widget build(BuildContext context) {
    final TramiteSeguimientoState state = ref.watch(
      tramiteSeguimientoViewModelProvider(_args),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: state.isLoading ? null : _cargarSeguimiento,
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, TramiteSeguimientoState state) {
    if (state.isLoading && state.seguimiento == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.seguimiento == null) {
      return _StateMessage(
        icon: Icons.error_outline_rounded,
        message: state.errorMessage!,
        actionLabel: 'Reintentar',
        onPressed: () {
          _cargarSeguimiento();
        },
      );
    }

    final TramiteSeguimiento? seguimiento = state.seguimiento;
    if (seguimiento == null) {
      return _StateMessage(
        icon: Icons.route_outlined,
        message: 'No hay seguimiento disponible para este tramite.',
        actionLabel: 'Actualizar',
        onPressed: () {
          _cargarSeguimiento();
        },
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarSeguimiento,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const <Widget>[
            SizedBox(height: 120),
            _StateMessageContent(
              icon: Icons.route_outlined,
              message: 'El tramite aun no tiene datos de seguimiento.',
            ),
          ],
        ),
      );
    }

    final _SeguimientoData data = _SeguimientoData.from(
      seguimiento: seguimiento,
      fallbackItem: widget.tramite,
    );

    return RefreshIndicator(
      onRefresh: _cargarSeguimiento,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          _StatusHero(data: data),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _InlineWarning(message: state.errorMessage!),
          ],
          const SizedBox(height: 14),
          _CurrentLocationPanel(data: data),
          const SizedBox(height: 14),
          _CompactFlowStrip(data: data),
          const SizedBox(height: 14),
          _NextStepsPanel(data: data),
          const SizedBox(height: 14),
          _TaskOverviewPanel(data: data),
          const SizedBox(height: 18),
          _SectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Ruta del tramite',
            subtitle: 'Lectura movil del flujo, sin edicion ni movimiento.',
          ),
          const SizedBox(height: 10),
          _Timeline(data: data),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = data.currentStyle.border;
    final int percent = (data.progress * 100).round().clamp(0, 100);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _LightBadge(
                  icon: Icons.confirmation_number_outlined,
                  text: data.codigo,
                ),
                _LightBadge(icon: Icons.flag_outlined, text: data.estado),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.nombre,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.currentDepartment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.currentNodeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.progress,
                minHeight: 10,
                backgroundColor: colors.onPrimary.withValues(alpha: 0.20),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Avance estimado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocationPanel extends StatelessWidget {
  const _CurrentLocationPanel({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.apartment_rounded,
            title: 'Donde esta ahora',
          ),
          const SizedBox(height: 12),
          if (data.departamentosActuales.isEmpty)
            _EmptyLine(
              icon: Icons.info_outline_rounded,
              text: 'El servidor aun no informo un departamento actual.',
            )
          else
            Column(
              children: data.departamentosActuales
                  .map((DepartamentoActualSeguimiento item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CurrentDepartmentCard(item: item),
                    );
                  })
                  .toList(growable: false),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Completadas',
                value: data.completedCount.toString(),
                color: Colors.green.shade700,
              ),
              _MetricChip(
                icon: Icons.radio_button_checked_rounded,
                label: 'Actuales',
                value: data.currentCount.toString(),
                color: theme.colorScheme.primary,
              ),
              _MetricChip(
                icon: Icons.schedule_rounded,
                label: 'Pendientes',
                value: data.pendingCount.toString(),
                color: Colors.blueGrey.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentDepartmentCard extends StatelessWidget {
  const _CurrentDepartmentCard({required this.item});

  final DepartamentoActualSeguimiento item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String department = _fallback(
      item.departamentoNombre,
      'Departamento sin nombre',
    );
    final String node = _fallback(item.nodoNombre, 'Etapa actual');
    final String responsible = _firstNonEmpty(<String>[
      item.asignadoANombre,
      item.responsableNombre,
      item.responsableTipo,
    ]);
    final String taskStatus = _estadoTareaLabel(item.estadoTarea);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
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
                    department,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (responsible.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    _TinyDetail(
                      icon: Icons.person_outline_rounded,
                      text: responsible,
                    ),
                  ],
                  if (taskStatus.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    _TinyDetail(
                      icon: Icons.fact_check_outlined,
                      text: taskStatus,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactFlowStrip extends StatelessWidget {
  const _CompactFlowStrip({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    if (data.nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.route_rounded,
            title: 'Vista rapida del flujo',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (int index = 0; index < data.nodes.length; index += 1)
                  _FlowStop(
                    node: data.nodes[index],
                    style: _StatusStyle.fromNode(
                      context,
                      data.nodes[index],
                      data.isCurrentNode(data.nodes[index]),
                    ),
                    showConnector: index < data.nodes.length - 1,
                    label: (index + 1).toString(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStop extends StatelessWidget {
  const _FlowStop({
    required this.node,
    required this.style,
    required this.showConnector,
    required this.label,
  });

  final NodoSeguimiento node;
  final _StatusStyle style;
  final bool showConnector;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Column(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: style.background,
                  border: Border.all(color: style.border, width: 2),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: style.isCurrent
                        ? Icon(style.icon, color: style.foreground, size: 22)
                        : Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: style.foreground,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _fallback(node.nombre, _tipoLabel(node.tipo)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: style.foreground,
                ),
              ),
            ],
          ),
        ),
        if (showConnector)
          Container(
            width: 26,
            height: 2,
            margin: const EdgeInsets.only(bottom: 34),
            color: style.border.withValues(alpha: 0.38),
          ),
      ],
    );
  }
}

class _NextStepsPanel extends StatelessWidget {
  const _NextStepsPanel({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    final List<NodoSeguimiento> nextNodes = data.nextNodes;

    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.next_plan_outlined,
            title: 'Proximos pasos',
            subtitle: 'Lo que probablemente viene despues de la etapa actual.',
          ),
          const SizedBox(height: 12),
          if (nextNodes.isEmpty)
            _EmptyLine(
              icon: Icons.flag_circle_outlined,
              text: data.isFinished
                  ? 'Este tramite ya llego al final del flujo.'
                  : 'No hay proximos pasos informados por ahora.',
            )
          else
            Column(
              children: nextNodes
                  .take(3)
                  .map((NodoSeguimiento node) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SimpleNodePreview(
                        node: node,
                        icon: Icons.arrow_forward_rounded,
                        color: Colors.blueGrey.shade700,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _TaskOverviewPanel extends StatelessWidget {
  const _TaskOverviewPanel({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            icon: Icons.fact_check_outlined,
            title: 'Tareas',
            subtitle: 'Resumen simple para saber que paso y que falta.',
          ),
          const SizedBox(height: 12),
          _TaskBucket(
            title: 'En curso',
            icon: Icons.radio_button_checked_rounded,
            color: Theme.of(context).colorScheme.primary,
            items: data.currentTaskLabels,
            emptyText: 'No hay tareas en curso informadas.',
          ),
          const SizedBox(height: 10),
          _TaskBucket(
            title: 'Completadas',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade700,
            items: data.completedTaskLabels,
            emptyText: 'Aun no hay tareas completadas visibles.',
          ),
          const SizedBox(height: 10),
          _TaskBucket(
            title: 'Por venir',
            icon: Icons.schedule_rounded,
            color: Colors.blueGrey.shade700,
            items: data.pendingTaskLabels,
            emptyText: 'No hay tareas pendientes informadas.',
          ),
        ],
      ),
    );
  }
}

class _TaskBucket extends StatelessWidget {
  const _TaskBucket({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> visibleItems = items.take(4).toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (visibleItems.isEmpty)
              Text(
                emptyText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: visibleItems
                    .map((String item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 6, color: color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.data});

  final _SeguimientoData data;

  @override
  Widget build(BuildContext context) {
    if (data.nodes.isEmpty) {
      return const _SectionSurface(
        child: _EmptyLine(
          icon: Icons.route_outlined,
          text: 'No hay etapas para mostrar.',
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < data.nodes.length; index += 1)
          _TimelineStep(
            node: data.nodes[index],
            tasks: data.tasksForNode(data.nodes[index].id),
            index: index,
            isFirst: index == 0,
            isLast: index == data.nodes.length - 1,
            isCurrent: data.isCurrentNode(data.nodes[index]),
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.node,
    required this.tasks,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
  });

  final NodoSeguimiento node;
  final List<TareaSeguimiento> tasks;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _StatusStyle.fromNode(context, node, isCurrent);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 42,
            child: CustomPaint(
              painter: _TimelineMarkerPainter(
                isFirst: isFirst,
                isLast: isLast,
                color: style.border,
                isCurrent: isCurrent,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _TimelineCard(
                node: node,
                tasks: tasks,
                index: index,
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.node,
    required this.tasks,
    required this.index,
    required this.style,
  });

  final NodoSeguimiento node;
  final List<TareaSeguimiento> tasks;
  final int index;
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = _fallback(node.nombre, _tipoLabel(node.tipo));
    final String department = _fallback(node.departamentoNombre, '');
    final String responsible = _firstNonEmpty(<String>[
      node.asignadoANombre,
      node.responsableNombre,
      node.responsableTipo,
    ]);
    final String taskStatus = _estadoTareaLabel(node.estadoTareaActual);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: style.border.withValues(alpha: style.isCurrent ? 1 : 0.32),
          width: style.isCurrent ? 2 : 1,
        ),
        boxShadow: style.isCurrent
            ? <BoxShadow>[
                BoxShadow(
                  color: style.border.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: style.border.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(style.icon, color: style.border, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: style.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: <Widget>[
                          _StatusBadge(
                            text: _estadoSeguimientoLabel(
                              style.isCurrent
                                  ? 'ACTUAL'
                                  : node.estadoSeguimiento,
                            ),
                            color: style.border,
                          ),
                          _StatusBadge(
                            text: _tipoLabel(node.tipo),
                            color: Colors.blueGrey.shade600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (style.isCurrent) ...<Widget>[
              const SizedBox(height: 10),
              _CurrentRibbon(color: style.border),
            ],
            const SizedBox(height: 10),
            _DetailGrid(
              details: <_DetailItem>[
                if (department.isNotEmpty)
                  _DetailItem(
                    icon: Icons.apartment_outlined,
                    label: 'Departamento',
                    value: department,
                  ),
                if (responsible.isNotEmpty)
                  _DetailItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Responsable',
                    value: responsible,
                  ),
                if (taskStatus.isNotEmpty)
                  _DetailItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Tarea',
                    value: taskStatus,
                  ),
              ],
            ),
            if (tasks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _NodeTaskList(tasks: tasks),
            ],
          ],
        ),
      ),
    );
  }
}

class _NodeTaskList extends StatelessWidget {
  const _NodeTaskList({required this.tasks});

  final List<TareaSeguimiento> tasks;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tasks
          .take(3)
          .map((TareaSeguimiento task) {
            final String title = _fallback(task.nombre, 'Tarea del tramite');
            final String status = _estadoTareaLabel(task.estado);
            final String assignee = _fallback(task.asignadoANombre, '');
            final String subtitle = <String>[
              status,
              assignee,
            ].where((String value) => value.trim().isNotEmpty).join(' - ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.assignment_outlined,
                        size: 17,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _SimpleNodePreview extends StatelessWidget {
  const _SimpleNodePreview({
    required this.node,
    required this.icon,
    required this.color,
  });

  final NodoSeguimiento node;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String department = _fallback(node.departamentoNombre, '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _fallback(node.nombre, _tipoLabel(node.tipo)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (department.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.details});

  final List<_DetailItem> details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: details
          .map((_DetailItem item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _TinyDetail(
                icon: item.icon,
                text: '${item.label}: ${item.value}',
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _CurrentRibbon extends StatelessWidget {
  const _CurrentRibbon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Aqui esta ahora',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 22, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightBadge extends StatelessWidget {
  const _LightBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color onPrimary = theme.colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: onPrimary),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TinyDetail extends StatelessWidget {
  const _TinyDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _TimelineMarkerPainter extends CustomPainter {
  const _TimelineMarkerPainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
    required this.isCurrent,
  });

  final bool isFirst;
  final bool isLast;
  final Color color;
  final bool isCurrent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, 28);
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (!isFirst) {
      canvas.drawLine(Offset(center.dx, 0), center, linePaint);
    }

    if (!isLast) {
      canvas.drawLine(center, Offset(center.dx, size.height), linePaint);
    }

    final Paint outerPaint = Paint()
      ..color = color.withValues(alpha: isCurrent ? 0.22 : 0.12)
      ..style = PaintingStyle.fill;
    final Paint innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, isCurrent ? 14 : 11, outerPaint);
    canvas.drawCircle(center, isCurrent ? 7 : 5.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelineMarkerPainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color ||
        oldDelegate.isCurrent != isCurrent;
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StateMessageContent(icon: icon, message: message),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateMessageContent extends StatelessWidget {
  const _StateMessageContent({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 56),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _SeguimientoData {
  _SeguimientoData({
    required this.seguimiento,
    required this.nodes,
    required this.nombre,
    required this.codigo,
    required this.estado,
    required this.currentNodes,
    required this.nextNodes,
    required this.completedCount,
    required this.currentCount,
    required this.pendingCount,
    required this.progress,
    required this.currentTaskLabels,
    required this.completedTaskLabels,
    required this.pendingTaskLabels,
    required this.tasksByNode,
  });

  factory _SeguimientoData.from({
    required TramiteSeguimiento seguimiento,
    required MisTramiteItem fallbackItem,
  }) {
    final List<NodoSeguimiento> nodes = _orderNodes(seguimiento);
    final Set<String> currentIds = seguimiento.nodosActualesIdSet;
    final List<NodoSeguimiento> currentNodes = nodes
        .where((NodoSeguimiento node) {
          return currentIds.contains(node.id) ||
              node.estadoSeguimiento.trim().toUpperCase() == 'ACTUAL';
        })
        .toList(growable: false);

    final int completedCount = nodes
        .where(
          (NodoSeguimiento node) => _isCompletedStatus(node.estadoSeguimiento),
        )
        .length;
    final int currentCount = currentNodes.length;
    final int pendingCount = nodes
        .where(
          (NodoSeguimiento node) => _isPendingStatus(node.estadoSeguimiento),
        )
        .length;
    final int total = math.max(nodes.length, 1);
    final double progress = ((completedCount + (currentCount * 0.5)) / total)
        .clamp(0.0, 1.0);

    final List<NodoSeguimiento> nextNodes = _findNextNodes(
      seguimiento: seguimiento,
      orderedNodes: nodes,
      currentNodes: currentNodes,
    );

    return _SeguimientoData(
      seguimiento: seguimiento,
      nodes: nodes,
      nombre: _fallback(seguimiento.politicaNombre, fallbackItem.nombre),
      codigo: _fallback(seguimiento.codigoTramite, 'Sin codigo'),
      estado: _fallback(
        _estadoInstanciaLabel(seguimiento.estadoInstancia),
        fallbackItem.estado,
      ),
      currentNodes: currentNodes,
      nextNodes: nextNodes,
      completedCount: completedCount,
      currentCount: currentCount,
      pendingCount: pendingCount,
      progress: progress,
      currentTaskLabels: _buildTaskLabels(
        seguimiento: seguimiento,
        nodes: currentNodes,
        filter: _isCurrentTaskStatus,
        fallbackNodes: currentNodes,
      ),
      completedTaskLabels: _buildTaskLabels(
        seguimiento: seguimiento,
        nodes: nodes,
        filter: _isCompletedTaskStatus,
        fallbackNodes: nodes
            .where(
              (NodoSeguimiento node) =>
                  _isCompletedStatus(node.estadoSeguimiento),
            )
            .toList(growable: false),
      ),
      pendingTaskLabels: _buildTaskLabels(
        seguimiento: seguimiento,
        nodes: nodes,
        filter: _isPendingTaskStatus,
        fallbackNodes: nextNodes.isEmpty
            ? nodes
                  .where(
                    (NodoSeguimiento node) =>
                        _isPendingStatus(node.estadoSeguimiento),
                  )
                  .toList(growable: false)
            : nextNodes,
      ),
      tasksByNode: _groupTasksByNode(seguimiento.tareas),
    );
  }

  final TramiteSeguimiento seguimiento;
  final List<NodoSeguimiento> nodes;
  final String nombre;
  final String codigo;
  final String estado;
  final List<NodoSeguimiento> currentNodes;
  final List<NodoSeguimiento> nextNodes;
  final int completedCount;
  final int currentCount;
  final int pendingCount;
  final double progress;
  final List<String> currentTaskLabels;
  final List<String> completedTaskLabels;
  final List<String> pendingTaskLabels;
  final Map<String, List<TareaSeguimiento>> tasksByNode;

  List<DepartamentoActualSeguimiento> get departamentosActuales {
    return seguimiento.departamentosActuales;
  }

  bool get isFinished {
    return nodes.isNotEmpty &&
        nodes.every(
          (NodoSeguimiento node) =>
              _isCompletedStatus(node.estadoSeguimiento) ||
              _isTerminalType(node.tipo),
        );
  }

  String get currentDepartment {
    final String fromDepartment = departamentosActuales
        .map((DepartamentoActualSeguimiento item) => item.departamentoNombre)
        .firstWhere(
          (String value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    if (fromDepartment.isNotEmpty) {
      return fromDepartment;
    }

    final String fromNode = currentNodes
        .map((NodoSeguimiento node) => node.departamentoNombre)
        .firstWhere(
          (String value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    return _fallback(fromNode, 'Ubicacion en revision');
  }

  String get currentNodeLabel {
    final String fromDepartment = departamentosActuales
        .map((DepartamentoActualSeguimiento item) => item.nodoNombre)
        .firstWhere(
          (String value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    if (fromDepartment.isNotEmpty) {
      return fromDepartment;
    }

    final String fromNode = currentNodes
        .map((NodoSeguimiento node) => node.nombre)
        .firstWhere(
          (String value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    return _fallback(fromNode, 'Etapa actual no informada');
  }

  _StatusStyle get currentStyle {
    final NodoSeguimiento? current = currentNodes.isEmpty
        ? null
        : currentNodes.first;
    if (current == null) {
      return const _StatusStyle(
        background: Color(0xFFF5F7FA),
        border: Color(0xFF607D8B),
        foreground: Color(0xFF263238),
        icon: Icons.route_outlined,
        isCurrent: false,
      );
    }

    return _StatusStyle.fromRaw(current, true);
  }

  bool isCurrentNode(NodoSeguimiento node) {
    return currentNodes.any((NodoSeguimiento current) => current.id == node.id);
  }

  List<TareaSeguimiento> tasksForNode(String nodeId) {
    return tasksByNode[nodeId] ?? const <TareaSeguimiento>[];
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    required this.isCurrent,
  });

  factory _StatusStyle.fromNode(
    BuildContext context,
    NodoSeguimiento node,
    bool isCurrent,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final _StatusStyle raw = _StatusStyle.fromRaw(node, isCurrent);
    if (!isCurrent) {
      return raw;
    }

    return _StatusStyle(
      background: colors.primaryContainer,
      border: colors.primary,
      foreground: colors.onPrimaryContainer,
      icon: raw.icon,
      isCurrent: true,
    );
  }

  factory _StatusStyle.fromRaw(NodoSeguimiento node, bool isCurrent) {
    final String estado = (isCurrent ? 'ACTUAL' : node.estadoSeguimiento)
        .toUpperCase();
    final IconData icon = _iconForTipo(node.tipo);

    switch (estado) {
      case 'ACTUAL':
        return _StatusStyle(
          background: const Color(0xFFE8F0FE),
          border: const Color(0xFF124170),
          foreground: const Color(0xFF102A43),
          icon: icon,
          isCurrent: true,
        );
      case 'COMPLETADO':
        return _StatusStyle(
          background: const Color(0xFFEAF6EF),
          border: const Color(0xFF2E7D32),
          foreground: const Color(0xFF1B5E20),
          icon: icon,
          isCurrent: false,
        );
      case 'EN_ESPERA':
        return _StatusStyle(
          background: const Color(0xFFFFF7E6),
          border: const Color(0xFFB26A00),
          foreground: const Color(0xFF7A4B00),
          icon: icon,
          isCurrent: false,
        );
      case 'CANCELADO':
      case 'RECHAZADO':
        return _StatusStyle(
          background: const Color(0xFFFDECEC),
          border: const Color(0xFFC62828),
          foreground: const Color(0xFF8E0000),
          icon: icon,
          isCurrent: false,
        );
      case 'PENDIENTE':
      default:
        return _StatusStyle(
          background: const Color(0xFFF6F8FA),
          border: const Color(0xFF78909C),
          foreground: const Color(0xFF37474F),
          icon: icon,
          isCurrent: false,
        );
    }
  }

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
  final bool isCurrent;
}

List<NodoSeguimiento> _orderNodes(TramiteSeguimiento seguimiento) {
  final List<NodoSeguimiento> nodes = List<NodoSeguimiento>.from(
    seguimiento.nodos,
  );
  if (nodes.length <= 1) {
    return nodes;
  }

  final Map<String, NodoSeguimiento> byId = <String, NodoSeguimiento>{
    for (final NodoSeguimiento node in nodes) node.id: node,
  };
  final Map<String, int> originalIndex = <String, int>{
    for (int index = 0; index < nodes.length; index += 1)
      nodes[index].id: index,
  };
  final Map<String, List<String>> outgoing = <String, List<String>>{};
  final Map<String, int> incoming = <String, int>{
    for (final NodoSeguimiento node in nodes) node.id: 0,
  };

  for (final ConexionSeguimiento connection in seguimiento.conexiones) {
    if (!byId.containsKey(connection.origen) ||
        !byId.containsKey(connection.destino)) {
      continue;
    }

    outgoing
        .putIfAbsent(connection.origen, () => <String>[])
        .add(connection.destino);
    incoming[connection.destino] = (incoming[connection.destino] ?? 0) + 1;
  }

  if (outgoing.isEmpty) {
    return _fallbackNodeOrder(nodes);
  }

  int compareStable(NodoSeguimiento a, NodoSeguimiento b) {
    final bool aInicio = a.tipo.trim().toUpperCase() == 'INICIO';
    final bool bInicio = b.tipo.trim().toUpperCase() == 'INICIO';
    if (aInicio != bInicio) {
      return aInicio ? -1 : 1;
    }

    return (originalIndex[a.id] ?? 0).compareTo(originalIndex[b.id] ?? 0);
  }

  final List<NodoSeguimiento> explicitStarts = nodes
      .where(
        (NodoSeguimiento node) => node.tipo.trim().toUpperCase() == 'INICIO',
      )
      .toList(growable: false);
  final List<NodoSeguimiento> starts = explicitStarts.isNotEmpty
      ? explicitStarts
      : nodes
            .where((NodoSeguimiento node) => (incoming[node.id] ?? 0) == 0)
            .toList(growable: false);
  starts.sort(compareStable);

  final Map<String, int> remainingIncoming = Map<String, int>.from(incoming);
  final Set<String> queued = <String>{};
  final Set<String> visited = <String>{};
  final List<NodoSeguimiento> ordered = <NodoSeguimiento>[];
  final List<NodoSeguimiento> queue = <NodoSeguimiento>[];

  void enqueue(NodoSeguimiento node) {
    if (queued.add(node.id) && !visited.contains(node.id)) {
      queue.add(node);
    }
  }

  for (final NodoSeguimiento node in starts) {
    enqueue(node);
  }

  while (ordered.length < nodes.length) {
    if (queue.isEmpty) {
      final List<NodoSeguimiento> available = nodes
          .where(
            (NodoSeguimiento node) =>
                !visited.contains(node.id) &&
                (remainingIncoming[node.id] ?? 0) <= 0,
          )
          .toList(growable: false);
      available.sort(compareStable);

      if (available.isNotEmpty) {
        enqueue(available.first);
      } else {
        final List<NodoSeguimiento> remaining = nodes
            .where((NodoSeguimiento node) => !visited.contains(node.id))
            .toList(growable: false);
        remaining.sort(compareStable);
        if (remaining.isEmpty) {
          break;
        }
        enqueue(remaining.first);
      }
    }

    final NodoSeguimiento current = queue.removeAt(0);
    if (!visited.add(current.id)) {
      continue;
    }

    ordered.add(current);

    for (final String childId in outgoing[current.id] ?? <String>[]) {
      final NodoSeguimiento? child = byId[childId];
      if (child == null || visited.contains(child.id)) {
        continue;
      }

      remainingIncoming[child.id] = (remainingIncoming[child.id] ?? 0) - 1;
      if ((remainingIncoming[child.id] ?? 0) <= 0) {
        enqueue(child);
      }
    }
  }

  return ordered;
}

List<NodoSeguimiento> _fallbackNodeOrder(List<NodoSeguimiento> nodes) {
  final List<NodoSeguimiento> ordered = List<NodoSeguimiento>.from(nodes);

  ordered.sort((NodoSeguimiento a, NodoSeguimiento b) {
    final int aWeight = _typeWeight(a.tipo);
    final int bWeight = _typeWeight(b.tipo);
    if (aWeight != bWeight) {
      return aWeight.compareTo(bWeight);
    }

    return nodes.indexOf(a).compareTo(nodes.indexOf(b));
  });
  return ordered;
}

int _typeWeight(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'INICIO':
      return 0;
    case 'FIN':
      return 2;
    default:
      return 1;
  }
}

List<NodoSeguimiento> _findNextNodes({
  required TramiteSeguimiento seguimiento,
  required List<NodoSeguimiento> orderedNodes,
  required List<NodoSeguimiento> currentNodes,
}) {
  final Map<String, NodoSeguimiento> byId = <String, NodoSeguimiento>{
    for (final NodoSeguimiento node in orderedNodes) node.id: node,
  };
  final Set<String> currentIds = currentNodes
      .map((NodoSeguimiento node) => node.id)
      .toSet();
  final List<NodoSeguimiento> fromConnections = <NodoSeguimiento>[];

  for (final ConexionSeguimiento connection in seguimiento.conexiones) {
    if (!currentIds.contains(connection.origen)) {
      continue;
    }

    final NodoSeguimiento? destination = byId[connection.destino];
    if (destination != null &&
        !_isCompletedStatus(destination.estadoSeguimiento) &&
        !currentIds.contains(destination.id)) {
      fromConnections.add(destination);
    }
  }

  if (fromConnections.isNotEmpty) {
    return _uniqueNodes(fromConnections);
  }

  if (currentNodes.isNotEmpty) {
    final int lastCurrentIndex = orderedNodes.lastIndexWhere(
      (NodoSeguimiento node) => currentIds.contains(node.id),
    );
    if (lastCurrentIndex >= 0 && lastCurrentIndex < orderedNodes.length - 1) {
      return orderedNodes
          .skip(lastCurrentIndex + 1)
          .where(
            (NodoSeguimiento node) =>
                !_isCompletedStatus(node.estadoSeguimiento) &&
                !currentIds.contains(node.id),
          )
          .take(3)
          .toList(growable: false);
    }
  }

  return orderedNodes
      .where((NodoSeguimiento node) => _isPendingStatus(node.estadoSeguimiento))
      .take(3)
      .toList(growable: false);
}

List<NodoSeguimiento> _uniqueNodes(List<NodoSeguimiento> nodes) {
  final Set<String> seen = <String>{};
  return nodes.where((NodoSeguimiento node) => seen.add(node.id)).toList();
}

List<String> _buildTaskLabels({
  required TramiteSeguimiento seguimiento,
  required List<NodoSeguimiento> nodes,
  required bool Function(String status) filter,
  required List<NodoSeguimiento> fallbackNodes,
}) {
  final Map<String, int> nodeOrder = <String, int>{
    for (int index = 0; index < nodes.length; index += 1)
      nodes[index].id: index,
  };
  final Map<String, int> taskOrder = <String, int>{
    for (int index = 0; index < seguimiento.tareas.length; index += 1)
      seguimiento.tareas[index].id: index,
  };
  final Set<String> nodeIds = nodes
      .map((NodoSeguimiento node) => node.id)
      .toSet();
  final List<TareaSeguimiento> matchingTasks = seguimiento.tareas
      .where((TareaSeguimiento task) {
        final bool matchesStatus = filter(task.estado);
        final bool matchesNode =
            nodeIds.isEmpty || nodeIds.contains(task.nodoId);
        return matchesStatus && matchesNode;
      })
      .toList(growable: false);

  matchingTasks.sort((TareaSeguimiento a, TareaSeguimiento b) {
    final int nodeCompare = (nodeOrder[a.nodoId] ?? 999999).compareTo(
      nodeOrder[b.nodoId] ?? 999999,
    );
    if (nodeCompare != 0) {
      return nodeCompare;
    }

    return (taskOrder[a.id] ?? 999999).compareTo(taskOrder[b.id] ?? 999999);
  });

  final List<String> labels = matchingTasks
      .map((TareaSeguimiento task) {
        final String name = _fallback(task.nombre, 'Tarea del tramite');
        final String assignee = _fallback(task.asignadoANombre, '');
        if (assignee.isEmpty) {
          return name;
        }

        return '$name - $assignee';
      })
      .where((String label) => label.trim().isNotEmpty)
      .toList(growable: false);

  if (labels.isNotEmpty) {
    return labels;
  }

  return fallbackNodes
      .map(
        (NodoSeguimiento node) => _fallback(node.nombre, _tipoLabel(node.tipo)),
      )
      .where((String label) => label.trim().isNotEmpty)
      .toList(growable: false);
}

Map<String, List<TareaSeguimiento>> _groupTasksByNode(
  List<TareaSeguimiento> tasks,
) {
  final Map<String, List<TareaSeguimiento>> grouped =
      <String, List<TareaSeguimiento>>{};

  for (final TareaSeguimiento task in tasks) {
    final String nodeId = task.nodoId.trim();
    if (nodeId.isEmpty) {
      continue;
    }

    grouped.putIfAbsent(nodeId, () => <TareaSeguimiento>[]).add(task);
  }

  return grouped;
}

bool _isCompletedStatus(String value) {
  final String normalized = value.trim().toUpperCase();
  return normalized == 'COMPLETADO' ||
      normalized == 'FINALIZADO' ||
      normalized == 'FINALIZADA' ||
      normalized == 'APROBADO' ||
      normalized == 'APROBADA';
}

bool _isPendingStatus(String value) {
  final String normalized = value.trim().toUpperCase();
  return normalized.isEmpty ||
      normalized == 'PENDIENTE' ||
      normalized == 'EN_ESPERA' ||
      normalized == 'ASIGNADA' ||
      normalized == 'CREADA';
}

bool _isCurrentTaskStatus(String value) {
  final String normalized = value.trim().toUpperCase();
  return normalized == 'ACTUAL' ||
      normalized == 'EN_CURSO' ||
      normalized == 'ASIGNADA' ||
      normalized == 'EN_PROCESO';
}

bool _isCompletedTaskStatus(String value) {
  return _isCompletedStatus(value) ||
      value.trim().toUpperCase() == 'COMPLETADA';
}

bool _isPendingTaskStatus(String value) {
  return _isPendingStatus(value);
}

bool _isTerminalType(String value) {
  return value.trim().toUpperCase() == 'FIN';
}

String _fallback(String value, String fallback) {
  final String normalizedValue = value.trim();
  return normalizedValue.isEmpty ? fallback : normalizedValue;
}

String _firstNonEmpty(List<String> values) {
  for (final String value in values) {
    final String normalizedValue = value.trim();
    if (normalizedValue.isNotEmpty) {
      return normalizedValue;
    }
  }

  return '';
}

String _estadoInstanciaLabel(String value) {
  final String normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'EN_CURSO':
      return 'En curso';
    case 'FINALIZADA':
      return 'Finalizada';
    case 'PAUSADA':
      return 'Pausada';
    case 'CANCELADA':
      return 'Cancelada';
    default:
      return _prettyRaw(value);
  }
}

String _estadoSeguimientoLabel(String value) {
  final String normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'ACTUAL':
      return 'Actual';
    case 'COMPLETADO':
      return 'Completado';
    case 'PENDIENTE':
      return 'Pendiente';
    case 'EN_ESPERA':
      return 'En espera';
    case 'CANCELADO':
      return 'Cancelado';
    case 'RECHAZADO':
      return 'Rechazado';
    default:
      return _prettyRaw(value);
  }
}

String _estadoTareaLabel(String value) {
  final String normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'EN_CURSO':
      return 'En curso';
    case 'ASIGNADA':
      return 'Asignada';
    case 'COMPLETADA':
    case 'COMPLETADO':
      return 'Completada';
    case 'PENDIENTE':
      return 'Pendiente';
    case 'EN_ESPERA':
      return 'En espera';
    case 'RECHAZADA':
    case 'RECHAZADO':
      return 'Rechazada';
    default:
      return _prettyRaw(value);
  }
}

String _tipoLabel(String value) {
  final String normalized = value.trim().toUpperCase();
  switch (normalized) {
    case 'INICIO':
      return 'Inicio';
    case 'ACTIVIDAD':
      return 'Actividad';
    case 'DECISION':
      return 'Decision';
    case 'FORK':
      return 'Bifurcacion';
    case 'JOIN':
      return 'Union';
    case 'FIN':
      return 'Fin';
    default:
      return _prettyRaw(value);
  }
}

String _prettyRaw(String value) {
  final String normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) {
    return '';
  }

  return normalized[0].toUpperCase() + normalized.substring(1);
}

IconData _iconForTipo(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'INICIO':
      return Icons.play_circle_outline_rounded;
    case 'DECISION':
      return Icons.call_split_rounded;
    case 'FORK':
      return Icons.fork_right_rounded;
    case 'JOIN':
      return Icons.merge_type_rounded;
    case 'FIN':
      return Icons.flag_circle_rounded;
    case 'ACTIVIDAD':
    default:
      return Icons.task_alt_rounded;
  }
}
