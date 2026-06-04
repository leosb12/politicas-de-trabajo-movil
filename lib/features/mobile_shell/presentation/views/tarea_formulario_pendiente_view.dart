import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

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
  final Map<String, List<String>> _checkboxValues = <String, List<String>>{};
  final Map<String, List<List<String>>> _gridValues = <String, List<List<String>>>{};
  final Map<String, String> _uploadedFileIds = <String, String>{};
  final Map<String, String> _uploadedFileNames = <String, String>{};
  final Map<String, bool> _uploadingFields = <String, bool>{};
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
    _checkboxValues.clear();
    _gridValues.clear();
    _uploadedFileIds.clear();
    _uploadedFileNames.clear();
    _uploadingFields.clear();

    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      final dynamic initialValue = detalle.formularioRespuesta[campo.clave];
      switch (campo.tipoNormalizado) {
        case 'BOOLEANO':
          _booleanValues[campo.clave] = _parseBool(initialValue) ?? false;
          break;
        case 'FECHA':
          _dateValues[campo.clave] = _parseDate(initialValue);
          break;
        case 'CHECKBOX':
          if (initialValue is List) {
            _checkboxValues[campo.clave] = initialValue.map((e) => e.toString()).toList();
          } else if (initialValue != null && initialValue.toString().isNotEmpty) {
            _checkboxValues[campo.clave] = initialValue
                .toString()
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else {
            _checkboxValues[campo.clave] = <String>[];
          }
          break;
        case 'GRID':
          final int rows = int.tryParse(campo.placeholder ?? '') ?? 3;
          final int cols = campo.opciones?.length ?? 2;
          final List<List<String>> matrix = List<List<String>>.generate(
            rows,
            (_) => List<String>.filled(cols, ''),
          );
          if (initialValue is List) {
            for (int r = 0; r < rows && r < initialValue.length; r++) {
              final dynamic rowVal = initialValue[r];
              if (rowVal is List) {
                for (int c = 0; c < cols && c < rowVal.length; c++) {
                  matrix[r][c] = rowVal[c]?.toString() ?? '';
                }
              }
            }
          }
          _gridValues[campo.clave] = matrix;
          break;
        case 'LABEL':
          // LABEL does not hold input values
          break;
        case 'ARCHIVO':
          final String initialValStr = _stringValue(initialValue);
          if (initialValStr.isNotEmpty) {
            _uploadedFileIds[campo.clave] = initialValStr;
            _uploadedFileNames[campo.clave] = 'Archivo adjunto';
          }
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
        case 'CHECKBOX':
          payload[campo.clave] = _checkboxValues[campo.clave] ?? <String>[];
          break;
        case 'GRID':
          payload[campo.clave] = _gridValues[campo.clave] ?? <List<String>>[];
          break;
        case 'LABEL':
          // LABEL is read-only
          break;
        case 'ARCHIVO':
          payload[campo.clave] = _uploadedFileIds[campo.clave] ?? '';
          break;
        case 'TEXTO':
        case 'SELECCION':
        default:
          payload[campo.clave] = (_textControllers[campo.clave]?.text ?? '')
              .trim();
          break;
      }
    }

    return payload;
  }

  Future<void> _seleccionarArchivo(CampoFormularioDetalle campo) async {
    if (_uploadingFields[campo.clave] == true) return;

    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;
      final List<int>? bytes = file.bytes;
      if (bytes == null) {
        throw Exception('No se pudo leer el contenido del archivo.');
      }

      setState(() {
        _uploadingFields[campo.clave] = true;
      });

      final String fileId = await ref
          .read(tareaFormularioDataSourceProvider)
          .subirArchivo(
            usuarioId: widget.usuarioId,
            instanciaId: widget.instanciaId,
            tareaId: widget.tareaId,
            campoId: campo.clave,
            nombreArchivo: file.name,
            bytes: bytes,
          );

      setState(() {
        _uploadedFileIds[campo.clave] = fileId;
        _uploadedFileNames[campo.clave] = file.name;
        _uploadingFields[campo.clave] = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archivo "${file.name}" subido con éxito.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _uploadingFields[campo.clave] = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir archivo: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _eliminarArchivo(CampoFormularioDetalle campo) {
    setState(() {
      _uploadedFileIds.remove(campo.clave);
      _uploadedFileNames.remove(campo.clave);
    });
  }

  String? _firstMissingStructuredField(TareaFormularioDetalle detalle) {
    for (final CampoFormularioDetalle campo in detalle.formularioDefinicion) {
      if (!campo.requerido) {
        continue;
      }
      switch (campo.tipoNormalizado) {
        case 'FECHA':
          if (_dateValues[campo.clave] == null) {
            return campo.etiqueta ?? _prettyLabel(campo.clave);
          }
          break;
        case 'CHECKBOX':
          final List<String> checked = _checkboxValues[campo.clave] ?? <String>[];
          if (checked.isEmpty) {
            return campo.etiqueta ?? _prettyLabel(campo.clave);
          }
          break;
        case 'GRID':
          final List<List<String>> grid = _gridValues[campo.clave] ?? <List<String>>[];
          bool hasEmptyCell = false;
          for (final List<String> row in grid) {
            if (row.any((cell) => cell.trim().isEmpty)) {
              hasEmptyCell = true;
              break;
            }
          }
          if (hasEmptyCell) {
            return 'celdas del campo "${campo.etiqueta ?? _prettyLabel(campo.clave)}"';
          }
          break;
        case 'ARCHIVO':
          final String fileId = _uploadedFileIds[campo.clave] ?? _stringValue(detalle.formularioRespuesta[campo.clave]);
          if (fileId.trim().isEmpty) {
            return campo.etiqueta ?? _prettyLabel(campo.clave);
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
            requiereArchivoNoSoportado: false,
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
    final String label = campo.etiqueta != null && campo.etiqueta!.trim().isNotEmpty
        ? campo.etiqueta!
        : _prettyLabel(campo.clave);

    switch (campo.tipoNormalizado) {
      case 'LABEL':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (campo.ayuda != null && campo.ayuda!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  campo.ayuda!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ],
          ),
        );

      case 'SELECCION':
        final List<String> options = campo.opciones ?? <String>[];
        final String? currentValue = _textControllers[campo.clave]?.text;
        final String? selectedValue = options.contains(currentValue) ? currentValue : null;

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: label + (campo.requerido ? ' *' : ''),
            hintText: campo.placeholder ?? 'Selecciona una opción',
            helperText: campo.ayuda,
            border: const OutlineInputBorder(),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: _isSubmitting
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _textControllers[campo.clave]?.text = newValue;
                    });
                  }
                },
          validator: (String? value) {
            if (campo.requerido && (value == null || value.trim().isEmpty)) {
              return 'Selecciona una opción.';
            }
            return null;
          },
        );

      case 'CHECKBOX':
        final List<String> options = campo.opciones ?? <String>[];
        final List<String> checkedList = _checkboxValues[campo.clave] ?? <String>[];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$label${campo.requerido ? ' *' : ''}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (campo.ayuda != null && campo.ayuda!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  campo.ayuda!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              if (options.isEmpty)
                Text(
                  'Sin opciones configuradas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                )
              else
                ...options.map((String option) {
                  final bool isChecked = checkedList.contains(option);
                  return CheckboxListTile(
                    title: Text(option),
                    value: isChecked,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: _isSubmitting
                        ? null
                        : (bool? checked) {
                            setState(() {
                              final List<String> currentList = List<String>.from(checkedList);
                              if (checked == true) {
                                if (!currentList.contains(option)) {
                                  currentList.add(option);
                                }
                              } else {
                                currentList.remove(option);
                              }
                              _checkboxValues[campo.clave] = currentList;
                            });
                          },
                  );
                }),
            ],
          ),
        );

      case 'GRID':
        final List<String> columns = campo.opciones ?? <String>[];
        final List<List<String>> rowsData = _gridValues[campo.clave] ?? <List<String>>[];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$label${campo.requerido ? ' *' : ''}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (campo.ayuda != null && campo.ayuda!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  campo.ayuda!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(120),
                    border: TableBorder.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    children: <TableRow>[
                      if (columns.isNotEmpty)
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          children: columns.map((String colName) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                colName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                      ...Iterable<int>.generate(rowsData.length).map((int rIdx) {
                        final List<String> rowCells = rowsData[rIdx];
                        return TableRow(
                          children: Iterable<int>.generate(rowCells.length).map((int cIdx) {
                            final String cellVal = rowCells[cIdx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: TextFormField(
                                initialValue: cellVal,
                                enabled: !_isSubmitting,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: '...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                ),
                                onChanged: (String newVal) {
                                  rowsData[rIdx][cIdx] = newVal;
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

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
            subtitle: campo.ayuda != null && campo.ayuda!.trim().isNotEmpty
                ? Text(campo.ayuda!)
                : const Text('Seleccion obligatoria'),
          ),
        );

      case 'FECHA':
        final DateTime? value = _dateValues[campo.clave];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSubmitting ? null : () => _seleccionarFecha(campo),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label + (campo.requerido ? ' *' : ''),
              helperText: campo.ayuda,
              border: OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_rounded),
            ),
            child: Text(
              value == null ? (campo.placeholder ?? 'Selecciona una fecha') : _formatDate(value),
            ),
          ),
        );

      case 'ARCHIVO':
        final String? fileName = _uploadedFileNames[campo.clave];
        final bool isUploading = _uploadingFields[campo.clave] ?? false;
        final bool hasFile = fileName != null || (_uploadedFileIds[campo.clave] != null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label + (campo.requerido ? ' *' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (campo.ayuda != null && campo.ayuda!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                campo.ayuda!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasFile ? Colors.green.shade300 : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: hasFile ? Colors.green.shade50.withOpacity(0.5) : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    hasFile ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                    color: hasFile ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasFile ? (fileName ?? 'Archivo adjunto') : 'Subir documento',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                            color: hasFile ? Colors.green.shade900 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!hasFile && !isUploading)
                          Text(
                            campo.placeholder ?? 'Word, Excel, PDF, PowerPoint, Imagen o Video',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        if (isUploading)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Subiendo archivo...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasFile && !isUploading)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: _isSubmitting ? null : () => _eliminarArchivo(campo),
                    )
                  else if (!isUploading)
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _seleccionarArchivo(campo),
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );

      case 'NUMERO':
        return TextFormField(
          controller: _textControllers[campo.clave],
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            hintText: campo.placeholder,
            helperText: campo.ayuda,
            border: const OutlineInputBorder(),
          ),
          validator: (String? value) {
            final String normalized = (value ?? '').trim();
            if (campo.requerido && normalized.isEmpty) {
              return 'Este campo es obligatorio.';
            }
            if (normalized.isNotEmpty && _parseNumber(normalized) == null) {
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
            hintText: campo.placeholder,
            helperText: campo.ayuda,
            border: const OutlineInputBorder(),
          ),
          validator: (String? value) {
            if (campo.requerido && (value ?? '').trim().isEmpty) {
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
