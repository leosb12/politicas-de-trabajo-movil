import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../guia_usuario_movil/dominio/modelos/contexto_guia_usuario_movil.dart';
import '../../../guia_usuario_movil/presentacion/widgets/boton_guia_usuario_movil.dart';
import '../../domain/models/tarea_formulario_detalle.dart';
import '../viewmodels/tarea_formulario_providers.dart';

class TareaFormularioPendienteView extends ConsumerStatefulWidget {
  const TareaFormularioPendienteView({
    super.key,
    required this.usuarioId,
    required this.tareaId,
    required this.instanciaId,
    required this.nombreActividad,
  });

  final String usuarioId;
  final String tareaId;
  final String instanciaId;
  final String nombreActividad;

  @override
  ConsumerState<TareaFormularioPendienteView> createState() =>
      _TareaFormularioPendienteViewState();
}

class _TareaFormularioPendienteViewState
    extends ConsumerState<TareaFormularioPendienteView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _booleanValues = <String, bool>{};
  final Map<String, DateTime?> _dateValues = <String, DateTime?>{};
  final TextEditingController _observacionesController =
      TextEditingController();

  TareaFormularioDetalle? _detalle;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_cargarDetalle);
  }

  @override
  void dispose() {
    _disposeControllers();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final TareaFormularioDetalle detalle = await ref
          .read(tareaFormularioDataSourceProvider)
          .obtenerDetalle(usuarioId: widget.usuarioId, tareaId: widget.tareaId);

      _hydrateForm(detalle);

      if (!mounted) {
        return;
      }

      setState(() {
        _detalle = detalle;
        _isLoading = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detalle = null;
        _isLoading = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detalle = null;
        _isLoading = false;
        _errorMessage = 'No se pudo cargar la tarea desde el servidor.';
      });
    }
  }

  void _hydrateForm(TareaFormularioDetalle detalle) {
    _disposeControllers();
    _booleanValues.clear();
    _dateValues.clear();

    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      final dynamic initialValue = detalle.formularioRespuesta[campo.clave];
      switch (campo.tipoNormalizado) {
        case 'BOOLEANO':
          _booleanValues[campo.clave] = _parseBool(initialValue) ?? false;
          break;
        case 'FECHA':
          _dateValues[campo.clave] = _parseDate(initialValue);
          break;
        default:
          _textControllers[campo.clave] = TextEditingController(
            text: _stringValue(initialValue),
          );
          break;
      }
    }

    _observacionesController.text = detalle.observaciones;
  }

  void _disposeControllers() {
    for (final TextEditingController controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }

  Future<void> _seleccionarFecha(CampoFormularioDetalle campo) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _dateValues[campo.clave] ?? _parseDate(DateTime.now()) ?? now;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _dateValues[campo.clave] = selected;
    });
  }

  Future<void> _completarTarea() async {
    final TareaFormularioDetalle? detalle = _detalle;
    if (detalle == null || _isSubmitting) {
      return;
    }

    final String? archivoNoSoportado = _firstUnsupportedFileField(detalle);
    if (archivoNoSoportado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El campo $archivoNoSoportado requiere archivo y aun no esta disponible en movil.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String? campoFaltante = _firstMissingStructuredField(detalle);
    if (campoFaltante != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa el campo $campoFaltante antes de continuar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final FormState? form = _formKey.currentState;
    if (form != null && !form.validate()) {
      return;
    }

    final Map<String, dynamic> payload = _buildPayload(detalle);

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(tareaFormularioDataSourceProvider)
          .completarTarea(
            usuarioId: widget.usuarioId,
            tareaId: widget.tareaId,
            formularioRespuesta: payload,
            observaciones: _observacionesController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la tarea.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, dynamic> _buildPayload(TareaFormularioDetalle detalle) {
    final Map<String, dynamic> payload = <String, dynamic>{};

    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      switch (campo.tipoNormalizado) {
        case 'BOOLEANO':
          payload[campo.clave] = _booleanValues[campo.clave] ?? false;
          break;
        case 'NUMERO':
          final String value = (_textControllers[campo.clave]?.text ?? '')
              .trim();
          payload[campo.clave] = _parseNumber(value);
          break;
        case 'FECHA':
          final DateTime? value = _dateValues[campo.clave];
          payload[campo.clave] = value?.toIso8601String().split('T').first;
          break;
        case 'ARCHIVO':
          final String value = (_textControllers[campo.clave]?.text ?? '')
              .trim();
          payload[campo.clave] = value;
          break;
        case 'TEXTO':
        default:
          payload[campo.clave] = (_textControllers[campo.clave]?.text ?? '')
              .trim();
          break;
      }
    }

    return payload;
  }

  String? _firstUnsupportedFileField(TareaFormularioDetalle detalle) {
    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      if (campo.tipoNormalizado != 'ARCHIVO') {
        continue;
      }

      final dynamic initialValue = detalle.formularioRespuesta[campo.clave];
      if (_stringValue(initialValue).trim().isEmpty) {
        return campo.clave;
      }
    }

    return null;
  }

  String? _firstMissingStructuredField(TareaFormularioDetalle detalle) {
    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      switch (campo.tipoNormalizado) {
        case 'FECHA':
          if (_dateValues[campo.clave] == null) {
            return campo.clave;
          }
          break;
        default:
          break;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Completar tarea')),
      floatingActionButton: BotonGuiaUsuarioMovil(
        heroTag: 'guia_formulario_${widget.tareaId}',
        usuarioId: widget.usuarioId,
        nombreUsuario: authState.authenticatedUser?.nombre.trim() ?? '',
        pantalla: PantallasGuiaUsuarioMovil.formularioSolicitud,
        contexto: _construirContextoGuia(),
        preguntasSugeridas: const <String>[
          '¿Qué tengo que completar aquí?',
          '¿Qué documentos me faltan?',
          '¿Cómo subo un documento?',
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _cargarDetalle,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final TareaFormularioDetalle? detalle = _detalle;
    if (detalle == null) {
      return const SizedBox.shrink();
    }

    final bool tareaCerrada = !detalle.estaAbierta;
    final String heading = detalle.nombreActividad.trim().isEmpty
        ? widget.nombreActividad
        : detalle.nombreActividad;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          _TaskHeaderCard(
            titulo: heading,
            estado: detalle.estadoTarea,
            requiereArchivoNoSoportado:
                _firstUnsupportedFileField(detalle) != null,
          ),
          const SizedBox(height: 14),
          if (detalle.formularioDefinicion.isEmpty)
            const _InlineInfo(
              icon: Icons.info_outline_rounded,
              message:
                  'Esta actividad no requiere campos adicionales. Puedes completarla directamente desde el celular.',
            )
          else
            ...detalle.formularioDefinicion.map((CampoFormularioDetalle campo) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildField(context, campo),
              );
            }),
          const SizedBox(height: 2),
          TextFormField(
            controller: _observacionesController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Observaciones (opcional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (tareaCerrada) ...<Widget>[
            const SizedBox(height: 16),
            const _InlineInfo(
              icon: Icons.check_circle_outline_rounded,
              message:
                  'Esta tarea ya no esta abierta. Vuelve a seguimiento para ver el estado actualizado.',
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: tareaCerrada || _isSubmitting ? null : _completarTarea,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_isSubmitting ? 'Completando...' : 'Completar tarea'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, CampoFormularioDetalle campo) {
    final String label = _prettyLabel(campo.clave);

    switch (campo.tipoNormalizado) {
      case 'BOOLEANO':
        final bool currentValue = _booleanValues[campo.clave] ?? false;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            value: currentValue,
            onChanged: _isSubmitting
                ? null
                : (bool value) {
                    setState(() {
                      _booleanValues[campo.clave] = value;
                    });
                  },
            title: Text(label),
            subtitle: const Text('Seleccion obligatoria'),
          ),
        );
      case 'FECHA':
        final DateTime? value = _dateValues[campo.clave];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSubmitting ? null : () => _seleccionarFecha(campo),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_rounded),
            ),
            child: Text(
              value == null ? 'Selecciona una fecha' : _formatDate(value),
            ),
          ),
        );
      case 'ARCHIVO':
        return const _InlineInfo(
          icon: Icons.attach_file_rounded,
          message:
              'Los campos de archivo aun no se pueden cargar desde esta vista movil.',
        );
      case 'NUMERO':
        return TextFormField(
          controller: _textControllers[campo.clave],
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (String? value) {
            final String normalized = (value ?? '').trim();
            if (normalized.isEmpty) {
              return 'Este campo es obligatorio.';
            }
            if (_parseNumber(normalized) == null) {
              return 'Ingresa un numero valido.';
            }
            return null;
          },
        );
      case 'TEXTO':
      default:
        return TextFormField(
          controller: _textControllers[campo.clave],
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (String? value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Este campo es obligatorio.';
            }
            return null;
          },
        );
    }
  }

  String _prettyLabel(String value) {
    final List<String> parts = value
        .trim()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((String part) => part.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'Campo';
    }

    return parts
        .map(
          (String part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  bool? _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final String normalized = _stringValue(value).toUpperCase();
    if (normalized == 'TRUE' || normalized == 'SI' || normalized == 'YES') {
      return true;
    }
    if (normalized == 'FALSE' || normalized == 'NO') {
      return false;
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final String normalized = _stringValue(value);
    if (normalized.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(normalized);
    } catch (_) {
      if (normalized.length >= 10) {
        try {
          return DateTime.parse(normalized.substring(0, 10));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  num? _parseNumber(String value) {
    final String normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    if (!normalized.contains('.')) {
      return int.tryParse(normalized) ?? double.tryParse(normalized);
    }

    return double.tryParse(normalized);
  }

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  ContextoGuiaUsuarioMovil _construirContextoGuia() {
    final TareaFormularioDetalle? detalle = _detalle;
    final List<String> documentosFaltantes = detalle == null
        ? const <String>[]
        : _documentosFaltantes(detalle);
    final List<String> acciones = <String>[
      'CONSULTAR_ESTADO',
      'VER_DETALLE_TRAMITE',
    ];
    if (documentosFaltantes.isNotEmpty) {
      acciones.add('SUBIR_DOCUMENTO');
    }

    return ContextoGuiaUsuarioMovil(
      tramiteId: widget.instanciaId,
      etapaActual: EtapaActualGuiaUsuarioMovil(
        identificador: widget.tareaId,
        nombre: detalle?.nombreActividad.trim().isNotEmpty == true
            ? detalle!.nombreActividad
            : widget.nombreActividad,
        descripcion:
            'Completa la informacion solicitada para que el tramite pueda continuar.',
        responsable: detalle?.responsableTipo ?? 'USUARIO',
      ),
      documentosFaltantes: documentosFaltantes,
      observaciones: _observacionesGuia(detalle),
      accionesDisponibles: acciones,
    );
  }

  List<String> _documentosFaltantes(TareaFormularioDetalle detalle) {
    final List<String> documentos = <String>[];
    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      if (campo.tipoNormalizado != 'ARCHIVO') {
        continue;
      }
      final String valorActual = _stringValue(
        detalle.formularioRespuesta[campo.clave],
      );
      if (valorActual.trim().isEmpty) {
        documentos.add(_prettyLabel(campo.clave));
      }
    }
    return documentos;
  }

  List<String> _observacionesGuia(TareaFormularioDetalle? detalle) {
    if (detalle == null) {
      return const <String>[];
    }

    final String observacion = detalle.observaciones.trim();
    if (observacion.isEmpty) {
      return const <String>[];
    }
    return <String>[observacion];
  }
}

class _TaskHeaderCard extends StatelessWidget {
  const _TaskHeaderCard({
    required this.titulo,
    required this.estado,
    required this.requiereArchivoNoSoportado,
  });

  final String titulo;
  final String estado;
  final bool requiereArchivoNoSoportado;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MiniBadge(
                  icon: Icons.assignment_outlined,
                  text: _prettyEstado(estado),
                ),
                if (requiereArchivoNoSoportado)
                  const _MiniBadge(
                    icon: Icons.warning_amber_rounded,
                    text: 'Archivo no soportado en movil',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyEstado(String value) {
    final String normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'EN_PROCESO':
        return 'En proceso';
      case 'COMPLETADA':
        return 'Completada';
      default:
        return value.trim().isEmpty ? 'Sin estado' : value;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: colors.onPrimaryContainer),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18, color: colors.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
