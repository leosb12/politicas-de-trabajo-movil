import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../mobile_shell/data/datasources/offline_tramite_classifier.dart';
import '../../../mobile_shell/domain/models/tarea_formulario_detalle.dart';
import '../../domain/entities/tramite_disponible.dart';
import '../viewmodels/tramites_providers.dart';

class RequisitosInicialesSheet extends ConsumerStatefulWidget {
  const RequisitosInicialesSheet({
    super.key,
    required this.actorUserId,
    required this.tramite,
    this.usarSoloRequisitosIniciales = false,
  });

  final String actorUserId;
  final TramiteDisponible tramite;
  final bool usarSoloRequisitosIniciales;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String actorUserId,
    required TramiteDisponible tramite,
    bool usarSoloRequisitosIniciales = false,
  }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return RequisitosInicialesSheet(
          actorUserId: actorUserId,
          tramite: tramite,
          usarSoloRequisitosIniciales: usarSoloRequisitosIniciales,
        );
      },
    );
  }

  @override
  ConsumerState<RequisitosInicialesSheet> createState() =>
      _RequisitosInicialesSheetState();
}

class _RequisitosInicialesSheetState
    extends ConsumerState<RequisitosInicialesSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  final Map<String, bool?> _booleanValues = <String, bool?>{};
  final Map<String, DateTime?> _dateValues = <String, DateTime?>{};
  final Map<String, List<String>> _checkboxValues = <String, List<String>>{};
  final Map<String, List<List<String>>> _gridValues =
      <String, List<List<String>>>{};
  final Map<String, String> _uploadedFileIds = <String, String>{};
  final Map<String, String> _uploadedFileNames = <String, String>{};
  final Map<String, bool> _uploadingFields = <String, bool>{};
  final Map<String, String> _offlineFileBytes = <String, String>{};
  final Map<String, Map<String, dynamic>> _detectedOfflineMetadata =
      <String, Map<String, dynamic>>{};

  List<CampoFormularioDetalle> _requisitos = <CampoFormularioDetalle>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_cargarRequisitos);
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarRequisitos() async {
    try {
      final List<CampoFormularioDetalle> requisitos = await ref
          .read(obtenerRequisitosInicialesUseCaseProvider)
          .call(actorUserId: widget.actorUserId, politicaId: widget.tramite.id);

      if (!mounted) {
        return;
      }

      if (requisitos.isEmpty) {
        Navigator.of(context).pop(<String, dynamic>{});
        return;
      }

      _hydrateForm(requisitos);
      setState(() {
        _requisitos = requisitos;
        _isLoading = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar los requisitos iniciales.';
      });
    }
  }

  void _hydrateForm(List<CampoFormularioDetalle> requisitos) {
    for (final TextEditingController controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _booleanValues.clear();
    _dateValues.clear();
    _checkboxValues.clear();
    _gridValues.clear();
    _uploadedFileIds.clear();
    _uploadedFileNames.clear();
    _uploadingFields.clear();
    _offlineFileBytes.clear();
    _detectedOfflineMetadata.clear();

    for (final CampoFormularioDetalle campo in requisitos) {
      switch (campo.tipoNormalizado) {
        case 'BOOLEANO':
          _booleanValues[campo.clave] = null;
          break;
        case 'CHECKBOX':
          _checkboxValues[campo.clave] = <String>[];
          break;
        case 'GRID':
          final int rows = _gridRows(campo);
          final int cols = _gridColumns(campo);
          _gridValues[campo.clave] = List<List<String>>.generate(
            rows,
            (_) => List<String>.filled(cols, ''),
          );
          break;
        case 'ARCHIVO':
          _uploadingFields[campo.clave] = false;
          break;
        case 'FECHA':
          _dateValues[campo.clave] = null;
          break;
        case 'LABEL':
        case 'DOCUMENTO_COLABORATIVO':
          break;
        default:
          _textControllers[campo.clave] = TextEditingController();
          break;
      }
    }
  }

  void _confirmar() {
    final FormState? form = _formKey.currentState;
    if (form != null && !form.validate()) {
      return;
    }

    final List<String> faltantes = <String>[];
    for (final CampoFormularioDetalle campo in _requisitos) {
      if (!campo.requerido || campo.tipoNormalizado == 'LABEL') {
        continue;
      }

      if (_isMissing(campo)) {
        faltantes.add(campo.etiqueta ?? _prettyLabel(campo.clave));
      }
    }

    if (faltantes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completa los requisitos obligatorios: ${faltantes.join(', ')}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    Navigator.of(context).pop(_buildPayload());
  }

  bool _isMissing(CampoFormularioDetalle campo) {
    switch (campo.tipoNormalizado) {
      case 'BOOLEANO':
        return _booleanValues[campo.clave] == null;
      case 'FECHA':
        return _dateValues[campo.clave] == null;
      case 'CHECKBOX':
        return (_checkboxValues[campo.clave]?.isEmpty ?? true);
      case 'GRID':
        final List<List<String>> grid =
            _gridValues[campo.clave] ?? <List<String>>[];
        return grid.isEmpty ||
            grid.any(
              (List<String> row) =>
                  row.isEmpty || row.any((String cell) => cell.trim().isEmpty),
            );
      case 'ARCHIVO':
        return (_uploadedFileIds[campo.clave] ?? '').trim().isEmpty;
      case 'DOCUMENTO_COLABORATIVO':
        return false;
      default:
        return (_textControllers[campo.clave]?.text ?? '').trim().isEmpty;
    }
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = <String, dynamic>{};
    for (final CampoFormularioDetalle campo in _requisitos) {
      switch (campo.tipoNormalizado) {
        case 'BOOLEANO':
          payload[campo.clave] = _booleanValues[campo.clave];
          break;
        case 'NUMERO':
          payload[campo.clave] = _parseNumber(
            _textControllers[campo.clave]?.text ?? '',
          );
          break;
        case 'FECHA':
          final DateTime? value = _dateValues[campo.clave];
          payload[campo.clave] = value != null ? _formatDate(value) : '';
          break;
        case 'CHECKBOX':
          payload[campo.clave] = _checkboxValues[campo.clave] ?? <String>[];
          break;
        case 'GRID':
          payload[campo.clave] = _gridValues[campo.clave] ?? <List<String>>[];
          break;
        case 'ARCHIVO':
          final String? fileId = _uploadedFileIds[campo.clave];
          final String? fileName = _uploadedFileNames[campo.clave];
          final String? base64Str = _offlineFileBytes[campo.clave];
          final Map<String, dynamic> filePayload = <String, dynamic>{
            'archivoId': fileId,
            'nombreOriginal': fileName,
            if (base64Str != null) 'isOfflineFile': true,
            if (base64Str != null) 'base64': base64Str,
          };
          if (base64Str != null && _detectedOfflineMetadata.containsKey(campo.clave)) {
            filePayload.addAll(_detectedOfflineMetadata[campo.clave]!);
          }
          payload[campo.clave] = filePayload;
          break;
        case 'DOCUMENTO_COLABORATIVO':
          payload[campo.clave] = <String, dynamic>{
            'tipo': 'DOCUMENTO_COLABORATIVO',
            'campoId': campo.clave,
            'estado': 'PENDIENTE_CREACION',
          };
          break;
        case 'LABEL':
          break;
        default:
          payload[campo.clave] = (_textControllers[campo.clave]?.text ?? '')
              .trim();
          break;
      }
    }
    return payload;
  }

  Future<void> _seleccionarArchivo(CampoFormularioDetalle campo) async {
    if (_uploadingFields[campo.clave] == true) {
      return;
    }

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
      if (bytes == null || bytes.isEmpty) {
        throw ApiFailure(message: 'No se pudo leer el archivo seleccionado.');
      }

      setState(() {
        _uploadingFields[campo.clave] = true;
      });

      final bool isOnline = ref.read(isOnlineProvider);
      String archivoId;
      if (isOnline) {
        archivoId = await _subirArchivoInicial(
          campo: campo,
          file: file,
          bytes: bytes,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _uploadedFileIds[campo.clave] = archivoId;
          _uploadedFileNames[campo.clave] = file.name;
          _uploadingFields[campo.clave] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo "${file.name}" subido correctamente.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        archivoId = 'local_file_${DateTime.now().millisecondsSinceEpoch}';
        final String base64Content = base64Encode(bytes);

        if (!mounted) {
          return;
        }

        if (widget.usarSoloRequisitosIniciales) {
          final List<CampoFormularioDetalle> fileFields = _requisitos
              .where((r) => r.tipoNormalizado == 'ARCHIVO')
              .toList();

          final Map<CampoFormularioDetalle, double> scores = {};
          for (final CampoFormularioDetalle r in fileFields) {
            final double score = OfflineRequisitoDetector.calcularScoreRequisito(
              nombreArchivo: file.name,
              clave: r.clave,
              etiqueta: r.etiqueta ?? '',
              ayuda: r.ayuda ?? '',
              palabrasClave: null,
            );
            scores[r] = score;
          }

          final List<MapEntry<CampoFormularioDetalle, double>> sortedScores = scores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          double highestScore = 0.0;
          CampoFormularioDetalle? matchedField;
          bool hasTie = false;

          if (sortedScores.isNotEmpty) {
            highestScore = sortedScores.first.value;
            matchedField = sortedScores.first.key;
            if (sortedScores.length > 1 && sortedScores[1].value == highestScore && highestScore > 0) {
              hasTie = true;
            }
          }

          if (highestScore >= 5.0 && !hasTie && matchedField != null) {
            setState(() {
              _offlineFileBytes[matchedField!.clave] = base64Content;
              _uploadedFileIds[matchedField.clave] = archivoId;
              _uploadedFileNames[matchedField.clave] = file.name;
              _uploadingFields[campo.clave] = false;

              _detectedOfflineMetadata[matchedField.clave] = <String, dynamic>{
                'requisitoId': matchedField.clave,
                'nombreRequisito': matchedField.etiqueta ?? matchedField.clave,
                'archivoLocalId': archivoId,
                'nombreArchivo': file.name,
                'detectadoOffline': true,
                'metodoDeteccion': 'NOMBRE_ARCHIVO',
                'confianzaDeteccion': (highestScore / 6.0).clamp(0.0, 1.0),
                'isOfflineFile': true,
              };
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Archivo asociado automáticamente al requisito: ${matchedField.etiqueta ?? matchedField.clave}'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else if (highestScore >= 3.0 && highestScore < 5.0 && !hasTie && matchedField != null) {
            setState(() {
              _offlineFileBytes[matchedField!.clave] = base64Content;
              _uploadedFileIds[matchedField.clave] = archivoId;
              _uploadedFileNames[matchedField.clave] = file.name;
              _uploadingFields[campo.clave] = false;

              _detectedOfflineMetadata[matchedField.clave] = <String, dynamic>{
                'requisitoId': matchedField.clave,
                'nombreRequisito': matchedField.etiqueta ?? matchedField.clave,
                'archivoLocalId': archivoId,
                'nombreArchivo': file.name,
                'detectadoOffline': true,
                'metodoDeteccion': 'NOMBRE_ARCHIVO',
                'confianzaDeteccion': (highestScore / 6.0).clamp(0.0, 1.0),
                'isOfflineFile': true,
              };
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Posible coincidencia con ${matchedField.etiqueta ?? matchedField.clave}. Verificá antes de continuar.'),
                backgroundColor: Colors.orange.shade800,
              ),
            );
          } else {
            setState(() {
              _offlineFileBytes[campo.clave] = base64Content;
              _uploadedFileIds[campo.clave] = archivoId;
              _uploadedFileNames[campo.clave] = file.name;
              _uploadingFields[campo.clave] = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No se pudo asociar automáticamente este archivo a un requisito inicial.'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        } else {
          setState(() {
            _offlineFileBytes[campo.clave] = base64Content;
            _uploadedFileIds[campo.clave] = archivoId;
            _uploadedFileNames[campo.clave] = file.name;
            _uploadingFields[campo.clave] = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archivo "${file.name}" cargado localmente (sin conexión).'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingFields[campo.clave] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingFields[campo.clave] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo subir el archivo seleccionado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<String> _subirArchivoInicial({
    required CampoFormularioDetalle campo,
    required PlatformFile file,
    required List<int> bytes,
  }) async {
    final MultipartFile archivo = MultipartFile.fromBytes(
      bytes,
      filename: file.name,
    );
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'archivo': archivo,
      'politicaId': widget.tramite.id,
      'tramiteId': widget.tramite.id,
      'campoId': campo.clave,
      'usuarioId': widget.actorUserId,
      'clienteId': widget.actorUserId,
      'descripcion': 'Requisito inicial ${campo.clave}',
    });

    try {
      final Response<dynamic> response = await ref
          .read(tramitesDioProvider)
          .post<dynamic>(
            NetworkConstants.archivosPath,
            data: formData,
            options: Options(
              headers: <String, String>{'X-User-Id': widget.actorUserId},
            ),
          );

      final Map<String, dynamic>? json = _toJsonMap(response.data);
      final String id = (json?['id'] ?? json?['archivoId'] ?? '')
          .toString()
          .trim();
      if (id.isEmpty) {
        throw ApiFailure(message: 'Respuesta invalida al subir el archivo.');
      }
      return id;
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  void _eliminarArchivo(CampoFormularioDetalle campo) {
    setState(() {
      _uploadedFileIds.remove(campo.clave);
      _uploadedFileNames.remove(campo.clave);
    });
  }

  Future<void> _seleccionarFecha(CampoFormularioDetalle campo) async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _dateValues[campo.clave] ?? now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 20),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _dateValues[campo.clave] = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Requisitos iniciales',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.tramite.nombre,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                _InlineError(message: _errorMessage!)
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: _requisitos
                            .map(
                              (CampoFormularioDetalle campo) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildField(context, campo),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Continuar',
                      onPressed:
                          _isLoading ||
                              _errorMessage != null ||
                              _uploadingFields.values.any((bool value) => value)
                          ? null
                          : _confirmar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, CampoFormularioDetalle campo) {
    final String label = _fieldLabel(campo);

    switch (campo.tipoNormalizado) {
      case 'LABEL':
        return _InfoBlock(label: label, ayuda: campo.ayuda);
      case 'SELECCION':
        return _buildSelectionField(campo, label);
      case 'CHECKBOX':
        return _buildCheckboxField(campo, label);
      case 'GRID':
        return _buildGridField(campo, label);
      case 'ARCHIVO':
        return _buildFileField(campo, label);
      case 'DOCUMENTO_COLABORATIVO':
        return _buildCollaborativeDocumentField(campo, label);
      case 'BOOLEANO':
        return _buildBooleanField(campo, label);
      case 'FECHA':
        return _buildDateField(campo, label);
      case 'NUMERO':
        return TextFormField(
          controller: _textControllers[campo.clave],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _requiredLabel(label, campo),
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
      default:
        return TextFormField(
          controller: _textControllers[campo.clave],
          minLines: campo.tipoNormalizado == 'TEXTO' ? 1 : 1,
          maxLines: campo.tipoNormalizado == 'TEXTO' ? 4 : 1,
          decoration: InputDecoration(
            labelText: _requiredLabel(label, campo),
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

  Widget _buildSelectionField(CampoFormularioDetalle campo, String label) {
    final List<String> options = campo.opciones ?? <String>[];
    final String current = _textControllers[campo.clave]?.text ?? '';

    return DropdownButtonFormField<String>(
      initialValue: options.contains(current) ? current : null,
      decoration: InputDecoration(
        labelText: _requiredLabel(label, campo),
        hintText: campo.placeholder ?? 'Selecciona una opcion',
        helperText: campo.ayuda,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (String option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(growable: false),
      onChanged: (String? value) {
        _textControllers[campo.clave]?.text = value ?? '';
      },
      validator: (String? value) {
        if (campo.requerido && (value == null || value.trim().isEmpty)) {
          return 'Selecciona una opcion.';
        }
        return null;
      },
    );
  }

  Widget _buildCheckboxField(CampoFormularioDetalle campo, String label) {
    final ThemeData theme = Theme.of(context);
    final List<String> options = campo.opciones ?? <String>[];
    final List<String> checked = _checkboxValues[campo.clave] ?? <String>[];

    return _FieldShell(
      label: _requiredLabel(label, campo),
      ayuda: campo.ayuda,
      child: options.isEmpty
          ? Text('Sin opciones configuradas.', style: theme.textTheme.bodySmall)
          : Column(
              children: options
                  .map((String option) {
                    final bool isChecked = checked.contains(option);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(option),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          final List<String> next = List<String>.from(checked);
                          if (value == true && !next.contains(option)) {
                            next.add(option);
                          }
                          if (value != true) {
                            next.remove(option);
                          }
                          _checkboxValues[campo.clave] = next;
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildGridField(CampoFormularioDetalle campo, String label) {
    final ThemeData theme = Theme.of(context);
    final List<String> columns = campo.opciones ?? <String>[];
    final List<List<String>> rows =
        _gridValues[campo.clave] ?? <List<String>>[];

    return _FieldShell(
      label: _requiredLabel(label, campo),
      ayuda: campo.ayuda,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(120),
          border: TableBorder.all(color: theme.colorScheme.outlineVariant),
          children: <TableRow>[
            if (columns.isNotEmpty)
              TableRow(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                children: columns
                    .map(
                      (String column) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          column,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ...List<int>.generate(rows.length, (int rowIndex) => rowIndex).map((
              int rowIndex,
            ) {
              final List<String> row = rows[rowIndex];
              return TableRow(
                children: List<Widget>.generate(row.length, (int colIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextFormField(
                      initialValue: row[colIndex],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '...',
                      ),
                      onChanged: (String value) {
                        rows[rowIndex][colIndex] = value;
                      },
                    ),
                  );
                }).toList(growable: false),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFileField(CampoFormularioDetalle campo, String label) {
    final String? fileName = _uploadedFileNames[campo.clave];
    final bool isUploading = _uploadingFields[campo.clave] ?? false;
    final bool hasFile = (fileName ?? '').trim().isNotEmpty;

    return _FieldShell(
      label: _requiredLabel(label, campo),
      ayuda: campo.ayuda,
      child: Row(
        children: <Widget>[
          Icon(
            hasFile
                ? Icons.check_circle_outline_rounded
                : Icons.cloud_upload_outlined,
            color: hasFile ? Colors.green.shade700 : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFile
                  ? fileName!
                  : (campo.placeholder ?? 'Selecciona un documento'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (hasFile)
            IconButton(
              tooltip: 'Quitar',
              onPressed: () => _eliminarArchivo(campo),
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => _seleccionarArchivo(campo),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Subir'),
            ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeDocumentField(
    CampoFormularioDetalle campo,
    String label,
  ) {
    final ThemeData theme = Theme.of(context);
    return _FieldShell(
      label: _requiredLabel(label, campo),
      ayuda: campo.ayuda,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.edit_document, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Se creara un documento colaborativo al iniciar. Podras abrirlo en OnlyOffice desde el seguimiento del tramite.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          const Chip(label: Text('OnlyOffice')),
        ],
      ),
    );
  }

  Widget _buildBooleanField(CampoFormularioDetalle campo, String label) {
    return DropdownButtonFormField<bool>(
      initialValue: _booleanValues[campo.clave],
      decoration: InputDecoration(
        labelText: _requiredLabel(label, campo),
        helperText: campo.ayuda,
        border: const OutlineInputBorder(),
      ),
      items: const <DropdownMenuItem<bool>>[
        DropdownMenuItem<bool>(value: true, child: Text('Si')),
        DropdownMenuItem<bool>(value: false, child: Text('No')),
      ],
      onChanged: (bool? value) {
        setState(() {
          _booleanValues[campo.clave] = value;
        });
      },
      validator: (bool? value) {
        if (campo.requerido && value == null) {
          return 'Selecciona una opcion.';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(CampoFormularioDetalle campo, String label) {
    final DateTime? date = _dateValues[campo.clave];
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _seleccionarFecha(campo),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _requiredLabel(label, campo),
          helperText: campo.ayuda,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          date == null
              ? (campo.placeholder ?? 'Seleccionar fecha')
              : _formatDate(date),
        ),
      ),
    );
  }

  String _fieldLabel(CampoFormularioDetalle campo) {
    final String label = campo.etiqueta?.trim() ?? '';
    return label.isNotEmpty ? label : _prettyLabel(campo.clave);
  }

  String _requiredLabel(String label, CampoFormularioDetalle campo) {
    return campo.requerido ? '$label *' : label;
  }

  String _prettyLabel(String key) {
    final List<String> parts = key
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
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

  int _gridRows(CampoFormularioDetalle campo) {
    final int? parsed = int.tryParse(campo.placeholder ?? '');
    return parsed != null && parsed > 0 ? parsed : 3;
  }

  int _gridColumns(CampoFormularioDetalle campo) {
    final int columns = campo.opciones?.length ?? 0;
    return columns > 0 ? columns : 2;
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

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Map<String, dynamic>? _toJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item),
      );
    }
    return null;
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child, this.ayuda});

  final String label;
  final String? ayuda;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((ayuda ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                ayuda!.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, this.ayuda});

  final String label;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((ayuda ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(ayuda!.trim()),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
